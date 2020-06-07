//
//  MVYGPUImageTextureInput.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageOutput.h"

@interface MVYGPUImageTextureInput : MVYGPUImageOutput

@property (nonatomic, assign) MVYGPUImageRotationMode rotateMode;

/**
 处理纹理

 @param texture 纹理数据
 */
- (void)processWithBGRATexture:(GLint)texture width:(int)width height:(int)height;

@end
