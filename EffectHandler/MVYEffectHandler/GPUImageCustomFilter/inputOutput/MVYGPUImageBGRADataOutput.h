//
//  MVYGPUImageBGRADataOutput.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/4/16.
//  Copyright © 2019年 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVYGPUImageFilter.h"
#import "MVYGPUImageContext.h"

@interface MVYGPUImageBGRADataOutput : NSObject<MVYGPUImageInput>

@property (nonatomic, assign) MVYGPUImageRotationMode rotateMode;

- (instancetype)initWithContext:(MVYGPUImageContext *)context;

/**
 设置输出BGRA数据

 @param pixelBuffer 用于存储输出数据的CVPixelBuffer
 */
- (void)setOutputWithBGRAPixelBuffer:(CVPixelBufferRef)pixelBuffer;

/**
 设置输出BGRA数据

 @param bgraData 原始BGRA数据
 @param width 宽
 @param height 高
 */
- (void)setOutputWithBGRAData:(void *)bgraData width:(int)width height:(int)height;

@end
