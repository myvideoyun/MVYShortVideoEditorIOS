//
//  MVYAudioTracker.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/13.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYAudioTracker.h"
#import <AudioToolbox/AudioToolbox.h>

static const int QUEUE_BUFFER_SIZE = 4;   //队列缓冲个数
static const int AUDIO_BUFFER_SIZE = 640; //数据区大小

static void sAudioQueueOutputCallback (void * inUserData,
                                       AudioQueueRef inAQ,
                                       AudioQueueBufferRef inBuffer);

@interface MVYAudioTracker () {
    
    // 缓冲队列
    AudioStreamBasicDescription asbd;
    AudioQueueBufferRef mAudioBufferRef[QUEUE_BUFFER_SIZE];

    // 播放器
    AudioQueueRef mAudioPlayer;

    // 锁
    NSLock *mPCMDataLock;

    void *mPCMData;
    int mMaxDataLen;
    int mDataLen;
    
}

-(void)handlerOutputAudioQueue:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer;

@end

static void sAudioQueueOutputCallback (void *                  inUserData,
                                       AudioQueueRef           inAQ,
                                       AudioQueueBufferRef     inBuffer) {
    MVYAudioTracker *player = (__bridge MVYAudioTracker *)(inUserData);
    [player handlerOutputAudioQueue:inAQ inBuffer:inBuffer];
}


@implementation MVYAudioTracker

- (instancetype)initWithSampleRate:(Float64)sampleRate;
{
    self = [super init];
    if (self) {
        _volume = 1;
        
        memset(&asbd, 0, sizeof(asbd));
        asbd.mSampleRate = sampleRate;
        asbd.mFormatID = kAudioFormatLinearPCM;
        asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        asbd.mBytesPerPacket = 2;
        asbd.mFramesPerPacket = 1;
        asbd.mBytesPerFrame = 2;
        asbd.mChannelsPerFrame = 1;
        asbd.mBitsPerChannel = 16;
        asbd.mReserved = 0;
        
    }
    return self;
}

- (void)play {
    // 锁
    mPCMDataLock = [[NSLock alloc]init];
    
    // 1 秒的音频数据大小
    mMaxDataLen = asbd.mSampleRate * asbd.mBytesPerFrame * asbd.mChannelsPerFrame;
    mPCMData = malloc(mMaxDataLen);

    AudioQueueNewOutput(&asbd, sAudioQueueOutputCallback, (__bridge void *)(self), nil, nil, 0, &mAudioPlayer);
    
    for(int i=0;i<QUEUE_BUFFER_SIZE;i++) {
        AudioQueueAllocateBuffer(mAudioPlayer, AUDIO_BUFFER_SIZE, &mAudioBufferRef[i]);
        memset(mAudioBufferRef[i]->mAudioData, 0, AUDIO_BUFFER_SIZE);
        mAudioBufferRef[i]->mAudioDataByteSize = AUDIO_BUFFER_SIZE;
        AudioQueueEnqueueBuffer(mAudioPlayer, mAudioBufferRef[i], 0, NULL);
    }
    
    AudioQueueSetParameter(mAudioPlayer, kAudioQueueParam_Volume, self.volume);
    
    AudioQueueStart(mAudioPlayer, NULL);
}

- (void)write:(NSData *)data {
    [mPCMDataLock lock];
    if (mPCMData) {
        int len = (int)[data length];
        if (len > 0 && mDataLen + len < mMaxDataLen) {
            memcpy(mPCMData + mDataLen, [data bytes], len);
            mDataLen += len;
        }
    }
    [mPCMDataLock unlock];
}

- (void)stop {
    AudioQueueStop(mAudioPlayer, YES);
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        AudioQueueFreeBuffer(mAudioPlayer, mAudioBufferRef[i]);
    }
    AudioQueueDispose(mAudioPlayer, YES);
    
    [mPCMDataLock lock];
    
    free(mPCMData);
    mPCMData = nil;

    [mPCMDataLock unlock];

    mAudioPlayer = nil;

}

- (void)setVolume:(CGFloat)volume {
    _volume = volume;
    
    if (mAudioPlayer) {
        AudioQueueSetParameter(mAudioPlayer, kAudioQueueParam_Volume, volume);
    }
}

-(void)handlerOutputAudioQueue:(AudioQueueRef)inAQ inBuffer:(AudioQueueBufferRef)inBuffer {

    memset(inBuffer->mAudioData, 0, AUDIO_BUFFER_SIZE);

    if( mDataLen >=  AUDIO_BUFFER_SIZE) {

        [mPCMDataLock lock];

        if (mPCMData) {
            memcpy(inBuffer->mAudioData, mPCMData, AUDIO_BUFFER_SIZE);
            mDataLen -= AUDIO_BUFFER_SIZE;
            memmove(mPCMData, mPCMData + AUDIO_BUFFER_SIZE, mDataLen);
        }
        
        [mPCMDataLock unlock];
    }
    
    inBuffer->mAudioDataByteSize = AUDIO_BUFFER_SIZE;
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
}

@end
