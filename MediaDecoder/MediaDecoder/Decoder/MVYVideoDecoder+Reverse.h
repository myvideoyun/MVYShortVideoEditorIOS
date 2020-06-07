//
//  MVYVideoDecoder+Reverse.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/7/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYVideoDecoder.h"

@interface MVYVideoDecoder (Reverse)

// 从最后一帧开始解码
- (void)startReverseDecodeWithSeekTime:(int64_t)seekTime;

@end
