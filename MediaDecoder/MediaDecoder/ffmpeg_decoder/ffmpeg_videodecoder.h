//
//  ffmpeg_videodecoder.h
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/14.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVYVideoFrame.h"

@interface ffmpeg_videodecoder : NSObject

+ (void)registerFFmpeg;

+ (long)initVideoDecoder;

+ (void)deinitVideoDecoder:(long)instance;

+ (bool)openFile:(long)instance path:(const char *)path fileName:(const char *)fileName;

+ (NSArray<MVYVideoFrame *> *)decodeAFrame:(long)instance;

+ (void)backwardSeekTo:(long)instance frameIndex:(int)frameIndex;

+ (void)backwardSeekTo:(long)instance millisecond:(int64_t)millisecond;

+ (int64_t)getVideoLength:(long)instance;

+ (void)closeFile:(long)instance;

@end
