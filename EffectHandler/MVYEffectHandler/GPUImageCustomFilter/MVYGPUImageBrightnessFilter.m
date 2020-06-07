//
//  MVYGPUImageBrightnessFilter.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/5/7.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageBrightnessFilter.h"

NSString *const kMVYGPUImageBrightnessFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform lowp float brightness;
 
 void main()
 {
     lowp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     gl_FragColor = vec4((textureColor.rgb + vec3(brightness)), textureColor.w);
 }
);

@interface MVYGPUImageBrightnessFilter () {
    GLint intensityUniform;
}

@end

@implementation MVYGPUImageBrightnessFilter

- (id)initWithContext:(MVYGPUImageContext *)context{
    if (!(self = [super initWithContext:context vertexShaderFromString:kMVYGPUImageVertexShaderString fragmentShaderFromString:kMVYGPUImageBrightnessFragmentShaderString])) {
        return nil;
    }
    
    runMVYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        self->intensityUniform = [self->filterProgram uniformIndex:@"brightness"];
    });
    
    self.intensity = 0.0f;
    
    return self;
}

#pragma mark -
#pragma mark Rendering

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    [filterProgram use];
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
    [outputFramebuffer activateFramebuffer];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(filterInputTextureUniform, 2);
    
    glUniform1f(intensityUniform, self.intensity);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    
}

@end
