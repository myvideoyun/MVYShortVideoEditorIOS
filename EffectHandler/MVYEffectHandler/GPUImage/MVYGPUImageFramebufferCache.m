//
//  MVYGPUImageFramebufferCache.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageFramebufferCache.h"

#import "MVYGPUImageOutput.h"
#import "MVYGPUImageFramebuffer.h"
#import "MVYGPUImageContext.h"

@interface MVYGPUImageFramebufferCache()
{
    NSMutableDictionary *framebufferCache;
}

@property (nonatomic, weak) MVYGPUImageContext *context;

- (NSString *)hashForSize:(CGSize)size textureOptions:(MVYGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;

@end


@implementation MVYGPUImageFramebufferCache

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(MVYGPUImageContext *)context;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    self.context = context;
    
    framebufferCache = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Framebuffer management

- (NSString *)hashForSize:(CGSize)size textureOptions:(MVYGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    if (missCVPixelBuffer)
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d-CVBF", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
    else
    {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
}

- (MVYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(MVYGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    __block MVYGPUImageFramebuffer *framebufferFromCache = nil;
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:textureOptions missCVPixelBuffer:missCVPixelBuffer];
        
        
        NSMutableArray *frameBufferArr = [self->framebufferCache objectForKey:lookupHash];
        
        if (frameBufferArr != nil && frameBufferArr.count > 0){
            framebufferFromCache = [frameBufferArr lastObject];
            [frameBufferArr removeLastObject];
            [self->framebufferCache setObject:frameBufferArr forKey:lookupHash];
        }
        
        if (framebufferFromCache == nil)
        {
            framebufferFromCache = [[MVYGPUImageFramebuffer alloc] initWithContext:self.context size:framebufferSize textureOptions:textureOptions missCVPixelBuffer:missCVPixelBuffer];
        }
    });
    
    [framebufferFromCache lock];
    return framebufferFromCache;
}

- (MVYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    MVYGPUTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    
    return [self fetchFramebufferForSize:framebufferSize textureOptions:defaultTextureOptions missCVPixelBuffer:missCVPixelBuffer];
}

- (void)returnFramebufferToCache:(MVYGPUImageFramebuffer *)framebuffer;
{
    [framebuffer clearAllLocks];
    
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        CGSize framebufferSize = framebuffer.size;
        MVYGPUTextureOptions framebufferTextureOptions = framebuffer.textureOptions;
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:framebufferTextureOptions missCVPixelBuffer:framebuffer.missCVPixelBuffer];
        
        NSMutableArray *frameBufferArr = [self->framebufferCache objectForKey:lookupHash];
        if (!frameBufferArr) {
            frameBufferArr = [NSMutableArray array];
        }
        
        [frameBufferArr addObject:framebuffer];
        [self->framebufferCache setObject:frameBufferArr forKey:lookupHash];
        
    });
}

@end

