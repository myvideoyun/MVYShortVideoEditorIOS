//
//  MVYGPUImageOutput.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageOutput.h"

@implementation MVYGPUImageOutput

@synthesize outputTextureOptions = _outputTextureOptions;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(MVYGPUImageContext *)context;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    targets = [[NSMutableArray alloc] init];
    
    // set default texture options
    _outputTextureOptions.minFilter = GL_LINEAR;
    _outputTextureOptions.magFilter = GL_LINEAR;
    _outputTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    _outputTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    _outputTextureOptions.internalFormat = GL_RGBA;
    _outputTextureOptions.format = GL_BGRA;
    _outputTextureOptions.type = GL_UNSIGNED_BYTE;
    
    self.context = context;
    
    return self;
}

- (void)dealloc
{
    [self removeAllTargets];
}

#pragma mark -
#pragma mark Managing targets

- (MVYGPUImageFramebuffer *)framebufferForOutput;
{
    return outputFramebuffer;
}

- (void)removeOutputFramebuffer;
{
    outputFramebuffer = nil;
}

- (NSArray*)targets;
{
    return [NSArray arrayWithArray:targets];
}

- (void)addTarget:(id<MVYGPUImageInput>)newTarget;
{
    if([targets containsObject:newTarget])
    {
        return;
    }
    
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self->targets addObject:newTarget];
    });
}

- (void)removeTarget:(id<MVYGPUImageInput>)targetToRemove;
{
    if(![targets containsObject:targetToRemove])
    {
        return;
    }
    
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self->targets removeObject:targetToRemove];
    });
}

- (void)removeAllTargets;
{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self->targets removeAllObjects];
    });
}

@end
