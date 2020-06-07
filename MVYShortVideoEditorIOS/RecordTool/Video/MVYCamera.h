//
//  MVYCamera.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol MVYCameraDelegate <NSObject>
@optional

/**
 视频数据回调 BGRA格式

 @param sampleBuffer 数据
 */
- (void)cameraVideoOutput:(CMSampleBufferRef)sampleBuffer;

/**
 音频数据回调

 @param sampleBuffer 数据
 */
- (void)cameraAudioOutput:(CMSampleBufferRef)sampleBuffer;

@end

@interface MVYCamera : NSObject

@property (nonatomic, weak) id <MVYCameraDelegate> delegate;

/**
 设置前后相机
 */
@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;

/**
 初始化指定分辨率的相机
 */
- (instancetype)initWithResolution:(AVCaptureSessionPreset)resolution;

/**
 设置帧率
 */
- (void)setFrameRate:(int)rate;

/**
 设置手电筒
 */
- (void)setTorchOn:(BOOL)torchMode;

/**
 设置焦点
 */
- (void)focusAtPoint:(CGPoint)focusPoint;

/**
 打开相机, 麦克风
 */
- (void)startCapture;

/**
 关闭相机, 麦克风
 */
- (void)stopCapture;

@end
