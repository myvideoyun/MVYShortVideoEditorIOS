//
//  MVYGPUImageTextureTransitionInput.h
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/6/29.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageOutput.h"
#import "MVYGPUImageTextureModel.h"

@interface MVYGPUImageTextureTransitionInput : MVYGPUImageOutput

// 设置需要渲染的纹理
@property (nonatomic, strong) NSArray<MVYGPUImageTextureModel *> *renderTextures;

// 渲染
- (void)processWithWidth:(int)width height:(int)height;

@end
