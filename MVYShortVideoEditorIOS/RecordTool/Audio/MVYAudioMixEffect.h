//
//  MVYAudioMixEffect.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/**
 音频混合效果
 */
@interface MVYAudioMixEffect : NSObject

/**
 输入的主音频文件路径
 */
@property (nonatomic, strong) NSString *inputMainPath;

/**
 主音频音量
 */
@property (nonatomic, assign) CGFloat mainVolume;

/**
 输入的副音频文件路径
 */
@property (nonatomic, strong) NSString *inputDeputyPath;

/**
 副音频开始时间
 */
@property (nonatomic, assign) CGFloat deputyStartTime;

/**
 副音频音量
 */
@property (nonatomic, assign) CGFloat deputyVolume;

/**
 输出的音频文件路径
 */
@property (nonatomic, strong) NSString *outputPath;

/**
 开始处理音频文件
 
 */
- (BOOL)process;

@end
