//
//  MVYGPUImageBGRADataInput.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/4/16.
//  Copyright © 2019年 myvideoyun. All rights reserved.
//

#import "MVYGPUImageOutput.h"

@interface MVYGPUImageBGRADataInput : MVYGPUImageOutput

@property (nonatomic, assign) MVYGPUImageRotationMode rotateMode;

/**
 处理BGRA数据
 
 @param pixelBuffer BGRA格式的pixelBuffer
 */
- (void)processWithBGRAPixelBuffer:(CVPixelBufferRef)pixelBuffer;


/**
 处理BGRA数据

 @param bgraData 原始数据
 */
- (void)processWithBGRAData:(void *)bgraData width:(int)width height:(int)height;

@end
