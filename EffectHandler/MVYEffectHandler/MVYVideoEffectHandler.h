//
//  MVYVideoEffectHandler.h
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/4/17.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "MVYGPUImageConstants.h"
#import "MVYGPUImageStickerModel.h"

@interface MVYVideoEffectHandler : NSObject

/**
 输出的纹理数据宽度
 */
@property (nonatomic, assign, readonly) int outputWidth;

/**
 输出的纹理数据高度
 */
@property (nonatomic, assign, readonly) int outputHeight;

/**
 设置输入的数据旋转或者翻转, 共8个方向
 */
@property (nonatomic, assign) MVYGPUImageRotationMode rotateMode;

/**
 设置输出的画面是否镜像
 */
@property (nonatomic, assign) BOOL mirror;

/**
 初始化判断是否是处理纹理数据
 */
- (instancetype)initWithProcessTexture:(Boolean)isProcessTexture;

/**
 添加贴纸
 */
- (void)addStickerWithModel:(MVYGPUImageStickerModel *)model;

/**
 删除贴纸
 */
- (void)removeStickerWithModel:(MVYGPUImageStickerModel *)model;

/**
 删除全部贴纸
 */
- (void)clearSticker;

/**
 设置特效
 */
- (void)setTypeOfMagicShaderEffect:(NSInteger)type;

/**
 重置特效
 */
- (void)resetMagicShaderEffect;

/**
 处理原始数据, 格式为I420, 一般用于安卓设备
 
 ----------Panel0
 Y1 Y2 Y3 Y4
 Y5 Y6 Y7 Y8
 ----------Panel1
 U1 U2
 ----------Panel2
 V1 V2
 
 @param yBuffer 灰度数据
 @param uBuffer 色度数据
 @param vBuffer 色度数据
 @param width 宽度
 @param height 高度
 @param bgraBuffer 输出的数据
 */
- (void)processWithYBuffer:(NSData *)yBuffer uBuffer:(NSData *)uBuffer vBuffer:(NSData *)vBuffer width:(int)width height:(int)height bgraBuffer:(void *)bgraBuffer;

- (void)destroy;

@end
