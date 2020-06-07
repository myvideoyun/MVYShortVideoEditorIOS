//
//  MVYAudioDecoder.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/4/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYAudioDecoder.h"
#import "ffmpeg_audiodecoder.h"

static NSString *TAG = @"AudioDecoder";

@implementation MVYAudioDecoder

- (instancetype)init {
    self = [super init];
    if (self) {
        
        _isDecodeStop = false;
        _decodeLock = [[MVYReadWriteLock alloc] init];
        
        _seekTime = 0;

        _decodeQueue = dispatch_queue_create("com.myvideoyun.audio.decoder", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// 创建本地解码器
- (void)createNativeAudioDecoder:(NSArray<NSString *> *)paths {
    [ffmpeg_audiodecoder registerFFmpeg];
    
    _ffAudioDecoders = [[NSMutableArray alloc] initWithCapacity:paths.count];
    
    for (NSString *path in paths) {
        // 创建本地解码器
        long ffAudioDecoder = [ffmpeg_audiodecoder initAudioDecoder];
        [_ffAudioDecoders addObject:@(ffAudioDecoder)];
        
        // 打开音频文件
        NSString *fileName = [path lastPathComponent];
        [ffmpeg_audiodecoder openFile:ffAudioDecoder path:[path cStringUsingEncoding:kCFStringEncodingUTF8] fileName:[fileName cStringUsingEncoding:kCFStringEncodingUTF8]];
    }
}

// 销毁本地解码器
- (void)destroyNativeAudioDecoder {
    // 加锁
    [_decodeLock.writeLock lock];
    
    _isDecodeStop = true;
        
    for (NSNumber *ffAudioDecoder in _ffAudioDecoders) {
        if (ffAudioDecoder != 0) {
            [ffmpeg_audiodecoder closeFile:[ffAudioDecoder longValue]];
            [ffmpeg_audiodecoder deinitAudioDecoder:[ffAudioDecoder longValue]];
        }
    }
    [_ffAudioDecoders removeAllObjects];
    
    // 解锁
    [_decodeLock.writeLock unlock];
}

// 从指定时间开始解码
- (void)startDecodeWithSeekTime:(int64_t)seekTime handleAudioFrame:(MVYAudioFrame *(^)(MVYAudioFrame *))handleAudioFrame {
    _isDecodeStop = false;
    
    _seekTime = seekTime;
    
    dispatch_async(_decodeQueue, ^{
        NSLog(@"%@ %@", TAG, @"从第一帧开始解码");
        
        // 计算每个单频的长度和总长度
        int64_t totalAudioLength = 0;
        NSMutableArray *audioLengths = [NSMutableArray arrayWithCapacity:_ffAudioDecoders.count];
        for (int i = 0; i < _ffAudioDecoders.count; i++) {
            audioLengths[i] = @([ffmpeg_audiodecoder getAudioLength:[_ffAudioDecoders[i] longValue]]);
            totalAudioLength += [audioLengths[i] longValue];
            
            NSLog(@"%@ 第 %d 个解码器, 音频长度 %d", TAG, i+1, [audioLengths[i] longValue]);
        }
        
        for (int i = 0; i < _ffAudioDecoders.count; i ++) {
            
            // 加锁
            [_decodeLock.readLock lock];
            
            // 获取解码器
            long ffAudioDecoder = [_ffAudioDecoders[i] longValue];
            
            if (ffAudioDecoder == 0) {
                NSLog(@"%@ 第 %d 个解码器, 无法打开解码器", TAG, i+1);
                
                if (self.decoderDelegate != NULL) {
                    [self.decoderDelegate audioDecoderStop];
                }
                
                [_decodeLock.readLock unlock];
                return;
            }
            
            // 当前解码器 开始时间
            int64_t decoderStartTime = 0;
            for (int x = 0; x < i; x++) {
                decoderStartTime += [audioLengths[x] longValue];
            }
            
            // 当前解码器 结束时间
            int64_t decoderEndTime = 0;
            for (int x = 0; x <= i; x++) {
                decoderEndTime += [audioLengths[x] longValue];
            }
            
            // 当前解码器 seek位置
            int64_t decoderSeekTime = seekTime - decoderStartTime;
            
            if (seekTime >= decoderEndTime) { // seek的时间超过了当前解码器的时长
                
                if (i != _ffAudioDecoders.count-1) { // 当前解码器不是最后一个解码器
                    
                    NSLog(@"%@ 第 %d 个解码器, seek位置 %d, 当前解码器时长短于seek位置", TAG, i+1, decoderSeekTime);
                    
                    // 进入下一个解码器
                    [_decodeLock.readLock unlock];
                    continue;
                    
                } else {
                    
                    NSLog(@"%@ 第 %d 个解码器, seek位置 %d, seek位置超过了当前音频的总长度", TAG, i+1, decoderSeekTime);
                    
                    if (self.decoderDelegate != NULL) {
                        [self.decoderDelegate audioDecoderStop];
                    }
                    
                    [_decodeLock.readLock unlock];
                    return;
                }
                
            } else if (seekTime >= decoderStartTime) { // seek的时间在当前解码器的范围内
                
                if (seekTime - decoderStartTime == 0) {
                    
                    NSLog(@"%@ 第 %d 个解码器, seek位置 %d, 开始解码", TAG, i+1, decoderSeekTime);
                    
                    // seek到第一帧开始解码
                    [ffmpeg_audiodecoder backwardSeekTo:ffAudioDecoder frameIndex:0];
                    
                } else {
                    
                    NSLog(@"%@ 第 %d 个解码器, seek位置 %d, 开始解码", TAG, i+1, decoderSeekTime);
                    
                    // seek到时间点之前的I帧
                    [ffmpeg_audiodecoder backwardSeekTo:ffAudioDecoder millisecond:decoderSeekTime];
                }
                
                // 解码到seek时间点
                for (int x = 0; x < 100; x++) {
                    
                    if (_isDecodeStop) {
                        
                        NSLog(@"%@ 停止解码", TAG);
                        
                        if (self.decoderDelegate != NULL) {
                            [self.decoderDelegate audioDecoderStop];
                        }
                        
                        [_decodeLock.readLock unlock];
                        return;
                    }
                    
                    // 解码数据
                    NSArray<MVYAudioFrame *> *frames = [ffmpeg_audiodecoder decodeAFrame:ffAudioDecoder];
                    
                    for (MVYAudioFrame *frame in frames) {
                        
                        // 设置全局 pts 和 length 数据
                        frame.globalPts = frame.pts;
                        for (int x = 0; x < i; x++) {
                            frame.globalPts += [audioLengths[x] longValue];
                        }
                        frame.globalLength = totalAudioLength;
                        
                        // 解码到seek点
                        if (frame.globalPts >= seekTime || abs(frame.globalPts - seekTime) < 15) {
                            
                            if (self.decoderDelegate != NULL) {
                                if (handleAudioFrame != NULL) {
                                    [self.decoderDelegate audioDecoderOutputWithFrame:handleAudioFrame(frame)];
                                } else {
                                    [self.decoderDelegate audioDecoderOutputWithFrame:frame];
                                }
                            }
                            
                            goto seekFinish;
                        }
                    }
                    
                    [NSThread sleepForTimeInterval:0.001];
                }
                
                // 连续解码100帧还没有解码到seek的真正位置, 判定为seek失败
                NSLog(@"%@ 第 %d 个解码器, seek位置 %d, seek处理发生错误", TAG, i+1, decoderSeekTime);
                
                if (self.decoderDelegate != NULL) {
                    [self.decoderDelegate audioDecoderStop];
                }
                
                [_decodeLock.readLock unlock];
                return;
                
            seekFinish:
                NSLog(@"%@ 第 %d 个解码器, seek位置 %d, seek处理完成", TAG, i+1, decoderSeekTime);
                
                // 解锁
                [_decodeLock.readLock unlock];
                
            } else { // seek时间点在上一个解码器
                
                NSLog(@"%@ 第 %d 个解码器, 无需处理seek", TAG, i+1);
                
                // seek到第一帧开始解码
                [ffmpeg_audiodecoder backwardSeekTo:ffAudioDecoder frameIndex:0];
                
                // 解锁
                [_decodeLock.readLock unlock];
            }
            
            while (true) {
                // 加锁
                [_decodeLock.readLock lock];
                
                if (_isDecodeStop) {
                    
                    NSLog(@"%@ 停止解码", TAG);
                    
                    if (self.decoderDelegate != NULL) {
                        [self.decoderDelegate audioDecoderStop];
                    }
                    
                    [_decodeLock.readLock unlock];
                    return;
                }
                
                // 解码数据
                NSArray<MVYAudioFrame *> *frames = [ffmpeg_audiodecoder decodeAFrame:ffAudioDecoder];
                
                for (MVYAudioFrame *frame in frames) {
                    
                    // 设置全局 pts 和 length 数据
                    frame.globalPts = frame.pts;
                    for (int x = 0; x < i; x++) {
                        frame.globalPts += [audioLengths[x] longValue];
                    }
                    frame.globalLength = totalAudioLength;
                    
                    if (self.decoderDelegate != NULL) {
                        if (handleAudioFrame != NULL) {
                            [self.decoderDelegate audioDecoderOutputWithFrame:handleAudioFrame(frame)];
                        } else {
                            [self.decoderDelegate audioDecoderOutputWithFrame:frame];
                        }
                    }
                    
                    // 是否到结尾
                    if (abs(frame.pts + frame.duration - frame.length) < 15 || frame.pts + frame.duration > frame.length) {
                        
                        // 解码到EOF
                        goto decoderFinish;
                    }
                }
                
                // 解锁
                [_decodeLock.readLock unlock];
                
                [NSThread sleepForTimeInterval:0.001];
            }
            
        decoderFinish:
            if (i == _ffAudioDecoders.count - 1) {
                
                // 解码完成
                _isDecodeStop = true;
                
                if (self.decoderDelegate != NULL) {
                    [self.decoderDelegate audioDecoderFinish];
                }
                
                NSLog(@"%@ 第 %d 个解码器, 解码到eof, 全部解码完成", TAG, i+1);
            } else {
                
                NSLog(@"%@ 第 %d 个解码器, 解码到eof, 进入下一个解码器", TAG, i+1);
            }
            
            [_decodeLock.readLock unlock];
        }
    });
}

- (void)startDecodeWithSeekTime:(int64_t)seekTime {
    [self startDecodeWithSeekTime:seekTime handleAudioFrame:nil];
}

// 停止解码器
- (void)stopDecoder {
    
    // 加锁
    [_decodeLock.writeLock lock];
    
    _isDecodeStop = true;
    
    // 解锁
    [_decodeLock.writeLock unlock];
    
    // 等待Stop完成
    dispatch_sync(_decodeQueue, ^{
    });
}

- (void)dealloc {
    NSLog(@"MVYAudioDecoder dealloc");
}

@end
