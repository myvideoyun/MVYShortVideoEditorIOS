//
//  MVYAudioTempoEffect.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYAudioTempoEffect.h"
#import <AVFoundation/AVFoundation.h>

static const AVAudioFrameCount kFrameCount = 256;

@interface MVYAudioTempoEffect () {
    AVAudioFormat *audioFormat;
    AudioStreamBasicDescription asbd;
}

@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioFile *playerFile;
@property (nonatomic, strong) AVAudioPlayerNode *audioPlayerNode;
@property (nonatomic, strong) AVAudioUnitTimePitch *audioUnitTimePitch;

@property (nonatomic, assign, getter=isConfig) BOOL config;

@end

@implementation MVYAudioTempoEffect

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.tempo = 1;
        
        memset(&asbd, 0, sizeof(asbd));
        asbd.mSampleRate = 44100;
        asbd.mFormatID = kAudioFormatLinearPCM;
        asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
        asbd.mBytesPerPacket = 2;
        asbd.mFramesPerPacket = 1;
        asbd.mBytesPerFrame = 2;
        asbd.mChannelsPerFrame = 1;
        asbd.mBitsPerChannel = 16;
        asbd.mReserved = 0;
        
        audioFormat = [[AVAudioFormat alloc] initWithStreamDescription:&asbd];
    }
    return self;
}

- (BOOL)process{
    if (!self.isConfig) {
        self.config = YES;        
        [self configureAudioEngine];
    }
    
    self.audioUnitTimePitch.rate = self.tempo;

    // Start engine
    NSError *error;
    [self.engine startAndReturnError:&error];
    if (error) {
        NSLog(@"AVAudioEngine startAndReturnError error:%@", error);
    }
    
    AVAudioFile *audioFile = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:self.inputPath] error:&error];
    if (error) {
        NSLog(@"AVAudioFile initForReading error :%@",error);
        return NO;
    }
    
    [self.audioPlayerNode scheduleFile:audioFile atTime:nil completionHandler:nil];
    
    BOOL result = NO;
    if (@available(iOS 11.0, *)) {
        [self.audioPlayerNode play];
        
        // start offline render
        result = [self renderAudioAndWriteToFile2];
    } else {
        
        [self.audioPlayerNode play];
        [self.engine pause];
        
        // start offline render
        result = [self renderAudioAndWriteToFile];
    }
    
    [self.audioPlayerNode stop];
    [self.engine stop];
   
    return result;
}

#pragma mark - Audio setup

- (void)configureAudioEngine {
    self.engine = [AVAudioEngine new];
    
    // AVAudioPlayerNode
    self.audioPlayerNode = [[AVAudioPlayerNode alloc] init];
    [self.engine attachNode:self.audioPlayerNode];
    
    // AVAudioUnitTimePitch
    self.audioUnitTimePitch = [AVAudioUnitTimePitch new];
    [self.engine attachNode:self.audioUnitTimePitch];
    
    [self.engine connect:self.audioPlayerNode
                      to:self.audioUnitTimePitch
                  format:[self.audioUnitTimePitch outputFormatForBus:0]];
    
    [self.engine connect:self.audioUnitTimePitch
                      to:[self.engine mainMixerNode]
                  format:[[self.engine mainMixerNode] outputFormatForBus:0]];
    
    
    if (@available(iOS 11.0, *)) {
        NSError *error;
        [self.engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:self->audioFormat maximumFrameCount:kFrameCount error:&error];
        if (error) {
            NSLog(@"enableManualRenderingMode Error %@",error.localizedDescription);
        }
    }
}

