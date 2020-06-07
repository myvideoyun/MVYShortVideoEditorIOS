//
//  MVYGPUImageFramebuffer.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>

#import "MVYGPUImageContext.h"
#import "MVYGPUImageConstants.h"

@interface MVYGPUImageFramebuffer : NSObject

@property(readonly) CGSize size;
@property(readonly) MVYGPUTextureOptions textureOptions;
@property(readonly) GLuint texture;
@property(readonly) BOOL missCVPixelBuffer;
@property(readonly) NSUInteger framebufferReferenceCount;
@property(nonatomic, weak) MVYGPUImageContext *context;

// Initialization and teardown

- (id)initWithContext:(MVYGPUImageContext *)context size:(CGSize)framebufferSize textureOptions:(MVYGPUTextureOptions)fboTextureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;

// Usage
- (void)activateFramebuffer;

// Reference counting
- (void)lock;
- (void)unlock;
- (void)clearAllLocks;

//// Raw data bytes
//- (void)lockForReading;
//- (void)unlockAfterReading;
- (NSUInteger)bytesPerRow;
- (GLubyte *)byteBuffer;
- (CVPixelBufferRef)pixelBuffer;
- (UIImage *)image;

@end
