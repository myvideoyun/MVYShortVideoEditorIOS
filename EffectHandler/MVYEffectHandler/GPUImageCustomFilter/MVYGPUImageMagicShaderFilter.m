//
//  MVYGPUImageShortVideoFilter.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/5/29.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageMagicShaderFilter.h"
#import <MVYMagicShader/MVYMagicShader.h>

@interface MVYGPUImageMagicShaderFilter() {
    NSMutableDictionary<NSNumber *, MVYMagicShaderEffect *> *shortVideoDic;
    MVYMagicShaderEffect *magicShader;
}

@end

@implementation MVYGPUImageMagicShaderFilter

- (id)initWithContext:(MVYGPUImageContext *)context {
    if (!(self = [super initWithContext:context])) {
        return nil;
    }
    
    self->shortVideoDic = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates {
    
    if (!(self->magicShader = [self->shortVideoDic objectForKey:@(self.type)])) {
        self->magicShader = [[MVYMagicShaderEffect alloc] initWithType:self.type];
        [self->magicShader initGLResource];
        
        [self->shortVideoDic setObject:self->magicShader forKey:@(self.type)];
    }
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions missCVPixelBuffer:YES];
    [outputFramebuffer activateFramebuffer];

    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [self->magicShader processWithTexture:[firstInputFramebuffer texture] width:outputFramebuffer.size.width height:outputFramebuffer.size.height];

    glEnableVertexAttribArray(filterPositionAttribute);
    glEnableVertexAttribArray(filterTextureCoordinateAttribute);

    [firstInputFramebuffer unlock];
}

- (void)setFloatValue:(CGFloat)value forKey:(NSString *)key {
    [self->magicShader setFloatValue:value forKey:key];
}

- (void)reset {
    [self->magicShader reset];
}

- (void)dealloc {
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];

        for (MVYMagicShaderEffect *magicShader in self->shortVideoDic.allValues) {
            [magicShader releaseGLResource];
        }
    });
}

@end
