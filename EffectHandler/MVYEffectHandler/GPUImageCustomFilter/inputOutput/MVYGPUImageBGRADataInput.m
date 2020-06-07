//
//  MVYGPUImageBGRADataInput.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/4/16.
//  Copyright © 2019年 myvideoyun. All rights reserved.
//

#import "MVYGPUImageBGRADataInput.h"
#import "MVYGPUImageFilter.h"
@interface MVYGPUImageBGRADataInput() {
    MVYGLProgram *dataProgram;
    
    GLint dataPositionAttribute;
    GLint dataTextureCoordinateAttribute;
    
    GLint dataInputTextureUniform;
    
    GLuint inputDataTexture;
}

@end

@implementation MVYGPUImageBGRADataInput

- (instancetype)initWithContext:(MVYGPUImageContext *)context
{
    if (!(self = [super initWithContext:context])){
        return nil;
    }
    
    runMVYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        
        self->dataProgram = [context programForVertexShaderString:kMVYGPUImageVertexShaderString fragmentShaderString:kMVYGPUImagePassthroughFragmentShaderString];
        
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

- (void)processWithBGRAData:(void *)bgraData width:(int)width height:(int)height{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        [self->dataProgram use];
        
        if ([MVYGPUImageFilter needExchangeWidthAndHeightWithRotation:self.rotateMode]) {
            self->outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(height, width) missCVPixelBuffer:YES];
        } else {
            self->outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(width, height) missCVPixelBuffer:YES];
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
        
        if (!self->inputDataTexture) {
            glGenTextures(1, &(self->inputDataTexture));
            glBindTexture(GL_TEXTURE_2D, self->inputDataTexture);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        }
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, self->inputDataTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, bgraData);
        
        glUniform1i(self->dataInputTextureUniform, 1);
        
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

- (void)processWithBGRAPixelBuffer:(CVPixelBufferRef)pixelBuffer;
{
    int width = (int) CVPixelBufferGetBytesPerRow(pixelBuffer) / 4;
    int height = (int) CVPixelBufferGetHeight(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void* bgraData = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    [self processWithBGRAData:bgraData width:width height:height];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)dealloc
{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (self->inputDataTexture){
            glDeleteTextures(1, &(self->inputDataTexture));
            self->inputDataTexture = 0;
        }
    });
}

@end
