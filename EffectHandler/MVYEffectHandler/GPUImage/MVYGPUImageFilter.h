//
//  MVYGPUImageFilter.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "MVYGPUImageOutput.h"
#import "MVYGLProgram.h"
#import "MVYGPUImageFramebuffer.h"
#import "MVYGPUImageConstants.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

extern NSString *const kMVYGPUImageVertexShaderString;
extern NSString *const kMVYGPUImagePassthroughFragmentShaderString;

@interface MVYGPUImageFilter : MVYGPUImageOutput <MVYGPUImageInput>
{
    
    MVYGPUImageFramebuffer *firstInputFramebuffer;
    
    MVYGLProgram *filterProgram;
    
    GLint filterPositionAttribute, filterTextureCoordinateAttribute;
    GLint filterInputTextureUniform;
}

@property(readonly) CVPixelBufferRef renderTarget;

- (id)initWithContext:(MVYGPUImageContext *)context vertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithContext:(MVYGPUImageContext *)context fragmentShaderFromString:(NSString *)fragmentShaderString;

- (id)initWithContext:(MVYGPUImageContext *)context;

- (CGSize)sizeOfFBO;

/// @name Rendering
+ (const GLfloat *)textureCoordinatesForRotation:(MVYGPUImageRotationMode)rotationMode;
+ (BOOL)needExchangeWidthAndHeightWithRotation:(MVYGPUImageRotationMode)rotationMode;
- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;

- (void)informTargetsAboutNewFrame;

@end
