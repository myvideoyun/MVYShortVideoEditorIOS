//
//  MVYPlayerSync.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/7/30.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MVYAudioPlayer.h"
#import "MVYVideoPlayer.h"

// 音视频同步
@interface MVYPlayerSync : NSObject

// 同步播放器
+ (void)syncWithVideo:(id<MVYVideoPlayerSyncProtocol>)video audio:(id<MVYAudioPlayerSyncProtocol>)audio;

@end
