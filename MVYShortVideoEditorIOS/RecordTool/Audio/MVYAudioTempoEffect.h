//
//  MVYAudioTempoEffect.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/**
 音频速度效果
 */
@interface MVYAudioTempoEffect : NSObject

/**
 输入的音频文件路径
 */
@property (nonatomic, strong) NSString *inputPath;

/**
 输出的音频文件路径
 */
@property (nonatomic, strong) NSString *outputPath;

/**
 节奏
 Range: 0.25 -> 4.0
 Default: 1.0
 */
@property (nonatomic, assign) CGFloat tempo;

/**
 开始处理音频文件

 */
- (BOOL)process;

@end
