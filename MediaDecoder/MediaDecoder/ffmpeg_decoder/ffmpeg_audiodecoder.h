//
//  ffmpeg_audiodecoder.h
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/14.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVYAudioFrame.h"

@interface ffmpeg_audiodecoder : NSObject

+ (void)registerFFmpeg;

+ (long)initAudioDecoder;

+ (void)deinitAudioDecoder:(long) instance;

+ (bool)openFile:(long)instance path:(const char *)path fileName:(const char *)fileName;

+ (NSArray<MVYAudioFrame *> *)decodeAFrame:(long)instance;

+ (void)backwardSeekTo:(long)instance frameIndex:(int)frameIndex;

+ (void)backwardSeekTo:(long)instance millisecond:(int64_t)millisecond;

+ (int64_t)getAudioLength:(long)instance;

+ (void)closeFile:(long)instance;

@end
