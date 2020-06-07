//
//  MVYVideoPlayer.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/7/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MVYVideoPlayer;
@class MVYVideoFrame;

// 播放器同步协议
@protocol MVYVideoPlayerSyncProtocol <NSObject>
@required

// 播放器第一帧的时间, 用于音频播放器同步
@property(nonatomic, assign) int64_t playerFirstFrameTime;

@end

/**
 * 播放监听
 */
@protocol MVYVideoPlayerDelegate <NSObject>
@required
/**
 * 返回需要渲染的帧数据
 */
- (void)videoPlayerOutputWithFrame:(MVYVideoFrame *)videoFrame;

@optional
/**
 * 播放停止完成
 */
- (void)videoPlayerStop;

/**
 * 播放结束
 */
- (void)videoPlayerFinish;

@end

@interface MVYVideoPlayer : NSObject <MVYVideoPlayerSyncProtocol>

// 回调协议
@property (nonatomic, weak) id<MVYVideoPlayerDelegate> playerDelegate;

// 初始化
- (instancetype)initWithPaths:(NSArray<NSString *> *)paths;

// 开始播放
- (void)startPlayWithSeekTime:(int64_t)seekTime;
- (void)startPlay;

// 开始倒放
- (void)startReversePlayWithSeekTime:(int64_t)seekTime;
- (void)startReversePlay;

// 开始慢放
- (void)startSlowPlayWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)slowTimeRange;
- (void)startSlowPlayWithSlowTimeRange:(NSRange)slowTimeRange;

// play fast
- (void)startFastPlayWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)slowTimeRange;

// 停止播放
- (void)stopPlay;

@end
