//
//  MVYGPUImageTextureTransitionInput.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/6/29.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageTextureTransitionInput.h"
#import "MVYGPUImageFilter.h"
#import "MVYGPUImageConstants.h"

NSString *const kMVYGPUImageTransitionVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform mat4 transformMatrix;
 uniform mat4 orthographicMatrix;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = transformMatrix * vec4(position.xyz, 1.0) * orthographicMatrix;
     textureCoordinate = inputTextureCoordinate.xy;
 }
);

NSString *const kMVYGPUImageTransitionFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float transparent;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     gl_FragColor = vec4(textureColor.rgb, (textureColor.w * transparent));
 }
);

@interface MVYGPUImageTextureTransitionInput (){
    MVYGLProgram *dataProgram;
    
    GLint dataPositionAttribute;
    GLint dataTextureCoordinateAttribute;
    
    GLint dataInputTextureUniform;
    GLint transformMatrixUniform;
    GLint orthographicMatrixUniform;
    GLint transparentUniform;
}

@property (nonatomic, strong) NSMutableArray<MVYGPUImageTextureModel *> *cacheTextures;

@property (nonatomic, assign) MVYGPUImageContentMode contentMode;

@end

@implementation MVYGPUImageTextureTransitionInput

- (instancetype)initWithContext:(MVYGPUImageContext *)context
{
    if (!(self = [super initWithContext:context])){
        return nil;
    }
    
    runMVYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        
        self->dataProgram = [context programForVertexShaderString:kMVYGPUImageTransitionVertexShaderString fragmentShaderString:kMVYGPUImageTransitionFragmentShaderString];
        
        if (!self->dataProgram.initialized)
        {
            if (![self->dataProgram link])
            {
                NSString *progLog = [self->dataProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [self->dataProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [self->dataProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                self->dataProgram = nil;
            }
        }
        
        self->dataPositionAttribute = [self->dataProgram attributeIndex:@"position"];
        self->dataTextureCoordinateAttribute = [self->dataProgram attributeIndex:@"inputTextureCoordinate"];
        self->dataInputTextureUniform = [self->dataProgram uniformIndex:@"inputImageTexture"];
        self->transformMatrixUniform = [self->dataProgram uniformIndex:@"transformMatrix"];
        self->orthographicMatrixUniform = [self->dataProgram uniformIndex:@"orthographicMatrix"];
        self->transparentUniform = [self->dataProgram uniformIndex:@"transparent"];

    });
    
    _cacheTextures = [[NSMutableArray alloc] init];
    
    _renderTextures = [[NSArray alloc] init];
    
    _contentMode = kMVYGPUImageContentModeScaleAspectFill;
    
    return self;
}


- (void)processWithWidth:(int)width height:(int)height {
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [self->dataProgram use];
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        self->outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(width, height) textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
        [self->outputFramebuffer activateFramebuffer];
        
        for (MVYGPUImageTextureModel *textureModel in self.renderTextures) {
            MVYGPUImageFramebuffer *tempFrameBuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(width, height) textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
            
            [tempFrameBuffer activateFramebuffer];
            
            glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            
            glActiveTexture(GL_TEXTURE2);
            
            glBindTexture(GL_TEXTURE_2D, textureModel->texture);
            
            glUniform1i(self->dataInputTextureUniform, 2);
            
            CATransform3D transformMatrix = CATransform3DMakeRotation(M_PI, 1, 0, 0);
            const GLfloat matrix[] = {
                transformMatrix.m11, transformMatrix.m12, transformMatrix.m13, transformMatrix.m14,
                transformMatrix.m21, transformMatrix.m22, transformMatrix.m23, transformMatrix.m24,
                transformMatrix.m31, transformMatrix.m32, transformMatrix.m33, transformMatrix.m34,
                transformMatrix.m41, transformMatrix.m42, transformMatrix.m43, transformMatrix.m44
            };
            glUniformMatrix4fv(self->transformMatrixUniform, 1, false, matrix);
            
            GLfloat orthographicMatrix[16];
            [self loadOrthoMatrix:orthographicMatrix left:-1.0f right:1.0f bottom:-1.0f top:1.0f near:-1.0f far:1.0f];
            glUniformMatrix4fv(self->orthographicMatrixUniform, 1, false, orthographicMatrix);
            
            glUniform1f(self->transparentUniform, textureModel.transparent);
            
            CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(textureModel.image.size.width, textureModel.image.size.height), CGRectMake(0, 0, width, height));
            
            if ([MVYGPUImageFilter needExchangeWidthAndHeightWithRotation:textureModel.rotate]) {
                insetRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(textureModel.image.size.height, textureModel.image.size.width), CGRectMake(0, 0, width, height));
            }
            
            float widthScaling = 0.0f, heightScaling = 0.0f;
            
            switch (self.contentMode) {
                case kMVYGPUImageContentModeScaleToFill: // 填充
                    widthScaling = 1.0;
                    heightScaling = 1.0;
                    break;
                    
                case kMVYGPUImageContentModeScaleAspectFit: //保持宽高比
                    widthScaling = insetRect.size.width / width;
                    heightScaling = insetRect.size.height / height;
                    break;
                    
                case kMVYGPUImageContentModeScaleAspectFill: //保持宽高比同时填满整个屏幕
                    widthScaling = height / insetRect.size.height;
                    heightScaling = width / insetRect.size.width;
                    break;
            }
            
            GLfloat squareVertices[8];
            squareVertices[0] = -widthScaling;
            squareVertices[1] = -heightScaling;
            squareVertices[2] = widthScaling;
            squareVertices[3] = -heightScaling;
            squareVertices[4] = -widthScaling;
            squareVertices[5] = heightScaling;
            squareVertices[6] = widthScaling;
            squareVertices[7] = heightScaling;
            
            const GLfloat *textureCoordinates = [MVYGPUImageFilter textureCoordinatesForRotation:textureModel.rotate];
            
            glEnableVertexAttribArray(self->dataPositionAttribute);
            glEnableVertexAttribArray(self->dataTextureCoordinateAttribute);
            
            glVertexAttribPointer(self->dataPositionAttribute, 2, GL_FLOAT, false, 0,  squareVertices);
            glVertexAttribPointer(self->dataTextureCoordinateAttribute, 2, GL_FLOAT, false, 0, textureCoordinates);
            
            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            [self->outputFramebuffer activateFramebuffer];
            
            glActiveTexture(GL_TEXTURE2);
            glBindTexture(GL_TEXTURE_2D, tempFrameBuffer.texture);
            glUniform1i(self->dataInputTextureUniform, 2);
            
            transformMatrix = textureModel.transformMatrix;
            const GLfloat matrix2[] = {
                transformMatrix.m11, transformMatrix.m12, transformMatrix.m13, transformMatrix.m14,
                transformMatrix.m21, transformMatrix.m22, transformMatrix.m23, transformMatrix.m24,
                transformMatrix.m31, transformMatrix.m32, transformMatrix.m33, transformMatrix.m34,
                transformMatrix.m41, transformMatrix.m42, transformMatrix.m43, transformMatrix.m44
            };
            glUniformMatrix4fv(self->transformMatrixUniform, 1, false, matrix2);
            
            [self loadOrthoMatrix:orthographicMatrix left:-1.0f right:1.0f bottom:-1.0f * height / width top:1.0f * height / width near:-1.0f far:1.0f];
            glUniformMatrix4fv(self->orthographicMatrixUniform, 1, false, orthographicMatrix);

            glUniform1f(self->transparentUniform, textureModel.transparent);

            GLfloat normalizedHeight = (GLfloat) height / (GLfloat) width;
            const GLfloat adjustedVertices[] = {
                -1.0f, -normalizedHeight,
                1.0f, -normalizedHeight,
                -1.0f,  normalizedHeight,
                1.0f,  normalizedHeight
            };

            glVertexAttribPointer(self->dataPositionAttribute, 2, GL_FLOAT, false, 0,  adjustedVertices);
            glVertexAttribPointer(self->dataTextureCoordinateAttribute, 2, GL_FLOAT, false, 0, [MVYGPUImageFilter textureCoordinatesForRotation:kMVYGPUImageNoRotation]);

            glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
            
            [tempFrameBuffer unlock];
        }
        
        glDisable(GL_BLEND);
        
        for (id<MVYGPUImageInput> currentTarget in self->targets)
        {
            [currentTarget setInputSize:CGSizeMake(width, height)];
            [currentTarget setInputFramebuffer:self->outputFramebuffer];
            [currentTarget newFrameReady];
        }
        
        [self->outputFramebuffer unlock];
    });
}

