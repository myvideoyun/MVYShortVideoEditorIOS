//
//  MVYGPUImageTextureOutput.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageTextureOutput.h"

#import "MVYGLProgram.h"
#import "MVYGPUImageFramebuffer.h"

@interface MVYGPUImageTextureOutput (){
    MVYGPUImageFramebuffer *firstInputFramebuffer;
    
    MVYGLProgram *dataProgram;
    GLint dataPositionAttribute, dataTextureCoordinateAttribute;
    GLint dataInputTextureUniform;
    
    GLuint framebuffer;
    GLint _texture;
    int _textureWidth;
    int _textureHeight;
}

@property (nonatomic, weak) MVYGPUImageContext *context;
@property (nonatomic, assign) CGSize inputSize;

@end

@implementation MVYGPUImageTextureOutput

- (instancetype)initWithContext:(MVYGPUImageContext *)context
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _context = context;
    
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

#pragma mark -
#pragma mark Data access

- (void)renderAtInternalSize;
{
    [self.context useAsCurrentContext];
    [dataProgram use];
    
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, _textureWidth, _textureHeight);
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(dataInputTextureUniform, 4);
    
    glVertexAttribPointer(dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [MVYGPUImageFilter textureCoordinatesForRotation:self.rotateMode]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [firstInputFramebuffer unlock];
}

- (void)setOutputWithBGRATexture:(GLint)texture width:(int)width height:(int)height{
    _texture = texture;
    _textureWidth = width;
    _textureHeight = height;
    
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (!self->framebuffer){
            glGenFramebuffers(1, &(self->framebuffer));
        }
        glBindFramebuffer(GL_FRAMEBUFFER, self->framebuffer);
        
        glBindTexture(GL_TEXTURE_2D, self->_texture);
        
        //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _textureWidth, _textureHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self->_texture, 0);
        
        glBindTexture(GL_TEXTURE_2D, 0);
        
    });
}

-(void)dealloc{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (self->framebuffer){
            glDeleteFramebuffers(1, &(self->framebuffer));
            self->framebuffer = 0;
        }
    });
    
}


#pragma mark -
#pragma mark GPUImageInput protocol

- (void)setInputSize:(CGSize)newSize;
{
    
}

- (void)setInputFramebuffer:(MVYGPUImageFramebuffer *)newInputFramebuffer;
{
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
}

- (void)newFrameReady;
{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [self renderAtInternalSize];
    });
}

@end
