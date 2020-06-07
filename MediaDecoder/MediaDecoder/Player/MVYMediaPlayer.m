//
//  MVYMediaPlayer.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/8/2.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYMediaPlayer.h"
#import "MVYPlayerSync.h"

@interface MVYMediaPlayer () <MVYAudioPlayerDelegate, MVYVideoPlayerDelegate>

@property (nonatomic, strong) MVYAudioPlayer *audioPlayer;

@property (nonatomic, strong) MVYVideoPlayer *videoPlayer;

@end

@implementation MVYMediaPlayer

- (instancetype)initWithVideoPaths:(NSArray<NSString *> *)videoPaths audioPaths:(NSArray<NSString *> *)audioPaths {
    self = [super init];
    if (self) {
        _audioPlayer = [[MVYAudioPlayer alloc] initWithPaths:audioPaths];
        _videoPlayer = [[MVYVideoPlayer alloc] initWithPaths:videoPaths];
        
        self.audioPlayer.playerDelegate = self;
        self.videoPlayer.playerDelegate = self;
        
    }
    return self;
}

// 开始播放
- (void)startPlayWithSeekTime:(int64_t)seekTime {
    [self.audioPlayer startPlayWithSeekTime:seekTime];
    [self.videoPlayer startPlayWithSeekTime:seekTime];
}

- (void)startPlay {
    [self startPlayWithSeekTime:0];
}

// 开始倒放
- (void)startReversePlayWithSeekTime:(int64_t)seekTime {
    [self.audioPlayer startPlayWithSeekTime:seekTime];
    [self.videoPlayer startReversePlayWithSeekTime:seekTime];
}

- (void)startReversePlay {
    [self startReversePlayWithSeekTime:0];
}

// 开始慢放
- (void)startSlowPlayWithSeekTime:(int64_t)seekTime slowTimeRange:(NSRange)slowTimeRange {
    [self.audioPlayer startSlowPlayWithSeekTime:seekTime slowTimeRange:slowTimeRange];
    [self.videoPlayer startSlowPlayWithSeekTime:seekTime slowTimeRange:slowTimeRange];
}

- (void)startSlowPlayWithSlowTimeRange:(NSRange)slowTimeRange {
    [self startSlowPlayWithSeekTime:0 slowTimeRange:slowTimeRange];
}

// 停止播放
- (void)stopPlay {
    [self.audioPlayer stopPlay];
    [self.videoPlayer stopPlay];
}

#pragma mark - MVYAudioPlayerDelegate, MVYVideoPlayerDelegate
- (void)videoPlayerOutputWithFrame:(MVYVideoFrame *)videoFrame {
    // 同步音视频
    [MVYPlayerSync syncWithVideo:self.videoPlayer audio:self.audioPlayer];
    
    if (self.playerDelegate != nil) {
        [self.playerDelegate videoPlayerOutputWithFrame:videoFrame];
    }
}

- (void)videoPlayerStop {
    if (self.playerDelegate != nil) {
        [self.playerDelegate videoPlayerStop];
    }
}

- (void)videoPlayerFinish {
    if (self.playerDelegate != nil) {
        [self.playerDelegate videoPlayerFinish];
    }
}

- (void)audioPlayerOutputWithFrame:(MVYAudioFrame *)audioFrame {
    // 同步音视频
    [MVYPlayerSync syncWithVideo:self.videoPlayer audio:self.audioPlayer];

    if (self.playerDelegate != nil) {
        [self.playerDelegate audioPlayerOutputWithFrame:audioFrame];
    }
}

- (void)audioPlayerStop {
    if (self.playerDelegate != nil && [self.playerDelegate respondsToSelector:@selector(audioPlayerStop)]){
        [self.playerDelegate audioPlayerStop];
    }
}

- (void)audioPlayerFinish {
    if (self.playerDelegate != nil && [self.playerDelegate respondsToSelector:@selector(audioPlayerFinish)]){
        [self.playerDelegate audioPlayerFinish];
    }
}

@end
