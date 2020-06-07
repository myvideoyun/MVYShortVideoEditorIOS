//
//  MVYGPUImageOutput.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MVYGPUImageFramebuffer.h"
#import "MVYGPUImageContext.h"

@interface MVYGPUImageOutput : NSObject
{
    MVYGPUImageFramebuffer *outputFramebuffer;
    
    NSMutableArray *targets;
    
    CGSize inputTextureSize;
}

@property (nonatomic, weak) MVYGPUImageContext *context;
@property(readwrite, nonatomic) MVYGPUTextureOptions outputTextureOptions;

- (id)initWithContext:(MVYGPUImageContext *)context;

- (MVYGPUImageFramebuffer *)framebufferForOutput;

- (void)removeOutputFramebuffer;

- (NSArray*)targets;

- (void)addTarget:(id<MVYGPUImageInput>)newTarget;

- (void)removeTarget:(id<MVYGPUImageInput>)targetToRemove;

- (void)removeAllTargets;

@end
