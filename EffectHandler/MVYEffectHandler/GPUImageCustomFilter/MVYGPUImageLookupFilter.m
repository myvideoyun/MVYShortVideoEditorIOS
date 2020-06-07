//
//  MVYGPUImageLookupFilter.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageLookupFilter.h"

NSString *const kMVYGPUImageLookupVertexShaderString = SHADER_STRING
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

NSString *const kMVYGPUImageLookupFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2; // lookup texture
 
 uniform lowp float intensity;
 
 void main()
 {
     highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
     
     highp float blueColor = textureColor.b * 63.0;
     
     highp vec2 quad1;
     quad1.y = floor(floor(blueColor) / 8.0);
     quad1.x = floor(blueColor) - (quad1.y * 8.0);
     
     highp vec2 quad2;
     quad2.y = floor(ceil(blueColor) / 8.0);
     quad2.x = ceil(blueColor) - (quad2.y * 8.0);
     
     highp vec2 texPos1;
     texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     highp vec2 texPos2;
     texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);
     
     lowp vec4 newColor1 = texture2D(inputImageTexture2, texPos1);
     lowp vec4 newColor2 = texture2D(inputImageTexture2, texPos2);
     
     lowp vec4 newColor = mix(newColor1, newColor2, fract(blueColor));
     gl_FragColor = mix(textureColor, vec4(newColor.rgb, textureColor.w), intensity);
 }
 );

@interface MVYGPUImageLookupFilter(){
    GLint filterInputTextureUniform2;
    GLint intensityUniform;
    
    GLuint lookupTexture;
    BOOL updateLookupTexture;
}

@end

@implementation MVYGPUImageLookupFilter

- (id)initWithContext:(MVYGPUImageContext *)context{
    if (!(self = [super initWithContext:context vertexShaderFromString:kMVYGPUImageLookupVertexShaderString fragmentShaderFromString:kMVYGPUImageLookupFragmentShaderString])) {
        return nil;
    }
    
    runMVYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        self->filterInputTextureUniform2 = [self->filterProgram uniformIndex:@"inputImageTexture2"];
        
        self->intensityUniform = [self->filterProgram uniformIndex:@"intensity"];
        
        // 创建LookupTexture
        glGenTextures(1, &(self->lookupTexture));
        glBindTexture(GL_TEXTURE_2D, self->lookupTexture);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    });
    
    self.intensity = 0.8f;
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"EffectHandler" ofType:@"bundle"]];
    NSString *path = [bundle pathForResource:@"lookup" ofType:@"png"];
    
    self.lookup = [UIImage imageWithContentsOfFile:path];
    
    return self;
}

- (void)setLookup:(UIImage *)lookup{
    _lookup = lookup;
    
    updateLookupTexture = YES;
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

    glActiveTexture(GL_TEXTURE3);
    if (updateLookupTexture) { // 更新Lookup
        NSData* data =  (id)CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(self.lookup.CGImage)));
        const uint8_t* bytes = [data bytes];
        glBindTexture(GL_TEXTURE_2D, lookupTexture);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 512, 512, 0, GL_RGBA, GL_UNSIGNED_BYTE, bytes);
        
        updateLookupTexture = NO;
    }else {
        glBindTexture(GL_TEXTURE_2D, lookupTexture);
    }
    glUniform1i(filterInputTextureUniform2, 3);
    
    glUniform1f(intensityUniform, _intensity);
    
    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    [firstInputFramebuffer unlock];

}

- (void)dealloc{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (self->lookupTexture) {
            glDeleteTextures(1, &(self->lookupTexture));
            self->lookupTexture = 0;
        }
    });
}

@end
