//
//  MVYGPUImageZoomFilter.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/5/7.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageZoomFilter.h"

@implementation MVYGPUImageZoomFilter

#pragma mark -
#pragma mark Rendering

- (id)initWithContext:(MVYGPUImageContext *)context {
    if (!(self = [super initWithContext:context])) {
        return nil;
    }
    
    _zoom = 1.0f;
    
    return self;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates;
{
    const GLfloat squareVertices[] = {
        vertices[0] * self.zoom, vertices[1] * self.zoom,
        vertices[2] * self.zoom, vertices[3] * self.zoom,
        vertices[4] * self.zoom, vertices[5] * self.zoom,
        vertices[6] * self.zoom, vertices[7] * self.zoom,
    };
    
    [super renderToTextureWithVertices:squareVertices textureCoordinates:textureCoordinates];
}
@end
