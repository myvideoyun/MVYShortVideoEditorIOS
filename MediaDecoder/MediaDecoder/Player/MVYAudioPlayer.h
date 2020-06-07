//
//  MVYAudioPlayer.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/7/30.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MVYAudioPlayer;
@class MVYAudioFrame;

// 播放器同步协议
@protocol MVYAudioPlayerSyncProtocol <NSObject>
@required

// 播放器第一帧的时间, 用于视频播放器同步
@property(nonatomic, assign) int64_t playerFirstFrameTime;

@end

/**
 * 播放监听
 */
@protocol MVYAudioPlayerDelegate <NSObject>
@required
/**
 * 返回需要渲染的帧数据
 */
- (void)audioPlayerOutputWithFrame:(MVYAudioFrame *)audioFrame;

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

@interface MVYAudioPlayer : NSObject <MVYAudioPlayerSyncProtocol>

// 回调数据
@property (nonatomic, weak) id<MVYAudioPlayerDelegate> playerDelegate;

// 初始化
- (instancetype)initWithPaths:(NSArray<NSString *> *)paths;

// 开始播放
- (void)startPlayWithSeekTime:(int64_t)seekTime;
- (void)startPlay;

// 开始慢放
- (void)startSlowPlayWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)slowTimeRange;
- (void)startSlowPlayWithSlowTimeRange:(NSRange)slowTimeRange;

// 停止播放
- (void)stopPlay;

@end

