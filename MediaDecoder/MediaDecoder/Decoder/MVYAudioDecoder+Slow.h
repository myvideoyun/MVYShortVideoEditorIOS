//
//  MVYAudioDecoder+Slow.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/8/19.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYAudioDecoder.h"

extern double MVYAudioDecoderTempo;

@interface MVYAudioDecoder (Slow)

// 从指定时间开始慢速解码
- (void)startSlowDecodeWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)slowTimeRange;

@end
