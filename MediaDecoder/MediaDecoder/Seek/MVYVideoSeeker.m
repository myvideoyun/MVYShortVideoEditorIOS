//
//  MVYVideoSeeker.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/7/29.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYVideoSeeker.h"
#import "MVYVideoAccurateSeekDecoder.h"

@interface MVYVideoSeeker () {
    // 解码器
    MVYVideoAccurateSeekDecoder *_decoder;
    
    // 获取seek数据的线程
    dispatch_queue_t _seekerQueue;
    
    // seek时间
    int64_t _seekTime;
    BOOL _updateSeekTime;
}

@end

@implementation MVYVideoSeeker

- (instancetype)initWithPaths:(NSArray<NSString *> *)paths {
    
    self = [super init];
    if (self) {
        _decoder = [[MVYVideoAccurateSeekDecoder alloc] init];
        [_decoder createNativeVideoDecoder:paths];
        
        // 开始解码
        [_decoder startAccurateSeekDecode];
        
        // seek线程
        _seekerQueue = dispatch_queue_create("com.myvideoyun.video.seeker", DISPATCH_QUEUE_SERIAL);
        
        __weak typeof(self) weakSelf = self;
        dispatch_async(_seekerQueue, ^{
            while (true) {
                
                [NSThread sleepForTimeInterval:0.05];
                
                if (weakSelf == nil) {
                    return;
                }
                
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                // 开始搜索最近的一帧
                if (strongSelf->_updateSeekTime) {
                    strongSelf->_updateSeekTime = false;
                    int64_t time = strongSelf->_seekTime;
                    
                    // 循环获取最近的一帧
                    NSTimeInterval searchStartTime = [[[NSDate alloc] init] timeIntervalSince1970];
                    while (true) {
                        MVYVideoFrame *frame = [strongSelf->_decoder frameWithSeekTime:time];
                        
                        // 搜索中
                        if (frame != nil && abs(frame.globalPts - strongSelf->_seekTime) < 10) {
                            @autoreleasepool {
                                if (strongSelf.seekerDelegate != nil) {
                                    [strongSelf.seekerDelegate seekerOutputWithFrame:frame];
                                }
                            }
                            break;
                        }
                        
                        // 搜索时间超过0.5秒
                        if ([[[NSDate alloc] init] timeIntervalSince1970] - searchStartTime > 0.5) {
                            if (frame != nil) {
                                @autoreleasepool {
                                    if (strongSelf.seekerDelegate != nil) {
                                        [strongSelf.seekerDelegate seekerOutputWithFrame:frame];
                                    }
                                }
                                break;
                            }
                        }
                        
                        // 每次搜索间隔50ms
                        [NSThread sleepForTimeInterval:0.05];
                    }
                }
            }
        });
    }
    
    return self;
}

- (void)setSeekTime:(int64_t) seekTime {
    _seekTime = seekTime;
    _updateSeekTime = true;
}

- (void)dealloc {
    [_decoder stopDecoder];
    [_decoder destroyNativeVideoDecoder];
}

@end
