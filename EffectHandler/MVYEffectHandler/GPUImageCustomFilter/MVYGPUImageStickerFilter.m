//
//  MVYGPUImageStickerFilter.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/5/7.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageStickerFilter.h"

NSString *const kMVYGPUImageStickerVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 uniform mat4 transformMatrix;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = transformMatrix * vec4(position.xyz, 1.0);
     textureCoordinate = inputTextureCoordinate.xy;
 }
);

@interface MVYGPUImageStickerFilter () {
    GLint transformMatrixUniform;
}

@property (nonatomic, strong) NSMutableArray<MVYGPUImageStickerModel *> *stickers;

@end

@implementation MVYGPUImageStickerFilter

- (id)initWithContext:(MVYGPUImageContext *)context{
    if (!(self = [super initWithContext:context vertexShaderFromString:kMVYGPUImageStickerVertexShaderString fragmentShaderFromString:kMVYGPUImagePassthroughFragmentShaderString])) {
        return nil;
    }
    
    runMVYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        self->transformMatrixUniform = [self->filterProgram uniformIndex:@"transformMatrix"];
    });
    
    self.stickers = [[NSMutableArray alloc] init];
    
    return self;
}

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    [self.context useAsCurrentContext];
    [filterProgram use];
    
    const float identity[] = {
        CATransform3DIdentity.m11, CATransform3DIdentity.m12, CATransform3DIdentity.m13, CATransform3DIdentity.m14,
        CATransform3DIdentity.m21, CATransform3DIdentity.m22, CATransform3DIdentity.m23, CATransform3DIdentity.m24,
        CATransform3DIdentity.m31, CATransform3DIdentity.m32, CATransform3DIdentity.m33, CATransform3DIdentity.m34,
        CATransform3DIdentity.m41, CATransform3DIdentity.m42, CATransform3DIdentity.m43, CATransform3DIdentity.m44
    };
    glUniformMatrix4fv(transformMatrixUniform, 1, false, identity);

    // 渲染正常画面
    [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
    
    // 循环渲染纹理贴图
    for (MVYGPUImageStickerModel *model in self.stickers) {
        [filterProgram use];
        
        glEnable(GL_BLEND);
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, model->texture);
        
        glUniform1i(filterInputTextureUniform, 2);
        
        CATransform3D transformMatrix = CATransform3DMakeRotation(M_PI, 1, 0, 0);
        transformMatrix = CATransform3DConcat(model.transformMatrix, transformMatrix);
        transformMatrix = CATransform3DScale(transformMatrix, model.image.size.width / firstInputFramebuffer.size.width, model.image.size.height / firstInputFramebuffer.size.height, 1);
        
        const float matrix[] = {
            transformMatrix.m11, transformMatrix.m12, transformMatrix.m13, transformMatrix.m14,
            transformMatrix.m21, transformMatrix.m22, transformMatrix.m23, transformMatrix.m24,
            transformMatrix.m31, transformMatrix.m32, transformMatrix.m33, transformMatrix.m34,
            transformMatrix.m41, transformMatrix.m42, transformMatrix.m43, transformMatrix.m44
        };
        glUniformMatrix4fv(transformMatrixUniform, 1, false, matrix);
        
        glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, false, 0, vertices);
        glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, false, 0, textureCoordinates);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glDisable(GL_BLEND);
    }
}

- (void)addStickerWithModel:(MVYGPUImageStickerModel *)model {
    
    // First get the image into your data buffer
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
    
    [self.stickers addObject:model];
}

- (void)removeStickerWithModel:(MVYGPUImageStickerModel *)model {
    
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        // 销毁一个纹理贴图对象
        if (model->texture != 0) {
            glDeleteTextures(1, &(model->texture));
            model->texture = 0;
        }
    });
    
    [self.stickers removeObject:model];
}

- (void)clear {
    for (NSInteger x = self.stickers.count - 1; x >= 0; x--) {
        [self removeStickerWithModel:self.stickers[x]];
    }
}

-(void)dealloc {
    [self clear];
}

@end
