//
//  MVYFFmpegCMD.h
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ MVYFFmpegCMDCallback)(int ret);

@interface MVYFFmpegCMD : NSObject

+ (int)exec:(NSString *)cmd callback:(MVYFFmpegCMDCallback)callback;

// 裁剪视频
+ (NSString *)cutVideoCMDWithStartPointTime:(NSString *)startPointTime needDuration:(NSString *)needDuration inputMediaPath:(NSString *)inputMediaPath outputMediaPath:(NSString *)outputMediaPath;

// 裁剪音频
+ (NSString *)cutAudioCMDWithStartPointTime:(NSString *)startPointTime inputAudioPath:(NSString *)inputAudioPath outputAudioPath:(NSString *)outputAudioPath;

// 分离视频
+ (NSString *)separateVideoCMDWithInputMediaPath:(NSString *)inputMediaPath outputVideoPath:(NSString *)outputVideoPath;

// 分离音频
+ (NSString *)separateAudioCMDWithInputMediaPath:(NSString *)inputMediaPath outputAudioPath:(NSString *)outputAudioPath;

// 设置音量
+ (NSString *)increaseVolumeCMDWithVolume:(NSString *)volume inputAudioPath:(NSString *)inputAudioPath outputAudioPath:(NSString *)outputAudioPath;

// adjust audio speed
+ (NSString *)adjustSpeedCMDWithSpeed:(NSString *)speed inputAudioPath:(NSString *)inputAudioPath outputAudioPath:(NSString *)outputAudioPath;

// 拼接音频
+ (NSString *)concatAudioCMDWithInputAudioPath:(NSArray<NSString *> *)inputAudioPath outputAudioPath:(NSString *)outputAudioPath;

// 混合音频
+ (NSString *)mixAudioCMDWithInputMajorAudioPath:(NSString *)inputMajorAudioPath inputMinorAudioPath:(NSString *)inputMinorAudioPath outputAudioPath:(NSString *)outputAudioPath;

// export gif
+ (NSString *)exportGifCMDWithInputVideoPath:(NSString *)inputVideoPath outputGifPath:(NSString *)outputGifPath;

// 秒 -> 时分秒
+ (NSString *)getMMSSFromSS:(NSString *)totalTime;

@end
