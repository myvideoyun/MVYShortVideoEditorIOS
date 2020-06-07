//
//  MVYGPUImageMirrorFilter.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/5/28.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageMirrorFilter.h"

@implementation MVYGPUImageMirrorFilter

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates {
    
    if (self.mirror) {
        [super renderToTextureWithVertices:vertices textureCoordinates:[MVYGPUImageFilter textureCoordinatesForRotation:kMVYGPUImageFlipHorizonal]];
    } else {
        [super renderToTextureWithVertices:vertices textureCoordinates:textureCoordinates];
    }
}

@end
