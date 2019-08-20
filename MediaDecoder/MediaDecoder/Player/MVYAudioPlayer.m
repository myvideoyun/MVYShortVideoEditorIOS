//
//  MVYAudioPlayer.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/7/30.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYAudioPlayer.h"
#import "MVYAudioDecoder.h"
#import "MVYAudioDecoder+Slow.h"
#import "MVYAudioFrame.h"
#import "MVYBlockingQueue.h"

static NSString *TAG = @"AudioPlayer";

@interface MVYAudioPlayer () <MVYAudioDecoderDelegate> {
    
    // 解码器
    MVYAudioDecoder *_audioDecoder;
    
    // 缓存数据队列
    MVYBlockingQueue *_framesQueue;
    
    // 播放锁
    bool _isPlayerStop;
    MVYReadWriteLock *_playerLock;
    
    // 播放线程
    dispatch_queue_t _playerQueue;
    
    // 解码器seek
    int64_t _seekTime;
    
    // 播放器第一帧的时间
    int64_t _playerFirstFrameTime;
}

@end

@implementation MVYAudioPlayer

- (instancetype)initWithPaths:(NSArray<NSString *> *)paths {
    
    self = [super init];
    if (self) {
        
        // 第一帧的时间
        _playerFirstFrameTime = 0;
        
        // 播放锁
        _playerLock = [[MVYReadWriteLock alloc] init];
        
        // 缓存数据
        _framesQueue = [[MVYBlockingQueue alloc] initWithCapacity:100];
        
        // 播放处理队列
        _playerQueue = dispatch_queue_create("com.myvideoyun.audio.player", DISPATCH_QUEUE_SERIAL);
        
        // 创建解码器
        _audioDecoder  = [[MVYAudioDecoder alloc] init];
        _audioDecoder.decoderDelegate = self;
        [_audioDecoder createNativeAudioDecoder:paths];
    }
    return self;
}

// 开始播放
- (void)startPlayWithSeekTime:(int64_t)seekTime {
    _seekTime = seekTime;
    
    // 开始解码
    [_audioDecoder startDecodeWithSeekTime:seekTime];
    
    // 播放解码出来的视频帧
    [self loopPlayDecoderFrame];
}

- (void)startPlay {
    [self startPlayWithSeekTime:0];
}

// 开始慢放
- (void)startSlowPlayWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)slowTimeRange {
    _seekTime = seekTime;
    
    // 设置缓存数据量
    _framesQueue = [[MVYBlockingQueue alloc] initWithCapacity:1];
    
    // 开始解码
    [_audioDecoder startSlowDecodeWithSeekTime:seekTime slowTimeRange:slowTimeRange];
    
    // 播放解码出来的视频帧
    [self loopPlayDecoderFrame];
}

- (void)startSlowPlayWithSlowTimeRange:(NSRange)slowTimeRange {
    [self startSlowPlayWithSeekTime:0 slowTimeRange:slowTimeRange];
}

