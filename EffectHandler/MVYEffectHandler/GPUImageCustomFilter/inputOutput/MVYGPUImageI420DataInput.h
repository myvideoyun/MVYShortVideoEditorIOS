//
//  MVYGPUImageI420DataInput.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/4/16.
//  Copyright © 2019年 myvideoyun. All rights reserved.
//

#import "MVYGPUImageOutput.h"

@interface MVYGPUImageI420DataInput : MVYGPUImageOutput

@property (nonatomic, assign) MVYGPUImageRotationMode rotateMode;

/**
 处理YUV数据
 */
- (void)processWithYData:(const void *)yData uData:(const void *)uData vData:(const void *)vData width:(int)width height:(int)height;

@end
