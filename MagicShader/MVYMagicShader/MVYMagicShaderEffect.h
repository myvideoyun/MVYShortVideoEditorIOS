//
//  MVYMagicShaderEffect.h
//  MVYMagicShader
//
//  Created by myvideoyun on 2019/5/26.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MVYMagicShaderEffect : NSObject

/**
 短视频类型
 */
- (instancetype)initWithType:(int)type;

/**
 初始化opengl相关的资源
 */
- (void)initGLResource;

/**
 释放opengl相关的资源
 */
- (void)releaseGLResource;

/**
 设置参数
 */
- (void)setFloatValue:(float)value forKey:(NSString *)key;

/**
 绘制特效
 
 @param texture 纹理数据
 @param width 宽度
 @param height 高度
 */
- (void)processWithTexture:(int)texture width:(int)width height:(int)height;

/**
 重置特效
 */
- (void)reset;


@end
