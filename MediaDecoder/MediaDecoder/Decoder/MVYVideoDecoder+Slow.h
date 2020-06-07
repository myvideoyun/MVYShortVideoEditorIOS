//
//  MVYVideoDecoder+Slow.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/8/11.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYVideoDecoder.h"

extern double MVYVideoDecoderPTSRate;

@interface MVYVideoDecoder (Slow)

// 从指定时间开始慢速解码
- (void)startSlowDecodeWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)slowTimeRange;

@end
