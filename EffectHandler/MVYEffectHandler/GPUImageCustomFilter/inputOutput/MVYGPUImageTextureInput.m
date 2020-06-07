//
//  MVYGPUImageTextureInput.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageTextureInput.h"
#import "MVYGPUImageFilter.h"

@interface MVYGPUImageTextureInput () {
    MVYGLProgram *dataProgram;
    
    GLint dataPositionAttribute;
    GLint dataTextureCoordinateAttribute;
    
    GLint dataInputTextureUniform;
}

@end

@implementation MVYGPUImageTextureInput

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


- (void)processWithBGRATexture:(GLint)texture width:(int)width height:(int)height{
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
        
        
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, texture);
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

@end