- (void)loadOrthoMatrix:(float *)matrix left:(float)left right:(float)right bottom:(float)bottom top:(float)top near:(float)near far:(float)far {
    float r_l = right - left;
    float t_b = top - bottom;
    float f_n = far - near;
    float tx = - (right + left) / (right - left);
    float ty = - (top + bottom) / (top - bottom);
    float tz = - (far + near) / (far - near);
    
    float scale = 2.0f;

    matrix[0] = scale / r_l;
    matrix[1] = 0.0f;
    matrix[2] = 0.0f;
    matrix[3] = tx;
    
    matrix[4] = 0.0f;
    matrix[5] = scale / t_b;
    matrix[6] = 0.0f;
    matrix[7] = ty;
    
    matrix[8] = 0.0f;
    matrix[9] = 0.0f;
    matrix[10] = scale / f_n;
    matrix[11] = tz;
    
    matrix[12] = 0.0f;
    matrix[13] = 0.0f;
    matrix[14] = 0.0f;
    matrix[15] = 1.0f;
}

- (void)setRenderTextures:(NSArray<MVYGPUImageTextureModel *> *)renderTextures {
    if (renderTextures == nil) {
        return;
    }
    
    for (MVYGPUImageTextureModel *textureModel in renderTextures) {
        if (![self.cacheTextures containsObject:textureModel]) {
            [self addCacheTexture: textureModel];
        }
    }
    
    _renderTextures = renderTextures;
}

- (void)addCacheTexture:(MVYGPUImageTextureModel *)model {
    CGImageRef imageRef = [model.image CGImage];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *pixelBuffer = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    size_t bytesPerPixel = 4;
    size_t bytesPerRow = bytesPerPixel * width;
    size_t bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(pixelBuffer, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        // 创建一个纹理贴图对象
        glGenTextures(1, &(model->texture));
        glBindTexture(GL_TEXTURE_2D, model->texture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        glBindTexture(GL_TEXTURE_2D, model->texture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (GLsizei)width, (GLsizei)height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixelBuffer);
    });
    
    free(pixelBuffer);
    
    [self.cacheTextures addObject:model];
}

- (void)clearCacheTexture {
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        for (NSInteger x = self.cacheTextures.count - 1; x >= 0; x--) {
            MVYGPUImageTextureModel *model = self.cacheTextures[x];
            
            // 销毁一个纹理贴图对象
            if (model->texture != 0) {
                glDeleteTextures(1, &(model->texture));
                model->texture = 0;
            }
            
            [self.cacheTextures removeObject:model];
        }
    });
}

-(void)dealloc {
    [self clearCacheTexture];
}

@end
