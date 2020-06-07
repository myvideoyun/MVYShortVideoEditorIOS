//
//  MVYCameraEffectHandler.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>
#import "MVYGPUImageConstants.h"
#import "MVYGPUImageStickerModel.h"

@interface MVYCameraEffectHandler : NSObject

/**
 设置风格滤镜
 */
@property (nonatomic, strong) UIImage *style;
@property (nonatomic, assign) CGFloat intensityOfStyle;

/**
 设置磨皮 [0-1]
 */
@property (nonatomic, assign) CGFloat intensityOfBeauty;

/**
 设置亮度 [0-1]
 */
@property (nonatomic, assign) CGFloat intensityOfBrightness;

/**
 设置饱合度 [0-1]
 */
@property (nonatomic, assign) CGFloat intensityOfSaturation;

/**
 设置zoom 默认为1, 大于1放大画面, 小于1缩小画面
 */
@property (nonatomic, assign) CGFloat intensityOfZoom;

/**
 设置特效旋转或者翻转, 共8个方向
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
 处理iOS封装的数据
 
 @param pixelBuffer 只支持 kCVPixelFormatType_32BGRA
 */
- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)destroy;

@end
