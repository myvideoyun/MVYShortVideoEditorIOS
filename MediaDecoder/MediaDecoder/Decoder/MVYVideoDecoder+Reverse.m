//
//  MVYVideoDecoder+Reverse.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/7/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYVideoDecoder+Reverse.h"
#import "ffmpeg_videodecoder.h"

static NSString *TAG = @"VideoReverseDecoder";

@implementation MVYVideoDecoder (Reverse)

// 从最后一帧开始解码
- (void)startReverseDecodeWithSeekTime:(int64_t)seekTime {
    _isDecodeStop = false;
    
    _seekTime = seekTime;

    dispatch_async(_decodeQueue, ^{
        NSLog(@"%@ %@", TAG, @"从最后一帧开始解码");

        // 计算每个视频的长度和总长度
        int64_t totalVideoLength = 0;
        NSMutableArray *videoLengths = [NSMutableArray arrayWithCapacity:_ffVideoDecoders.count];
        for (int i = 0; i < _ffVideoDecoders.count; i++) {
            videoLengths[i] = @([ffmpeg_videodecoder getVideoLength:[_ffVideoDecoders[i] longValue]]);
            totalVideoLength += [videoLengths[i] longValue];

            NSLog(@"%@ 第 %d 个解码器, 视频长度 %d", TAG, i+1, [videoLengths[i] longValue]);
        }

        float iFrameInterval = 100;

        for (int i = _ffVideoDecoders.count - 1; i >= 0; i--) {

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

            // 当前视频帧是否是seek点
            bool isSeekFrame = false;

            // 当前I帧时间
            int64_t currentIFramePTS = 0;

            // 下一个I帧时间
            int64_t nextIFramePTS = 0;

            NSMutableArray<MVYVideoFrame *> *gopFrames = [[NSMutableArray alloc] init];

            // 当前解码器 开始时间
            double decoderStartTime = 0;
            for (int x = 0; x < i; x++) {
                decoderStartTime += [videoLengths[x] longValue];
            }

            // 当前解码器 结束时间
            double decoderEndTime = 0;
            for (int x = 0; x <= i; x++) {
                decoderEndTime += [videoLengths[x] longValue];
            }

            // 解锁
            [_decodeLock.readLock unlock];

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

                // 处理当前解码器的开始位置
                if (currentIFramePTS == 0 && nextIFramePTS == 0) { // 初始位置

                    if (decoderStartTime >= totalVideoLength - seekTime) { // 当前解码器不需要解码
                        NSLog(@"%@ 第 %d 个解码器, 当前解码器不需要解码", TAG, i+1);

                        // 解锁
                        [_decodeLock.readLock unlock];
                        break;

                    } else if (decoderEndTime <= totalVideoLength - seekTime) { // 当前解码器需要解码, 不需要Seek
                        NSLog(@"%@ 第 %d 个解码器, 当前解码器需要解码, 不需要Seek", TAG, i+1);

                        // 正常从结尾的I帧开始解码
                        [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder millisecond:[videoLengths[i] longValue]];

                    } else { // 在seek范围内, 当前解码器需要解码, 需要Seek
                        NSLog(@"%@ 第 %d 个解码器, 当前解码器需要解码, 需要Seek", TAG, i+1);

                        // 处理seek
                        int64_t time = totalVideoLength - seekTime - decoderStartTime;
                        [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder millisecond:time];
                    }

                    isSeekFrame = true;
                }

                // 视频解码
                NSArray<MVYVideoFrame *> *frames = [ffmpeg_videodecoder decodeAFrame:ffVideoDecoder];

                if (frames.count == 0) {
                    iFrameInterval += 100;
                }

                for (MVYVideoFrame *frame in frames) {

                    if (isSeekFrame) { // seek帧需要设置解码视频段信息
                        isSeekFrame = false;

                        if (nextIFramePTS == 0 && currentIFramePTS == 0) { // 初始解码的情况
                            nextIFramePTS = totalVideoLength - seekTime - decoderStartTime;
                            if (nextIFramePTS > [videoLengths[i] longValue]) {
                                nextIFramePTS = [videoLengths[i] longValue];
                            }
                            currentIFramePTS = frame.pts;

                        }else if (frame.pts == currentIFramePTS) { // seek距离太近, 回到了原点
                            NSLog(@"%@ 第 %d 个解码器, seek距离太近, 回到了原点",TAG, i+1);

                            iFrameInterval *= 2; // 增加每次Seek的距离
                            int64_t time = currentIFramePTS - iFrameInterval;
                            if (time > 0) {
                                [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder millisecond:time];
                            } else {
                                [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder frameIndex:0];
                            }
                            isSeekFrame = true;
                            break;

                        } else { // 正常seek
                            nextIFramePTS = currentIFramePTS;
                            currentIFramePTS = frame.pts;
                        }

                        NSLog(@"%@ 第 %d 个解码器, 下一个I帧位置 : %d 当前I帧位置 : %d", TAG, i+1, nextIFramePTS, currentIFramePTS);
                    }

                    [gopFrames addObject:frame];

                    // 解码到视频段的最后一帧, nextIFramePTS有时是Seek的位置, 不是一个准确的pts, 误差在一帧
                    if (frame.pts + frame.duration > nextIFramePTS || abs(frame.pts + frame.duration - nextIFramePTS) < 10) {
                        NSLog(@"%@  第 %d 个解码器, 解码到视频段的最后一帧", TAG, i+1);

                        // 解锁
                        [_decodeLock.readLock unlock];

                        // 倒序排列视频帧, 并添加到视频帧队列
                        for (int x = gopFrames.count - 1; x >= 0; --x) {
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

                            MVYVideoFrame *frame = [gopFrames objectAtIndex:x];
                            // 设置全局 pts 和 length 数据
                            frame.globalPts = frame.pts;
                            for (int y = 0; y < i; y++) {
                                frame.globalPts += [videoLengths[y] doubleValue];
                            }
                            frame.globalLength = totalVideoLength;
                            frame.globalPts = frame.globalLength - frame.globalPts - frame.duration;

                            if (self.decoderDelegate != NULL) {
                                [self.decoderDelegate videoDecoderOutputWithFrame:frame];
                            }

                            // 解锁
                            [_decodeLock.readLock unlock];

                            [NSThread sleepForTimeInterval:0.001];
                        }

                        // 加锁
                        [_decodeLock.readLock lock];

                        // 重置视频段内容
                        gopFrames = [[NSMutableArray alloc] init];

                        // 判断是否解码完成
                        if (currentIFramePTS > 10) { // 解码下一个视频段
                            int64_t time = currentIFramePTS - iFrameInterval;

                            NSLog(@"%@  第 %d 个解码器, seekTo %d", TAG, i+1, time);

                            if (time > 0) {
                                [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder millisecond:time];
                            } else {
                                [ffmpeg_videodecoder backwardSeekTo:ffVideoDecoder frameIndex:0];
                            }

                            isSeekFrame = true;
                            break;
                        } else {
                            // 解码完成
                            goto decoderFinish;
                        }
                    }
                }

                // 解锁
                [_decodeLock.readLock unlock];

                [NSThread sleepForTimeInterval:0.001];
            }

        decoderFinish:
            if (i == 0) {
                
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

@end
