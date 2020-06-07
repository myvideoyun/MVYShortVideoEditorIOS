//
//  MVYVideoFrame.h
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/14.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MVYVideoFrame : NSObject

/*标记 -1 表示 eof, -2 表示主要停止*/
@property(nonatomic, assign) int flag;

/*视频宽*/
@property(nonatomic, assign) int width;

/*视频高*/
@property(nonatomic, assign) int height;

/*行宽*/
@property(nonatomic, assign) int lineSize;

/*旋转信息*/
@property(nonatomic, assign) int rotate;

/*显示时间*/
@property(nonatomic, assign) int64_t pts;

/*显示时长*/
@property(nonatomic, assign) int64_t duration;

/*视频总时长*/
@property(nonatomic, assign) int64_t length;

/*y数据*/
@property(nonatomic, strong) NSData *yData;

/*u数据*/
@property(nonatomic, strong) NSData *uData;

/*v数据*/
@property(nonatomic, strong) NSData *vData;

/*是否是关键帧*/
@property(nonatomic, assign) int isKeyFrame;

/*全局视频长度*/
@property(nonatomic, assign) int64_t globalLength;

/*全局pts*/
@property(nonatomic, assign) int64_t globalPts;

/*偏移时间*/
@property(nonatomic, assign) int64_t offset;

@end
