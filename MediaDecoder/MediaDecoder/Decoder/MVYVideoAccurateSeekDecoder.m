//
//  MVYVideoAccurateSeekDecoder.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/4/29.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYVideoAccurateSeekDecoder.h"
#import "MVYVideoDecoder.h"
#import "MVYBlockingQueue.h"
#import "MVYReadWriteLock.h"
#import "ffmpeg_videodecoder.h"

static NSString *TAG = @"SeekDecoder";

@interface MVYVideoAccurateSeekDecoder () {
    
    // 解码器
    NSMutableArray<NSNumber *> *_ffVideoDecoders;
    
    // 解码锁
    bool _isDecodeStop;
    MVYReadWriteLock *_decodeLock;
    
    // 解码线程
    dispatch_queue_t _decodeQueue;
    
    // 帧缓存数组
    NSMutableArray<MVYVideoFrame *> *_framesQueue;
    int _maxSizeOfFrameQueue; // 最多缓存60帧
    
    // 数据读写锁
    MVYReadWriteLock *_dataLock;
    
    // 帧预览seek位置
    int64_t _seekTime;
}

@end

@implementation MVYVideoAccurateSeekDecoder

- (instancetype)init {
    self = [super init];
    if (self) {

        _isDecodeStop = false;
        _decodeLock = [[MVYReadWriteLock alloc] init];
        
        // 帧缓存数组
        _framesQueue = [[NSMutableArray alloc] initWithCapacity:60];
        _maxSizeOfFrameQueue = 60;
        _dataLock = [[MVYReadWriteLock alloc] init];
        
        _seekTime = 0;
        
        _decodeQueue = dispatch_queue_create("com.myvideoyun.seek.decoder", DISPATCH_QUEUE_SERIAL);
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

// 开始精准Seek解码
- (void)startAccurateSeekDecode {
    _isDecodeStop = false;
    
    dispatch_async(_decodeQueue, ^{
        
        // 计算每个单频的长度和总长度
        int64_t totalVideoLength = 0;
        NSMutableArray *videoLengths = [NSMutableArray arrayWithCapacity:_ffVideoDecoders.count];
        for (int i = 0; i < _ffVideoDecoders.count; i++) {
            videoLengths[i] = @([ffmpeg_videodecoder getVideoLength:[_ffVideoDecoders[i] longValue]]);
            totalVideoLength += [videoLengths[i] longValue];
            
            NSLog(@"%@ 第 %d 个解码器, 视频长度 %d", TAG, i+1, [videoLengths[i] longValue]);
        }
        
        while (true) {
            
            int64_t seekTime = _seekTime;
            
            // 加锁
            [_decodeLock.readLock lock];
            
            if (_isDecodeStop) {
                
                NSLog(@"%@ 停止解码", TAG);
                
                if (self.decoderDelegate != NULL) {
                    [self.decoderDelegate videoAccurateSeekStop];
                }
                
                [_decodeLock.readLock unlock];
                return;
            }
            
            // 是否有缓存数据
            BOOL hasCache = false;

            [_dataLock.readLock lock];
            for (MVYVideoFrame *frame in _framesQueue) {
                if (seekTime + 10 > frame.globalPts && seekTime - 10 < frame.globalPts + frame.duration) {
                    hasCache = true;
                }
            }
            [_dataLock.readLock unlock];
            
            if (hasCache) {
                [_decodeLock.readLock unlock];
                [NSThread sleepForTimeInterval:0.005];
                continue;
            }
            
            // 获取解码器
            int decoderIndex = -1;
            long frontVideoLength = 0;
            for (int i = 0; i < _ffVideoDecoders.count; i ++) {
                if (seekTime - frontVideoLength < [videoLengths[i] longValue]) {
                    decoderIndex = i;
                    break;
                    
                } else {
                    if (i == _ffVideoDecoders.count - 1) { // 最后一个解码器
                        decoderIndex = i;
                        seekTime = frontVideoLength + [videoLengths[i] longValue];
                        
                    } else {
                        frontVideoLength += [ffmpeg_videodecoder getVideoLength:[_ffVideoDecoders[i] longValue]];
                    }
                }
            }
            
            long ffVideoDecoder = [_ffVideoDecoders[decoderIndex] longValue];
            
            // Seek处理
            if (ffVideoDecoder != 0) {
                
                int64_t time = seekTime - frontVideoLength;
                
                if (abs(time) < 10) {
                    [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder frameIndex:0];
                    NSLog(@"%@ 第 %d 个解码器, seekTo 视频起点", TAG, decoderIndex+1);

                } else {
                    [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder millisecond:time];
                    NSLog(@"%@ 第 %d 个解码器, seekTo %d", TAG, decoderIndex+1, time);
                }
                
            } else {
                NSLog(@"%@ 第 %d 个解码器, 无法打开解码器", TAG, decoderIndex+1);
                
                if (self.decoderDelegate != NULL) {
                    [self.decoderDelegate videoAccurateSeekStop];
                }
                
                [_decodeLock.readLock unlock];
                return;
            }
            
            // 解锁
            [_decodeLock.readLock unlock];
            
            // 设置解码器 开始时间 结束时间
            int64_t decoderStartTime = 0;
            int64_t decoderEndTime = 0;
            
            while (true) {
                
                // 加锁
                [_decodeLock.readLock lock];
                
                if (_isDecodeStop) {
                    
                    NSLog(@"%@ 停止解码", TAG);
                    
                    if (self.decoderDelegate != NULL) {
                        [self.decoderDelegate videoAccurateSeekStop];
                    }
                    
                    [_decodeLock.readLock unlock];
                    return;
                }
                
                // 解码数据
                NSArray<MVYVideoFrame *> *frames = [ffmpeg_videodecoder decodeAFrame:ffVideoDecoder];
            
                for (MVYVideoFrame *frame in frames) {
                    
                    // 设置全局 pts 和 length 数据
                    frame.globalPts = frame.pts;
                    for (int x = 0; x < _ffVideoDecoders.count; x++) {
                        if (ffVideoDecoder != [_ffVideoDecoders[x] longValue]) {
                            frame.globalPts += [videoLengths[x] longValue];
                        } else {
                            break;
                        }
                    }
                    frame.globalLength = totalVideoLength;
                    
                    // 设置解码器 开始时间 结束时间
                    if (decoderStartTime == 0 && decoderEndTime == 0) {
                        decoderStartTime = frame.globalPts;
                        
                        decoderEndTime = decoderStartTime + 2 * 1000;
                        
                        // 解码结束时间不能超过解码器总时长
                        if (frame.pts + 2 * 1000 > frame.length) {
                            decoderEndTime = decoderStartTime + (frame.length - frame.pts);
                        }
                        
                        NSLog(@"%@ 第 %d 个解码器, 解码开始时间 %d 解码结束时间 %d", TAG, decoderIndex+1, (decoderStartTime - frontVideoLength), (decoderEndTime - frontVideoLength));

                    }
                    
                    // 添加到帧预览缓存数组
                    [_dataLock.writeLock lock];
                    
                    // 使用自动释放池回收NSData的内存
                    @autoreleasepool {
                        while (_framesQueue.count > _maxSizeOfFrameQueue) {
                            MVYVideoFrame *tempFrame = _framesQueue.firstObject;
                            [_framesQueue removeObject:tempFrame];
                            
                            tempFrame.yData = nil;
                            tempFrame.uData = nil;
                            tempFrame.vData = nil;
                        }
                    }
                    
                    [_framesQueue addObject:frame];
                    [_dataLock.writeLock unlock];
                    
                    // 更新seekTime
                    seekTime = _seekTime;
                    if (seekTime > frame.globalLength) {
                        seekTime = frame.globalLength;
                    }
                    
                    // 当前解码范围是否需要更新
                    if (seekTime < decoderStartTime || seekTime > decoderEndTime) {
                        [_decodeLock.readLock unlock];
                        
                        goto continueSeek;
                    }
                    
                    // 解码任务是否完成
                    if (abs(frame.globalPts + frame.duration - decoderEndTime) < 10) {
                        [_decodeLock.readLock unlock];
                        
                        goto decoderFinish;
                    }
                }
                
                // 解锁
                [_decodeLock.readLock unlock];
                [NSThread sleepForTimeInterval:0.001];
            }
            
        continueSeek:
            NSLog(@"%@ %@", TAG, @"seek位置超出当前解码范围");
            continue;
            
        decoderFinish:
            NSLog(@"%@ %@", TAG, @"解码任务完成");
            continue;
        }
    });
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

// 设置跳转的时间
- (MVYVideoFrame *)frameWithSeekTime:(int64_t) seekTime {
    
    self->_seekTime = seekTime;

    // 加锁
    [_dataLock.readLock lock];
    
    MVYVideoFrame *resultFrame = NULL;
    int64_t resultTimeInterval = 0;

    for (MVYVideoFrame *frame in _framesQueue) {
        if (resultFrame == NULL) {
            resultFrame = frame;
            resultTimeInterval = abs(seekTime - frame.globalPts);
        } else {
            int64_t timeInterval = abs(seekTime - frame.globalPts);
            if (timeInterval < resultTimeInterval) {
                resultFrame = frame;
                resultTimeInterval = timeInterval;
            }
        }
    }
    
    // 解锁
    [_dataLock.readLock unlock];
    
    return resultFrame;
}

@end
