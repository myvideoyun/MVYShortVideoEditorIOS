//
//  MVYGPUImageContext.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <OpenGLES/EAGLDrawable.h>
#import <AVFoundation/AVFoundation.h>

@class MVYGLProgram;
@class MVYGPUImageFramebuffer;

#import "MVYGPUImageFramebufferCache.h"
#import "MVYGPUImageConstants.h"

void runMVYSynchronouslyOnContextQueue(MVYGPUImageContext *context, void (^block)(void));

@interface MVYGPUImageContext : NSObject

@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readonly, nonatomic) void *contextKey;
@property(readonly, retain, nonatomic) EAGLContext *context;
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(readonly, retain, nonatomic) MVYGPUImageFramebufferCache *framebufferCache;

- (instancetype)initWithNewGLContext;

- (instancetype)initWithCurrentGLContext;

- (void)useAsCurrentContext;

- (void)presentBufferForDisplay;

- (MVYGLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

@end

@protocol MVYGPUImageInput <NSObject>

- (void)setInputSize:(CGSize)newSize;
- (void)setInputFramebuffer:(MVYGPUImageFramebuffer *)newInputFramebuffer;
- (void)newFrameReady;

@end
