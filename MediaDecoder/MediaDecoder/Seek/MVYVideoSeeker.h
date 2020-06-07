//
//  MVYVideoSeeker.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/7/29.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MVYVideoSeeker;
@class MVYVideoFrame;

/**
 * Seek监听
 */
@protocol MVYVideoSeekerDelegate <NSObject>
@required
/**
 * 返回需要渲染的帧数据
 */
- (void)seekerOutputWithFrame:(MVYVideoFrame *)videoFrame;

@end

@interface MVYVideoSeeker : NSObject

// 回调协议
@property (nonatomic, weak) id<MVYVideoSeekerDelegate> seekerDelegate;

// 初始化
- (instancetype)initWithPaths:(NSArray<NSString *> *)paths;

- (void)setSeekTime:(int64_t)seekTime;
@end