#pragma mark - Offline rendering  >= iOS 11
- (BOOL)renderAudioAndWriteToFile2{
    
    BOOL result = YES;
    if (@available(iOS 11.0, *)) {
        
        // 1. create ExtAudioFileRef
        ExtAudioFileRef extAudioFile = [self createAndSetupExtAudioFileWithASBD:&self->asbd andFilePath:self.outputPath];
        if (!extAudioFile){
            NSLog(@"ExtAudioFileRef createError");
            return NO;
        }
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.inputPath]];
        
        // 2. create audio buffer
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self->audioFormat frameCapacity:self.engine.manualRenderingMaximumFrameCount];

        // audio frame length
        NSUInteger lengthInFrames = (NSUInteger) (CMTimeGetSeconds(asset.duration) * self->asbd.mSampleRate / self.tempo);

        // 3. offline render
        while (self.engine.manualRenderingSampleTime < lengthInFrames) {
            NSError *error;
            AVAudioEngineManualRenderingStatus status = [self.engine renderOffline:buffer.frameCapacity toBuffer:buffer error:&error];
            switch (status) {
                case AVAudioEngineManualRenderingStatusSuccess:{
                    const AudioBufferList *bufferList = buffer.audioBufferList;                    
                    status = ExtAudioFileWrite(extAudioFile, buffer.frameCapacity, bufferList);
                    if (status != noErr)
                        NSLog(@"Can not write audio to file");
                }
                    break;
                case AVAudioEngineManualRenderingStatusInsufficientDataFromInputNode:
                    NSLog(@"insufficient");
                    break;
                case AVAudioEngineManualRenderingStatusCannotDoInCurrentContext:
                    NSLog(@"colud not render");
                    break;
                case AVAudioEngineManualRenderingStatusError:
                    NSLog(@"error");
                    result = NO;
                    break;
            }
            
            if (error) {
                NSLog(@"renderOffline error %@",error.localizedDescription);
                result = NO;
                break;
            }
        }
        
        SInt64 fileLengthInFrames;
        UInt32 size = sizeof(SInt64);
        ExtAudioFileGetProperty(extAudioFile, kExtAudioFileProperty_FileLengthFrames, &size, &fileLengthInFrames);
        NSLog(@"Audio FileLengthFrames %lld",fileLengthInFrames);

        // 4. free buffer
        OSStatus status = ExtAudioFileDispose(extAudioFile);
        
        if (status != noErr){
            NSLog(@"Audio Tempo Effect Process Failure !");
        } else {
            NSLog(@"Audio Tempo Effect Process Success !");
        }
    }
    return result;
}

#pragma mark - Offline rendering
- (BOOL)renderAudioAndWriteToFile {
    
    // 1. create ExtAudioFileRef
    ExtAudioFileRef extAudioFile = [self createAndSetupExtAudioFileWithASBD:&self->asbd andFilePath:self.outputPath];
    if (!extAudioFile){
        NSLog(@"ExtAudioFileRef createError");
        return NO;
    }
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.inputPath]];
    
    // 2. create audio buffer list
    AudioBufferList *bufferList = allocateAndInitAudioBufferList(self->asbd, kFrameCount);
    
    // audio timeStamp
    AudioTimeStamp timeStamp;
    memset (&timeStamp, 0, sizeof(timeStamp));
    timeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    
    // audio frame length
    NSUInteger lengthInFrames = (NSUInteger) (CMTimeGetSeconds(asset.duration) * self->asbd.mSampleRate / self.tempo);
    
    // 3. offline render
    OSStatus status = noErr;
    for (NSUInteger i = kFrameCount; i < lengthInFrames; i += kFrameCount) {
        status = [self renderToBufferList:bufferList writeToFile:extAudioFile bufferLength:kFrameCount timeStamp:&timeStamp];
        if (status != noErr)
            break;
    }
    
    if (status == noErr && timeStamp.mSampleTime < lengthInFrames) {
        NSUInteger restBufferLength = (NSUInteger) (lengthInFrames - timeStamp.mSampleTime);
        AudioBufferList *restBufferList = allocateAndInitAudioBufferList(self->asbd, (UInt32)restBufferLength);
        status = [self renderToBufferList:restBufferList writeToFile:extAudioFile bufferLength:(UInt32)restBufferLength timeStamp:&timeStamp];
        freeAudioBufferList(restBufferList);
    }
    
    SInt64 fileLengthInFrames;
    UInt32 size = sizeof(SInt64);
    ExtAudioFileGetProperty(extAudioFile, kExtAudioFileProperty_FileLengthFrames, &size, &fileLengthInFrames);
    
    // 4. free buffer
    ExtAudioFileDispose(extAudioFile);
    freeAudioBufferList(bufferList);
    
    if (status != noErr){
        return NO;
    }
    
    NSLog(@"Audio Tempo Effect Process Success !");
    NSLog(@"Audio FileLengthFrames %lld  size %d",fileLengthInFrames,size);
    
    return YES;
}


/**
 创建ExtAudioFileRef, 用于导出新的音频文件

 @param audioDescription 音频流的描述
 @param path 新的音频文件的路径
 @return ExtAudioFileRef
 */
