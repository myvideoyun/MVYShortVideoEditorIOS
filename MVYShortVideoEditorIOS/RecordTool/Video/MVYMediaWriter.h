//
//  MVYMediaWriter.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 音视频存储
 音频存储为.m4a
 视频存储为.m4v
 */
@interface MVYMediaWriter : NSObject

/**
 最后一帧视频画面的时间
 */
@property (nonatomic, assign, readonly) CMTime lastFramePresentationTimeStamp;

/**
 设置视频保存位置
*/
@property (nonatomic, strong) NSURL *outputVideoURL;

/**
 设置视频速度
 Range: 0.25 -> 4.0
 Default: 1.0
 */
@property (nonatomic, assign) CMTime videoSpeed;

/**
 视频宽度
 */
@property (nonatomic, assign) NSInteger videoWidth;

/**
 视频高度
 */
@property (nonatomic, assign) NSInteger videoHeight;

/**
 视频码率
 */
@property (nonatomic, assign) NSInteger videoBitRate;

/**
 音频码率
 */
@property (nonatomic, assign) NSInteger audioBitRate;

/**
 视频帧率
 */
@property (nonatomic, assign) NSInteger videoFrameRate;

/**
 设置音频保存位置
 */
@property (nonatomic, strong) NSURL *outputAudioURL;

/**
 设置音视频保存位置
 */
@property (nonatomic, strong) NSURL *outputMediaURL;

/**
 单例
 */
+ (MVYMediaWriter *)sharedInstance;

/**
 写音频数据
 */
- (void)writeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 写视频数据
 */
- (void)writeVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)frameTime;

/**
 写入完成
 */
- (void)finishWritingWithCompletionHandler:(void (^)(void))handler;

/**
 取消写入
 */
- (void)cancelWriting;

/**
 是否写入完成
 */
- (BOOL)isWriteFinish;

@end

@interface MVYMediaWriterTool : NSObject

/**
 44100采样率的PCM数据转成SampleBuffer
 */
+ (CMSampleBufferRef)PCMDataToSampleBuffer:(NSData *)pcmData pts:(CMTime)pts duration:(CMTime)duration;

@end
