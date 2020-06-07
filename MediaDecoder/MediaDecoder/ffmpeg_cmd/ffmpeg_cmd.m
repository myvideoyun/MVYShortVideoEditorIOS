//
//  ffmpeg_cmd.m
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/14.
//  Copyright © 2019 myvideoyun. All rights reserved.
//
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

#import "ffmpeg_cmd.h"

#include "ffmpeg_thread.h"
#include "libavutil/log.h"

@implementation ffmpeg_cmd

static const char *TAG = "FFmpegCMD";

static char **argv = NULL;

static int argvCount = 0;

/**
 * ffmpeg-结果回调
 */
static void FFmpegCMD_callback(int ret) {

    av_log_set_callback(NULL);

    if (ffmpegCallback == NULL) {
        return;
    }

    ffmpegCallback(ret);
    
    if(argv != NULL){
        for(int i = 0; i < argvCount; ++i){
            free(argv[i]);
        }
        free(argv);
        argv = NULL;
    }

    ffmpegCallback = NULL;
}

static FFmpegCallback ffmpegCallback;

+ (void)exec:(NSArray<NSString *> *)cmdSpan callback:(FFmpegCallback)callback{
    ffmpegCallback = callback;
    
    av_log_set_level(AV_LOG_DEBUG);
    
    int i = 0;

    if (cmdSpan != NULL && cmdSpan.count > 0) {
        argvCount = cmdSpan.count;
        argv = (char **) malloc(sizeof(char *) * argvCount);
        memset(argv, 0, sizeof(char *) * argvCount);

        for (i = 0; i < argvCount; ++i) {//转换
            
            int len = sizeof(char) * cmdSpan[i].length;
            char *arg = malloc(len + 1);
            memset(arg, 0, len + 1);
            memcpy(arg, [cmdSpan[i] UTF8String], len);
            arg[len] = '\0';

            argv[i] = arg;
        }

        //新建线程 执行FFmpeg 命令
        ffmpeg_thread_run_cmd(argvCount, argv);

        //注册FFmpeg命令执行完毕时的回调
        ffmpeg_thread_callback(FFmpegCMD_callback);

    } else {

        FFmpegCMD_callback(-1);
    }
}

@end
