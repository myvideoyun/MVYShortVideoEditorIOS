//
//  MVYVideoDecoder.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/4/16.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVYVideoFrame.h"
#import "MVYReadWriteLock.h"

/**
 * 解码监听
 */
@protocol MVYVideoDecoderDelegate <NSObject>
@required
/**
 * 返回解码成功的帧数据
 */
- (void)videoDecoderOutputWithFrame:(MVYVideoFrame *)videoFrame;

/**
 * 解码停止
 */
- (void)videoDecoderStop;

/**
 * 解码完成
 */
- (void)videoDecoderFinish;

@end

@interface MVYVideoDecoder : NSObject {
    
    // 解码器
    NSMutableArray<NSNumber *> *_ffVideoDecoders;
    
    // 解码锁
    bool _isDecodeStop;
    MVYReadWriteLock *_decodeLock;
        
    // 解码线程
    dispatch_queue_t _decodeQueue;
    
    // 解码器seek
    int64_t _seekTime;
}

@property (nonatomic, weak) id<MVYVideoDecoderDelegate> decoderDelegate;

// 创建本地解码器
- (void)createNativeVideoDecoder:(NSArray<NSString *> *)paths;

// 销毁本地解码器
- (void)destroyNativeVideoDecoder;

// 从指定时间开始解码
- (void)startDecodeWithSeekTime:(int64_t)seekTime;
- (void)startDecodeWithSeekTime:(int64_t)seekTime handleVideoFrame:(MVYVideoFrame *(^)(MVYVideoFrame *))handleVideoFrame;

// 停止解码器
- (void)stopDecoder;

@end
