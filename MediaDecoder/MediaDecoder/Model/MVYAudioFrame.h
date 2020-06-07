//
//  MVYAudioFrame.h
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/14.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MVYAudioFrame : NSObject

/*标记 -1 表示 eof, -2 表示主要停止*/
@property(nonatomic, assign) int flag;

/*显示时间*/
@property(nonatomic, assign) int64_t pts;

/*显示时长*/
@property(nonatomic, assign) int64_t duration;

/*视频总时长*/
@property(nonatomic, assign) int64_t length;

/*采样率*/
@property(nonatomic, assign) int sampleRate;

/*通道数*/
@property(nonatomic, assign) int channels;

/*数据*/
@property(nonatomic, strong) NSData *buffer;

/*数据大小*/
@property(nonatomic, assign) size_t bufferSize;

/*全局视频长度*/
@property(nonatomic, assign) int64_t globalLength;

/*全局pts*/
@property(nonatomic, assign) int64_t globalPts;

/*偏移时间, 控制快放慢放*/
@property(nonatomic, assign) int64_t offset;

/*重采样速率, 控制快放慢放*/
@property(nonatomic, assign) int64_t tempo;

// 进行重采样, 控制快放慢放
-(void)resampleUseTempo;

@end
