//
//  MVYGPUImageTextureOutput.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVYGPUImageFilter.h"
#import "MVYGPUImageContext.h"

@interface MVYGPUImageTextureOutput : NSObject<MVYGPUImageInput>

@property (nonatomic, assign) MVYGPUImageRotationMode rotateMode;

- (instancetype)initWithContext:(MVYGPUImageContext *)context;

/**
 设置输出BGRA纹理

 @param texture BGRA纹理
 */
- (void)setOutputWithBGRATexture:(GLint)texture width:(int)width height:(int)height;

@end
