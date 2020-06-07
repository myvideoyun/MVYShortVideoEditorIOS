//
//  MVYAudioDecoder.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/4/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVYAudioFrame.h"
#import "MVYReadWriteLock.h"

/**
 * 解码监听
 */
@protocol MVYAudioDecoderDelegate <NSObject>
@required
/**
 * 返回解码成功的帧数据
 */
- (void)audioDecoderOutputWithFrame:(MVYAudioFrame *)audioFrame;

/**
 * 解码停止
 */
- (void)audioDecoderStop;

/**
 * 解码完成
 */
- (void)audioDecoderFinish;

@end

@interface MVYAudioDecoder : NSObject {
    
    // 解码器
    NSMutableArray<NSNumber *> *_ffAudioDecoders;
    
    // 解码锁
    bool _isDecodeStop;
    MVYReadWriteLock *_decodeLock;
    
    // 解码线程
    dispatch_queue_t _decodeQueue;
    
    // 解码器seek
    int64_t _seekTime;
}

@property (nonatomic, weak) id<MVYAudioDecoderDelegate> decoderDelegate;

// 创建本地解码器
- (void)createNativeAudioDecoder:(NSArray<NSString *> *)paths;

// 销毁本地解码器
- (void)destroyNativeAudioDecoder;

// 从指定时间开始解码
- (void)startDecodeWithSeekTime:(int64_t)seekTime;
- (void)startDecodeWithSeekTime:(int64_t)seekTime handleAudioFrame:(MVYAudioFrame *(^)(MVYAudioFrame *))handleAudioFrame;

// 停止解码器
- (void)stopDecoder;

@end
