//
//  MVYAudioAveragePower.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MVYAudioAveragePower : NSObject

/**
 获取音频波形数据
 
 @param url 音频路径
 @param sampleCount 采样次数
 @return 波形数据
 range: 0 -> 1.0
 count: sampleCount
 */
+ (NSArray *)averagePowerWithAudioURL:(NSURL *)url sampleCount:(NSUInteger)sampleCount;

@end

