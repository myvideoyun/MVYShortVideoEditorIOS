//
//  MVYVideoDecoder.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/4/16.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYVideoDecoder.h"
#import "ffmpeg_videodecoder.h"

static NSString *TAG = @"VideoDecoder";

@implementation MVYVideoDecoder

- (instancetype)init {
    self = [super init];
    if (self) {
        
        _isDecodeStop = false;
        _decodeLock = [[MVYReadWriteLock alloc] init];
        
        _seekTime = 0;

        _decodeQueue = dispatch_queue_create("com.myvideoyun.video.decoder", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

// 创建本地解码器
- (void)createNativeVideoDecoder:(NSArray<NSString *> *)paths {
    [ffmpeg_videodecoder registerFFmpeg];
    
    _ffVideoDecoders = [[NSMutableArray alloc] initWithCapacity:paths.count];
    
    for (NSString *path in paths) {
        // 创建本地解码器
        long ffVideoDecoder = [ffmpeg_videodecoder initVideoDecoder];
        [_ffVideoDecoders addObject:@(ffVideoDecoder)];
        
        // 打开视频文件
        NSString *fileName = [[path componentsSeparatedByString:@"/"] lastObject];
        [ffmpeg_videodecoder openFile:ffVideoDecoder path:[path cStringUsingEncoding:kCFStringEncodingUTF8] fileName:[fileName cStringUsingEncoding:kCFStringEncodingUTF8]];
    }
}

// 销毁本地解码器
- (void)destroyNativeVideoDecoder {
    // 加锁
    [_decodeLock.writeLock lock];
    
    _isDecodeStop = true;
        
    for (NSNumber *ffVideoDecoder in _ffVideoDecoders) {
        if (ffVideoDecoder != 0) {
            [ffmpeg_videodecoder closeFile:[ffVideoDecoder longValue]];
            [ffmpeg_videodecoder deinitVideoDecoder:[ffVideoDecoder longValue]];
        }
    }
    [_ffVideoDecoders removeAllObjects];
    
    // 解锁
    [_decodeLock.writeLock unlock];
}

// 从指定时间开始解码
- (void)startDecodeWithSeekTime:(int64_t)seekTime handleVideoFrame:(MVYVideoFrame *(^)(MVYVideoFrame *))handleVideoFrame withSpeed:(float)speed {
    _isDecodeStop = false;
    
    _seekTime = seekTime;
    
    dispatch_async(_decodeQueue, ^{
        NSLog(@"%@ %@", TAG, @"从第一帧开始解码");
        
        // 计算每个单频的长度和总长度
        int64_t totalVideoLength = 0;
        NSMutableArray *videoLengths = [NSMutableArray arrayWithCapacity:_ffVideoDecoders.count];
        for (int i = 0; i < _ffVideoDecoders.count; i++) {
            videoLengths[i] = @([ffmpeg_videodecoder getVideoLength:[_ffVideoDecoders[i] longValue]]);
            totalVideoLength += [videoLengths[i] longValue];
            
            NSLog(@"%@ 第 %d 个解码器, 视频长度 %d", TAG, i+1, [videoLengths[i] longValue]);
        }
        
        for (int i = 0; i < _ffVideoDecoders.count; i ++) {
            
            // 加锁
            [_decodeLock.readLock lock];
            
            // 获取解码器
            long ffVideoDecoder = [_ffVideoDecoders[i] longValue];
            
            if (ffVideoDecoder == 0) {
                NSLog(@"%@ 第 %d 个解码器, 无法打开解码器", TAG, i+1);
                
                if (self.decoderDelegate != NULL) {
                    [self.decoderDelegate videoDecoderStop];
                }
                
                [_decodeLock.readLock unlock];
                return;
            }
            
            // 当前解码器 开始时间
            int64_t decoderStartTime = 0;
            for (int x = 0; x < i; x++) {
                decoderStartTime += [videoLengths[x] longValue];
            }
            
            // 当前解码器 结束时间
            int64_t decoderEndTime = 0;
            for (int x = 0; x <= i; x++) {
                decoderEndTime += [videoLengths[x] longValue];
            }
            
            // 当前解码器 seek位置
            int64_t decoderSeekTime = seekTime - decoderStartTime;
            
            if (seekTime >= decoderEndTime) { // seek的时间超过了当前解码器的时长
                
                if (i != _ffVideoDecoders.count-1) { // 当前解码器不是最后一个解码器
                    
                    NSLog(@"%@ 第 %d 个解码器, seek位置 %d, 当前解码器时长短于seek位置", TAG, i+1, decoderSeekTime);
                    
                    // 进入下一个解码器
                    [_decodeLock.readLock unlock];
                    continue;
                    
                } else {
                    
                    NSLog(@"%@ 第 %d 个解码器, seek位置 %d, seek位置超过了当前视频的总长度", TAG, i+1, decoderSeekTime);
                    
                    if (self.decoderDelegate != NULL) {
                        [self.decoderDelegate videoDecoderStop];
                    }
                    
                    [_decodeLock.readLock unlock];
                    return;
                }
                
            } else if (seekTime >= decoderStartTime) { // seek的时间在当前解码器的范围内
                
                if (seekTime - decoderStartTime == 0) {
                    
                    NSLog(@"%@ 第 %d 个解码器, seek位置 %d, 开始解码", TAG, i+1, decoderSeekTime);

                    // seek到第一帧开始解码
                    [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder frameIndex:0];
                    
                } else {
                    
                    NSLog(@"%@ 第 %d 个解码器, seek位置 %d, 开始解码", TAG, i+1, decoderSeekTime);

                    // seek到时间点之前的I帧
                    [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder millisecond:decoderSeekTime];
                }
                
                // 解码到seek时间点
                for (int x = 0; x < 100; x++) {
                    
                    if (_isDecodeStop) {
                        
                        NSLog(@"%@ 停止解码", TAG);
                        
                        if (self.decoderDelegate != NULL) {
                            [self.decoderDelegate videoDecoderStop];
                        }
                        
                        [_decodeLock.readLock unlock];
                        return;
                    }
                    
                    // 解码数据
                    NSArray<MVYVideoFrame *> *frames = [ffmpeg_videodecoder decodeAFrame:ffVideoDecoder];
                    
                    for (MVYVideoFrame *frame in frames) {
                        
                        // 设置全局 pts 和 length 数据
                        frame.globalPts = frame.pts;
                        for (int x = 0; x < i; x++) {
                            frame.globalPts += [videoLengths[x] longValue];
                        }
                        frame.globalLength = totalVideoLength;
                        
                        // 解码到seek点
                        if (frame.globalPts >= seekTime || abs(frame.globalPts - seekTime) < 15) {
                            
                            if (self.decoderDelegate != NULL) {
                                if (handleVideoFrame != NULL) {
                                    [self.decoderDelegate videoDecoderOutputWithFrame:handleVideoFrame(frame)];
                                } else {
                                    [self.decoderDelegate videoDecoderOutputWithFrame:frame];
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
                    [self.decoderDelegate videoDecoderStop];
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
                [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder frameIndex:0];
                
                // 解锁
                [_decodeLock.readLock unlock];
            }
                
            while (true) {
                // 加锁
                [_decodeLock.readLock lock];
                
                if (_isDecodeStop) {
                    
                    NSLog(@"%@ 停止解码", TAG);
                    
                    if (self.decoderDelegate != NULL) {
                        [self.decoderDelegate videoDecoderStop];
                    }
                    
                    [_decodeLock.readLock unlock];
                    return;
                }
                
                // 解码数据
                NSArray<MVYVideoFrame *> *frames = [ffmpeg_videodecoder decodeAFrame:ffVideoDecoder];
                
                for (MVYVideoFrame *frame in frames) {
                    
                    // 设置全局 pts 和 length 数据
                    frame.globalPts = frame.pts * speed;
                    for (int x = 0; x < i; x++) {
                        frame.globalPts += [videoLengths[x] longValue];
                    }
                    frame.globalLength = totalVideoLength * speed;
                    
                    if (self.decoderDelegate != NULL) {
                        if (handleVideoFrame != NULL) {
                            [self.decoderDelegate videoDecoderOutputWithFrame:handleVideoFrame(frame)];
                        } else {
                            [self.decoderDelegate videoDecoderOutputWithFrame:frame];
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
            if (i == _ffVideoDecoders.count - 1) {
                
                // 解码完成
                _isDecodeStop = true;
                
                if (self.decoderDelegate != NULL) {
                    [self.decoderDelegate videoDecoderFinish];
                }
                
                NSLog(@"%@ 第 %d 个解码器, 解码到eof, 全部解码完成", TAG, i+1);
            } else {
                
                NSLog(@"%@ 第 %d 个解码器, 解码到eof, 进入下一个解码器", TAG, i+1);
            }
            
            [_decodeLock.readLock unlock];
        }
    });
}

- (void)startDecodeWithSeekTime:(int64_t)seekTime withSpeed:(float)speed{
    [self startDecodeWithSeekTime:seekTime handleVideoFrame:nil withSpeed:speed];
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
    NSLog(@"MVYVideoDecoder dealloc");
}

@end
