//
//  MVYGPUImageFilter.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageFilter.h"

// Hardcode the vertex shader for standard filters, but this can be overridden
NSString *const kMVYGPUImageVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy;
 }
 );


NSString *const kMVYGPUImagePassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
     gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
 );

@implementation MVYGPUImageFilter

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(MVYGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [super initWithContext:context]))
    {
        return nil;
    }
    
    self.context = context;
    
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        self->filterProgram = [self.context programForVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        
        if (!self->filterProgram.initialized)
        {
            if (![self->filterProgram link])
            {
                NSString *progLog = [self->filterProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [self->filterProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [self->filterProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                self->filterProgram = nil;
                NSAssert(NO, @"Filter shader link failed");
            }
        }
        
        self->filterPositionAttribute = [self->filterProgram attributeIndex:@"position"];
        self->filterTextureCoordinateAttribute = [self->filterProgram attributeIndex:@"inputTextureCoordinate"];
        self->filterInputTextureUniform = [self->filterProgram uniformIndex:@"inputImageTexture"]; // This does self->assume a name of "inputImageTexture" for the fragment shader
        
        [self->filterProgram use];
        
        glEnableVertexAttribArray(self->filterPositionAttribute);
        glEnableVertexAttribArray(self->filterTextureCoordinateAttribute);
    });
    
    return self;
}

- (id)initWithContext:(MVYGPUImageContext *)context fragmentShaderFromString:(NSString *)fragmentShaderString;
{
    if (!(self = [self initWithContext:context vertexShaderFromString:kMVYGPUImageVertexShaderString fragmentShaderFromString:fragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

- (id)initWithContext:(MVYGPUImageContext *)context;
{
    if (!(self = [self initWithContext:context fragmentShaderFromString:kMVYGPUImagePassthroughFragmentShaderString]))
    {
        return nil;
    }
    
    return self;
}

- (void)dealloc
{
    
}

#pragma mark -
#pragma mark Managing the display FBOs

- (CGSize)sizeOfFBO;
{
    return inputTextureSize;
}

#pragma mark -
#pragma mark Rendering

+ (const GLfloat *)textureCoordinatesForRotation:(MVYGPUImageRotationMode)rotationMode;
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    switch(rotationMode)
    {
        case kMVYGPUImageNoRotation: return noRotationTextureCoordinates;
        case kMVYGPUImageRotateLeft: return rotateLeftTextureCoordinates;
        case kMVYGPUImageRotateRight: return rotateRightTextureCoordinates;
        case kMVYGPUImageFlipVertical: return verticalFlipTextureCoordinates;
        case kMVYGPUImageFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kMVYGPUImageRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kMVYGPUImageRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kMVYGPUImageRotate180: return rotate180TextureCoordinates;
    }
}

+ (BOOL)needExchangeWidthAndHeightWithRotation:(MVYGPUImageRotationMode)rotationMode {
    switch(rotationMode)
    {
        case kMVYGPUImageNoRotation: return NO;
        case kMVYGPUImageRotateLeft: return YES;
        case kMVYGPUImageRotateRight: return YES;
        case kMVYGPUImageFlipVertical: return NO;
        case kMVYGPUImageFlipHorizonal: return NO;
        case kMVYGPUImageRotateRightFlipVertical: return YES;
        case kMVYGPUImageRotateRightFlipHorizontal: return YES;
        case kMVYGPUImageRotate180: return NO;
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    [self.context useAsCurrentContext];
    [filterProgram use];
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
    [outputFramebuffer activateFramebuffer];
    
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    
    glUniform1i(filterInputTextureUniform, 2);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
}

- (void)informTargetsAboutNewFrame;
{
    // Get all targets the framebuffer so they can grab a lock on it
    for (id<MVYGPUImageInput> currentTarget in targets)
    {
        [currentTarget setInputSize:[self outputFrameSize]];
        [currentTarget setInputFramebuffer:[self framebufferForOutput]];
    }
    
    // Release our hold so it can return to the cache immediately upon processing
    [[self framebufferForOutput] unlock];
    
    [self removeOutputFramebuffer];
    
    // Trigger processing last, so that our unlock comes first in serial execution, avoiding the need for a callback
    for (id<MVYGPUImageInput> currentTarget in targets)
    {
        [currentTarget newFrameReady];
    }
}

- (CGSize)outputFrameSize;
{
    return inputTextureSize;
}

#pragma mark -
#pragma mark MVYGPUImageInput

- (void)setInputSize:(CGSize)newSize;
{
    inputTextureSize = newSize;
}

- (void)setInputFramebuffer:(MVYGPUImageFramebuffer *)newInputFramebuffer;
{
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
}

- (void)newFrameReady;
{
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    [self renderToTextureWithVertices:imageVertices textureCoordinates:textureCoordinates];
    
    [self informTargetsAboutNewFrame];
}

@end
