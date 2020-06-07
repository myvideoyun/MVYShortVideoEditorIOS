//
//  MVYFFmpegCMD.m
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYFFmpegCMD.h"
#import "ffmpeg_cmd.h"

@implementation MVYFFmpegCMD

+ (int)exec:(NSString *)cmd callback:(MVYFFmpegCMDCallback)callback_ {
    
    NSMutableArray<NSString *> *cmdData = [[NSMutableArray alloc] init];
    NSMutableString *ms = [[NSMutableString alloc] init];
    for (NSString *cmdSpan in [cmd componentsSeparatedByString:@" "]) {
        
        if ([cmdSpan hasPrefix:@"\""]) {
            [ms appendString:cmdSpan];
        } else if (ms.length > 0) {
            [ms appendString:@" "];
            [ms appendString:cmdSpan];
        } else {
            [cmdData addObject:cmdSpan];
        }
        
        if ([ms hasSuffix:@"\""]) {
            [cmdData addObject:[ms substringWithRange:NSMakeRange(1, ms.length - 2)]];
            ms = [[NSMutableString alloc] init];
        }
    }
    
    [ffmpeg_cmd exec:cmdData callback:^(int ret) {
        callback_(ret);
    }];
}

// 裁剪视频
+ (NSString *)cutVideoCMDWithStartPointTime:(NSString *)startPointTime needDuration:(NSString *)needDuration inputMediaPath:(NSString *)inputMediaPath outputMediaPath:(NSString *)outputMediaPath {
    return [NSString stringWithFormat:@"ffmpeg -threads 4 "
            "-accurate_seek "
            "-ss %@ "
            "-t %@ "
            "-err_detect ignore_err "
            "-i \"%@\" "
            "-r 30 "
            "-g 30 "
            "-b:v 20000k "
            "-vf transpose=2 "
            "-vcodec libx264 "
            "-preset ultrafast "
            "-acodec copy "
            "\"%@\"", startPointTime, needDuration, inputMediaPath, outputMediaPath];
}

// 裁剪音频
+ (NSString *)cutAudioCMDWithStartPointTime:(NSString *)startPointTime inputAudioPath:(NSString *)inputAudioPath outputAudioPath:(NSString *)outputAudioPath {
    return [NSString stringWithFormat:@"ffmpeg -threads 4 "
            "-accurate_seek "
            "-ss %@ "
            "-err_detect ignore_err "
            "-i \"%@\" "
            "-acodec pcm_s16le "
            "-ac 1 "
            "-ar 44100 "
            "\"%@\"", startPointTime, inputAudioPath, outputAudioPath];
}

// 分离视频
+ (NSString *)separateVideoCMDWithInputMediaPath:(NSString *)inputMediaPath outputVideoPath:(NSString *)outputVideoPath {
    return [NSString stringWithFormat:@"ffmpeg -threads 4 "
            "-i \"%@\" "
            "-metadata:s:v:0 rotate=270 "
            "-an "
            "-vcodec copy "
            "\"%@\"", inputMediaPath, outputVideoPath];
}

// 分离音频
+ (NSString *)separateAudioCMDWithInputMediaPath:(NSString *)inputMediaPath outputAudioPath:(NSString *)outputAudioPath {
    return [NSString stringWithFormat:@"ffmpeg -threads 4 "
            "-i \"%@\" "
            "-vn "
            "-acodec pcm_s16le "
            "-ac 1 "
            "-ar 44100 "
            "\"%@\"", inputMediaPath, outputAudioPath];
}

// 设置音量
+ (NSString *)increaseVolumeCMDWithVolume:(NSString *)volume inputAudioPath:(NSString *)inputAudioPath outputAudioPath:(NSString *)outputAudioPath {
    return [NSString stringWithFormat:@"ffmpeg -threads 4 "
            "-i \"%@\" "
            "-filter:a volume=%@ "
            "-acodec pcm_s16le "
            "-ac 1 "
            "-ar 44100 "
            "\"%@\"", inputAudioPath, volume, outputAudioPath];
}

+ (NSString *)adjustSpeedCMDWithSpeed:(NSString *)speed inputAudioPath:(NSString *)inputAudioPath outputAudioPath:(NSString *)outputAudioPath{
    return [NSString stringWithFormat:@"ffmpeg -threads 4 "
            "-i \"%@\" "
            "-filter:a \"atempo=%@\" "
            "-acodec pcm_s16le "
            "-ac 1 "
            "-ar 44100 "
            "\"%@\"", inputAudioPath, speed, outputAudioPath];
}

+ (NSString *)exportGifCMDWithInputVideoPath:(NSString *)inputVideoPath outputGifPath:(NSString *)outputGifPath{
    return [NSString stringWithFormat:@"ffmpeg -threads 4 -ss 0 -t 2 "
            "-i \"%@\" "
            "-vf \"fps=5,scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse\" "
            "\"%@\"", inputVideoPath, outputGifPath];
}

// 拼接音频
+ (NSString *)concatAudioCMDWithInputAudioPath:(NSArray<NSString *> *)inputAudioPath outputAudioPath:(NSString *)outputAudioPath {
    NSMutableString *inputMS = [[NSMutableString alloc] init];
    NSMutableString *filterMS = [[NSMutableString alloc] init];
    for (int i = 0; i < inputAudioPath.count; i++) {
        [inputMS appendString:@" -i "];
        [inputMS appendFormat:@"\"%@\"", [inputAudioPath objectAtIndex:i]];
        [filterMS appendString:@"["];
        [filterMS appendFormat:@"%d",i];
        [filterMS appendString:@":0]"];
    }

    return [NSString stringWithFormat:@"ffmpeg -threads 4"
            "%@ "
            "-filter_complex %@concat=n=%d:v=0:a=1[out] "
            "-map [out] "
            "\"%@\"", inputMS, filterMS, inputAudioPath.count, outputAudioPath];
}

// 混合音频
+ (NSString *)mixAudioCMDWithInputMajorAudioPath:(NSString *)inputMajorAudioPath inputMinorAudioPath:(NSString *)inputMinorAudioPath outputAudioPath:(NSString *)outputAudioPath {
    return [NSString stringWithFormat:@"ffmpeg -threads 4 "
            "-i \"%@\" "
            "-i \"%@\" "
            "-filter_complex amix=inputs=2:duration=first:dropout_transition=2 "
            "\"%@\"", inputMajorAudioPath, inputMinorAudioPath, outputAudioPath];
}

// 秒 -> 时分秒
+ (NSString *)getMMSSFromSS:(NSString *)totalTime {

    NSInteger seconds = [totalTime integerValue];
    
    double ms = [totalTime doubleValue] - seconds;
    
    //format of hour
    NSString *str_hour = [NSString stringWithFormat:@"%ld",seconds/3600];
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%ld",(seconds%3600)/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%ld",seconds%60];
    //format of millisecond
    NSString *str_millisecond = [NSString stringWithFormat:@"%ld",(NSInteger)(ms*1000)];
    //format of time
    NSString *format_time = [NSString stringWithFormat:@"%@:%@:%@.%@",str_hour,str_minute,str_second,str_millisecond];
    
    return format_time;
    
}

@end
