//
//  ffmpeg_cmd.h
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/14.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ FFmpegCallback)(int ret);

@interface ffmpeg_cmd : NSObject

+ (void)exec:(NSArray<NSString *> *)cmdSpan callback:(FFmpegCallback)callback;

@end
