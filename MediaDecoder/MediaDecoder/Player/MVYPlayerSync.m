//
//  MVYPlayerSync.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/7/30.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYPlayerSync.h"

@implementation MVYPlayerSync

+ (void)syncWithVideo:(id<MVYVideoPlayerSyncProtocol>)video audio:(id<MVYAudioPlayerSyncProtocol>)audio {
    // 同步时间
    NSTimeInterval startTime = [[[NSDate alloc] init] timeIntervalSince1970];
    while (true) {
        
        // 音频解码快于视频, 等待
        if (video.playerFirstFrameTime == 0) {
            [NSThread sleepForTimeInterval:0.05]; // 休眠一帧的时间
            NSLog(@"Sync 休眠一帧的时间");
            
        } else if (audio.playerFirstFrameTime == 0) { // 视频解码快于视频, 不等待
            break;
            
        } else { // 音视频正在解码中
            break;
        }
       
        if ([[[NSDate alloc] init] timeIntervalSince1970] - startTime > 0.20) {
            // 超过0.2秒还没有画面, 不再阻塞, 防止用户操作卡顿
            NSLog(@"Sync 超过0.2秒还没有画面");
            return;
        }
    }
    
    // 已经同步完成
    if (audio.playerFirstFrameTime == video.playerFirstFrameTime) {
        return;
    }
    
    // 视频播放时间不变, 修改音频播放时间
    audio.playerFirstFrameTime = video.playerFirstFrameTime;
}

@end