// 播放解码出来的音频帧
- (void)loopPlayDecoderFrame {
    // 重置新播放器的状态
    _isPlayerStop = false;
    
    // 解码出的第一帧对应的系统时间
    _playerFirstFrameTime = 0;
    
    dispatch_async(_playerQueue, ^{
        
        NSLog(@"%@ 开启播放线程", TAG);
        while (true) {
            // 加锁
            [_playerLock.readLock lock];
            
            if (_isPlayerStop) {
            
                NSLog(@"%@ 停止播放", TAG);
                
                if (self.playerDelegate != NULL && [self.playerDelegate respondsToSelector:@selector(audioPlayerStop)]) {
                    [self.playerDelegate audioPlayerStop];
                }
                
                [_playerLock.readLock unlock];
                
                return;
            }
        
            MVYAudioFrame *frame = [_framesQueue take];
            
            // 解码到最后一帧
            if (frame.flag < 0) {
                
                if (frame.flag == -2) {
                    NSLog(@"%@ 停止播放", TAG);
                } else {
                    NSLog(@"%@ 播放完成", TAG);
                }
                
                _isPlayerStop = true;
                
                if (self.playerDelegate != NULL) {
                    if (frame.flag == -2) {
                        if ([self.playerDelegate respondsToSelector:@selector(audioPlayerStop)]) {
                            [self.playerDelegate audioPlayerStop];
                        }
                        
                    } else {
                        if ([self.playerDelegate respondsToSelector:@selector(audioPlayerFinish)]) {
                            [self.playerDelegate audioPlayerFinish];
                        }
                    }
                }
                
                [_playerLock.readLock unlock];
                
                return;
            }
            
            //NSLog(@"%@ 播放一帧 globalPts : %d duration : %d globalLength : %d", TAG, frame.globalPts, frame.duration, frame.globalLength);
            
            if (self.playerFirstFrameTime == 0) {
                _playerFirstFrameTime = [NSDate date].timeIntervalSince1970 * 1000 - _seekTime;
            }
            
            // 计算休眠时间
            int64_t currentTime = [NSDate date].timeIntervalSince1970 * 1000;
            
            while (currentTime - self.playerFirstFrameTime < frame.globalPts + frame.offset) {
                
                [_playerLock.readLock unlock];
                
                // 休眠中
                [NSThread sleepForTimeInterval:0.001];
                currentTime = [NSDate date].timeIntervalSince1970 * 1000;
                
                [_playerLock.readLock lock];
                
                if (_isPlayerStop) {
                
                    NSLog(@"%@ 停止播放", TAG);
                    
                    if (self.playerDelegate != NULL && [self.playerDelegate respondsToSelector:@selector(audioPlayerStop)]) {
                        [self.playerDelegate audioPlayerStop];
                    }
                    
                    [_playerLock.readLock unlock];
                    
                    return;
                }
            }
            
            // 使用自动释放池回收NSData的内存
            @autoreleasepool {
                if (self.playerDelegate != nil) {
                    [frame resampleUseTempo];
                    [self.playerDelegate audioPlayerOutputWithFrame:frame];
                }
                
                frame.buffer = nil;
            }
            
            [_playerLock.readLock unlock];
        }
        
    });
}

// 停止播放
- (void)stopPlay {
    
    // 关闭解码器
    [_audioDecoder stopDecoder];
    
    // 加锁
    [_playerLock.writeLock lock];
    
    _isPlayerStop = true;
    
    // 解锁
    [_playerLock.writeLock unlock];
    
    dispatch_sync(_playerQueue, ^{
    });
    
    // 清理无用数据
    [_framesQueue clear];
}

// 播放器第一帧的时间
- (int64_t)playerFirstFrameTime {
    return _playerFirstFrameTime;
}

- (void)setPlayerFirstFrameTime:(int64_t)playerFirstFrameTime {
    _playerFirstFrameTime = playerFirstFrameTime;
}

#pragma mark - MVYAudioDecoderDelegate
// 返回解码成功的帧数据
- (void)audioDecoderOutputWithFrame:(MVYAudioFrame *)audioFrame {
    [_framesQueue put:audioFrame];
}

// 解码停止
- (void)audioDecoderStop {
    if (_framesQueue != NULL) {
        MVYAudioFrame *frame = [[MVYAudioFrame alloc] init];
        frame.flag = -2;
        [_framesQueue put:frame];
    }
}

// 解码完成
- (void)audioDecoderFinish {
    if (_framesQueue != NULL) {
        MVYAudioFrame *frame = [[MVYAudioFrame alloc] init];
        frame.flag = -1;
        [_framesQueue put:frame];
    }
}

- (void)dealloc {
    [_audioDecoder destroyNativeAudioDecoder];
    
    NSLog(@"MVYAudioPlayer dealloc");
}
@end
