//
//  MVYGPUImageFramebufferCache.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#import "MVYGPUImageConstants.h"

@class MVYGPUImageFramebuffer;
@class MVYGPUImageContext;

@interface MVYGPUImageFramebufferCache : NSObject

// Framebuffer management
- (id)initWithContext:(MVYGPUImageContext *)context;

- (MVYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(MVYGPUTextureOptions)textureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;

- (MVYGPUImageFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize missCVPixelBuffer:(BOOL)missCVPixelBuffer;

- (void)returnFramebufferToCache:(MVYGPUImageFramebuffer *)framebuffer;

@end