- (ExtAudioFileRef)createAndSetupExtAudioFileWithASBD:(AudioStreamBasicDescription const *)audioDescription andFilePath:(NSString *)path {
    
    AudioStreamBasicDescription destinationFormat = *audioDescription;
    destinationFormat.mChannelsPerFrame = 1;//wav只能是单声道

    ExtAudioFileRef audioFile;
    
    OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef) [NSURL fileURLWithPath:path],
                                                kAudioFileWAVEType,
                                                &destinationFormat,
                                                NULL,
                                                kAudioFileFlags_EraseFile,
                                                &audioFile);
    
    if (status != noErr) {
        NSLog(@"Can not create ext audio file");
        return nil;
    }
    
    UInt32 codecManufacturer = kAppleSoftwareAudioCodecManufacturer;
    status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_CodecManufacturer, sizeof(UInt32), &codecManufacturer);
    status = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(AudioStreamBasicDescription), audioDescription);
    status = ExtAudioFileWriteAsync(audioFile, 0, NULL);
    
    if (status != noErr) {
        NSLog(@"Can not setup ext audio file");
        return nil;
    }
    return audioFile;
}

/**
 创建音频缓冲区
 
 @param audioFormat 音频流格式
 @param frameCount 缓冲的帧数
 @return AudioBufferList
 */
static AudioBufferList *allocateAndInitAudioBufferList(AudioStreamBasicDescription audioFormat, int frameCount) {
    int numberOfBuffers = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? audioFormat.mChannelsPerFrame : 1;
    int channelsPerBuffer = audioFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? 1 : audioFormat.mChannelsPerFrame;
    int bytesPerBuffer = audioFormat.mBytesPerFrame * frameCount;
    AudioBufferList *audio = malloc(sizeof(AudioBufferList) + (numberOfBuffers - 1) * sizeof(AudioBuffer));
    if (!audio) {
        return NULL;
    }
    audio->mNumberBuffers = numberOfBuffers;
    for (int i = 0; i < numberOfBuffers; i++) {
        if (bytesPerBuffer > 0) {
            audio->mBuffers[i].mData = calloc(bytesPerBuffer, 1);
            if (!audio->mBuffers[i].mData) {
                for (int j = 0; j < i; j++) free(audio->mBuffers[j].mData);
                free(audio);
                return NULL;
            }
        } else {
            audio->mBuffers[i].mData = NULL;
        }
        audio->mBuffers[i].mDataByteSize = bytesPerBuffer;
        audio->mBuffers[i].mNumberChannels = channelsPerBuffer;
    }
    return audio;
}

/**
 渲染音频缓冲区数据到音频文件中

 @param bufferList 音频缓冲区
 @param audioFile 音频文件
 @param bufferLength 缓冲区数据的长度
 @param timeStamp 音频缓冲区数据的时间戳
 @return OSStatus
 */
- (OSStatus)renderToBufferList:(AudioBufferList *)bufferList writeToFile:(ExtAudioFileRef)audioFile bufferLength:(UInt32)bufferLength timeStamp:(AudioTimeStamp *)timeStamp {
    
    [self clearBufferList:bufferList];
    
    AudioUnit outputUnit = self.engine.outputNode.audioUnit;
    OSStatus status = AudioUnitRender(outputUnit, 0, timeStamp, 0,bufferLength, bufferList);
    if (status != noErr) {
        NSLog(@"Can not render audio unit");
        return status;
    }
    
    timeStamp->mSampleTime += bufferLength;
    status = ExtAudioFileWrite(audioFile, bufferLength, bufferList);
    if (status != noErr)
        NSLog(@"Can not write audio to file");
    return status;
}

/**
 清空音频缓冲区

 @param bufferList 缓冲区数据
 */
- (void)clearBufferList:(AudioBufferList *)bufferList {
    for (int bufferIndex = 0; bufferIndex < bufferList->mNumberBuffers; bufferIndex++) {
        memset(bufferList->mBuffers[bufferIndex].mData, 0, bufferList->mBuffers[bufferIndex].mDataByteSize);
    }
}

/**
 释放音频缓冲区

 @param bufferList 音频缓冲区
 */
static void freeAudioBufferList(AudioBufferList *bufferList) {
    for (int i = 0; i < bufferList->mNumberBuffers; i++) {
        if (bufferList->mBuffers[i].mData) free(bufferList->mBuffers[i].mData);
    }
    free(bufferList);
}

@end
