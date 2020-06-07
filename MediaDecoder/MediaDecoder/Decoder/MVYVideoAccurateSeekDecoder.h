//
//  MVYVideoAccurateSeekDecoder.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/4/29.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVYVideoFrame.h"

@class MVYVideoAccurateSeekDecoder;

/**
 * 解码监听
 */
@protocol MVYVideoAccurateSeekDecoderDelegate <NSObject>
@required

/**
 * 解码停止
 */
- (void)videoAccurateSeekStop;

@end

@interface MVYVideoAccurateSeekDecoder : NSObject

@property (nonatomic, weak) id<MVYVideoAccurateSeekDecoderDelegate> decoderDelegate;

// 创建本地解码器
- (void)createNativeVideoDecoder:(NSArray<NSString *> *)paths;

// 销毁本地解码器
- (void)destroyNativeVideoDecoder;

// 开始精准Seek解码
- (void)startAccurateSeekDecode;

// 停止解码器
- (void)stopDecoder;

// 获取跳转时间附近的视频帧
- (MVYVideoFrame *)frameWithSeekTime:(int64_t) seekTime;

@end
