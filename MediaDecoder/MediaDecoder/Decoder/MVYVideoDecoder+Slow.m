//
//  MVYVideoDecoder+Slow.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/8/11.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYVideoDecoder+Slow.h"

double MVYVideoDecoderPTSRate = 2;

@implementation MVYVideoDecoder (Slow)

- (void)startSlowDecodeWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)_slowTimeRange {
    // 处理视频帧
    [self startDecodeWithSeekTime:seekTime handleVideoFrame:^MVYVideoFrame *(MVYVideoFrame *frame) {
        
        NSRange slowTimeRange = _slowTimeRange;

        if (frame.globalLength < slowTimeRange.location) {
            // 视频时长太短, 无法处理
            return frame;
        }
        
        if (NSMaxRange(slowTimeRange) > frame.globalLength) {
            // 需要处理的范围超过了视频时长
            slowTimeRange.length = frame.globalLength - slowTimeRange.location;
        }
        
        // 增加的时长
        int64_t offsetTime = 0;
        
        if (frame.globalPts < slowTimeRange.location) { // 时间小于变慢时间
            offsetTime = 0;
            
        } else if (frame.globalPts >= slowTimeRange.location && frame.globalPts <= NSMaxRange(slowTimeRange)) { // 在这个区间内
            offsetTime = (frame.globalPts - slowTimeRange.location) * (MVYVideoDecoderPTSRate - 1);
            
        } else if (frame.globalPts > NSMaxRange(slowTimeRange)) { // 时间大于变慢时间
            offsetTime = slowTimeRange.length * (MVYVideoDecoderPTSRate - 1);
        }
        
        frame.offset = offsetTime;

        return frame;
    } withSpeed:1.0f];
}

@end
