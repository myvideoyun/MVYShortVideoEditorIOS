//
//  MVYMediaPlayer.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/8/2.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVYAudioPlayer.h"
#import "MVYVideoPlayer.h"

@protocol MVYMediaPlayerDelegate <NSObject>
@required

/**
 * 返回需要渲染的帧数据
 */
- (void)videoPlayerOutputWithFrame:(MVYVideoFrame *)videoFrame;

/**
 * 返回需要渲染的帧数据
 */
- (void)audioPlayerOutputWithFrame:(MVYAudioFrame *)audioFrame;

/**
 * 播放停止完成
 */
- (void)videoPlayerStop;

/**
 * 播放结束
 */
- (void)videoPlayerFinish;

@optional
/**
 * 播放停止完成
 */
- (void)audioPlayerStop;

/**
 * 播放结束
 */
- (void)audioPlayerFinish;

@end

@interface MVYMediaPlayer : NSObject

// 回调音视频数据
@property (nonatomic, weak) id<MVYMediaPlayerDelegate> playerDelegate;

// 初始化
- (instancetype)initWithVideoPaths:(NSArray<NSString *> *)videoPaths audioPaths:(NSArray<NSString *> *)audioPaths;

// 开始播放
- (void)startPlayWithSeekTime:(int64_t)seekTime;
- (void)startPlay;

// 开始倒放
- (void)startReversePlayWithSeekTime:(int64_t)seekTime;
- (void)startReversePlay;

// 开始慢放
- (void)startSlowPlayWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)slowTimeRange;
- (void)startSlowPlayWithSlowTimeRange:(NSRange)slowTimeRange;

// start play fast
- (void)startFastPlayWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)slowTimeRange;

// 停止播放
- (void)stopPlay;

@end

