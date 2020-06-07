//
//  MVYImageEffectHandler.h
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/7/1.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "MVYGPUImageConstants.h"
#import "MVYGPUImageTextureModel.h"

@interface MVYImageEffectHandler : NSObject

/**
 初始化判断是否是处理纹理数据
 */
- (instancetype)initWithProcessTexture:(Boolean)isProcessTexture;

/**
 设置要渲染的纹理
 */
- (void)setRenderTextures:(NSArray<MVYGPUImageTextureModel *> *)renderTextures;

/**
 渲染
 */
- (void)processWithWidth:(int)width height:(int)height rotateMode:(MVYGPUImageRotationMode)rotateMode bgraBuffer:(void *)bgraBuffer;

@end
