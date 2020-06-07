//
//  MVYGPUImageI420DataInput.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/4/16.
//  Copyright © 2019年 myvideoyun. All rights reserved.
//

#import "MVYGPUImageI420DataInput.h"
#import "MVYGPUImageFilter.h"
#import "MVYGPUImageConstants.h"

// Fragment Shader String
NSString *const kMVYRGBConversion2FragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D yTexture;
 uniform sampler2D uTexture;
 uniform sampler2D vTexture;
 uniform mediump mat3 colorConversionMatrix;
 
 void main()
 {
     mediump vec3 yuv;
     lowp vec3 rgb;
     yuv.x = texture2D(yTexture, textureCoordinate).r;
     yuv.y = texture2D(uTexture, textureCoordinate).r - 0.5;
     yuv.z = texture2D(vTexture, textureCoordinate).r - 0.5;
     rgb = colorConversionMatrix * yuv;
     gl_FragColor = vec4(rgb, 1);
 }
 );

@interface MVYGPUImageI420DataInput() {
    MVYGLProgram *dataProgram;
    
    GLint dataPositionAttribute;
    GLint dataTextureCoordinateAttribute;
    
    GLint datayTextureUniform;
    GLint datauTextureUniform;
    GLint datavTextureUniform;

    GLint colorConversionUniform;
    
    GLuint inputyTexture;
    GLuint inputuTexture;
    GLuint inputvTexture;
}

@end

@implementation MVYGPUImageI420DataInput

- (instancetype)initWithContext:(MVYGPUImageContext *)context
{
    if (!(self = [super initWithContext:context])){
        return nil;
    }
    
    [context useAsCurrentContext];
    
    runMVYSynchronouslyOnContextQueue(context, ^{
        self->dataProgram = [context programForVertexShaderString:kMVYGPUImageVertexShaderString fragmentShaderString:kMVYRGBConversion2FragmentShaderString];
        
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
        self->datayTextureUniform = [self->dataProgram uniformIndex:@"yTexture"];
        self->datauTextureUniform = [self->dataProgram uniformIndex:@"uTexture"];
        self->datavTextureUniform = [self->dataProgram uniformIndex:@"vTexture"];
        self->colorConversionUniform = [self->dataProgram uniformIndex:@"colorConversionMatrix"];
    });
        
    return self;
}

// Raw格式的导出和导入此转换函数不一样
- (void)setRotateMode:(MVYGPUImageRotationMode)rotateMode {
    switch (rotateMode) {
        case kMVYGPUImageNoRotation:
            _rotateMode = kMVYGPUImageFlipVertical;
            break;
        case kMVYGPUImageRotateLeft:
            _rotateMode = kMVYGPUImageRotateRightFlipHorizontal;
            break;
        case kMVYGPUImageRotateRight:
            _rotateMode = kMVYGPUImageRotateRightFlipVertical;
            break;
        case kMVYGPUImageRotate180:
            _rotateMode = kMVYGPUImageFlipHorizonal;
            break;
        case kMVYGPUImageFlipVertical:
            _rotateMode = kMVYGPUImageNoRotation;
            break;
        case kMVYGPUImageRotateRightFlipHorizontal:
            _rotateMode = kMVYGPUImageRotateLeft;
            break;
        case kMVYGPUImageRotateRightFlipVertical:
            _rotateMode = kMVYGPUImageRotateRight;
            break;
        case kMVYGPUImageFlipHorizonal:
            _rotateMode = kMVYGPUImageRotate180;
            break;
    }
}

- (void)processWithYData:(const void *)yData uData:(const void *)uData vData:(const void *)vData width:(int)width height:(int)height{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [self->dataProgram use];
        
        if ([MVYGPUImageFilter needExchangeWidthAndHeightWithRotation:self.rotateMode]) {
            self->outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(height, width) textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
        } else {
            self->outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(width, height) textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
        }
        [self->outputFramebuffer activateFramebuffer];
        
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        static const GLfloat squareVertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };
        
        if (!self->inputyTexture) {
            glGenTextures(1, &(self->inputyTexture));
            glBindTexture(GL_TEXTURE_2D, self->inputyTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
        if (!self->inputuTexture) {
            glGenTextures(1, &(self->inputuTexture));
            glBindTexture(GL_TEXTURE_2D, self->inputuTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
        if (!self->inputvTexture) {
            glGenTextures(1, &(self->inputvTexture));
            glBindTexture(GL_TEXTURE_2D, self->inputvTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, self->inputyTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width, height, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, yData);
        glUniform1i(self->datayTextureUniform, 1);
        
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, self->inputuTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width / 2, height / 2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, uData);
        glUniform1i(self->datauTextureUniform, 2);
        
        glActiveTexture(GL_TEXTURE3);
        glBindTexture(GL_TEXTURE_2D, self->inputvTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, width / 2, height / 2, 0, GL_RED_EXT, GL_UNSIGNED_BYTE, vData);
        glUniform1i(self->datavTextureUniform, 3);
        
        glUniformMatrix3fv(self->colorConversionUniform, 1, GL_FALSE, kMVYColorConversion601FullRangeDefault);
        
        glVertexAttribPointer(self->dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
        glVertexAttribPointer(self->dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [MVYGPUImageFilter textureCoordinatesForRotation:self.rotateMode]);
        
        glEnableVertexAttribArray(self->dataPositionAttribute);
        glEnableVertexAttribArray(self->dataTextureCoordinateAttribute);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        for (id<MVYGPUImageInput> currentTarget in self->targets)
        {
            if ([MVYGPUImageFilter needExchangeWidthAndHeightWithRotation:self.rotateMode]) {
                [currentTarget setInputSize:CGSizeMake(height, width)];
            } else {
                [currentTarget setInputSize:CGSizeMake(width, height)];
            }
            [currentTarget setInputFramebuffer:self->outputFramebuffer];
            [currentTarget newFrameReady];
        }
        
        [self->outputFramebuffer unlock];
    });
}

- (void)dealloc
{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (self->inputyTexture){
            glDeleteTextures(1, &(self->inputyTexture));
            self->inputyTexture = 0;
        }
        
        if (self->inputuTexture){
            glDeleteTextures(1, &(self->inputuTexture));
            self->inputuTexture = 0;
        }
        
        if (self->inputvTexture){
            glDeleteTextures(1, &(self->inputvTexture));
            self->inputvTexture = 0;
        }
    });
}


@end
