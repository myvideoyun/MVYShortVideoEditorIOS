//
//  MVYAudioMixEffect.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYAudioMixEffect.h"
#import <AVFoundation/AVFoundation.h>

static const AVAudioFrameCount kFrameCount = 256;

@interface MVYAudioMixEffect ()

@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) AVAudioFile *playerFile;
@property (nonatomic, strong) AVAudioPlayerNode *audioMainPlayerNode;
@property (nonatomic, strong) AVAudioPlayerNode *audioDeputyPlayerNode;

@property (nonatomic, assign, getter=isConfig) BOOL config;

@end

@implementation MVYAudioMixEffect

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


/**
 核心功能来自于
 https://stackoverflow.com/questions/30679061/can-i-use-avaudioengine-to-read-from-a-file-process-with-an-audio-unit-and-writ?noredirect=1&lq=1

 连接耳机时无法使用
 https://stackoverflow.com/questions/34144456/avaudioengine-offline-render-silent-output-only-when-headphones-connected
*/
- (BOOL)process{
    if (!self.isConfig) {
        self.config = YES;
        [self configureAudioEngine];
    }
    
    self.audioMainPlayerNode.volume = self.mainVolume;
    self.audioDeputyPlayerNode.volume = self.deputyVolume;
    
    // Start engine
    NSError *error;
    [self.engine startAndReturnError:&error];
    if (error) {
        NSLog(@"AVAudioEngine startAndReturnError error:%@", error);
    }
    
    AVAudioFile *mainAudioFile = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:self.inputMainPath] error:&error];
    if (error) {
        NSLog(@"AVAudioFile initForReading error :%@",error);
        return NO;
    }
    
    AVAudioFile *deputyAudioFile = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:self.inputDeputyPath] error:&error];
    if (error) {
        NSLog(@"AVAudioFile initForReading error :%@",error);
        return NO;
    }
    
    [self.audioMainPlayerNode scheduleFile:mainAudioFile atTime:nil completionHandler:nil];
    
    AVAudioFramePosition startPosition = deputyAudioFile.fileFormat.sampleRate * self.deputyStartTime;
    AVAudioFramePosition endPosition = deputyAudioFile.length;
    AVAudioFrameCount frameCount = (AVAudioFrameCount)(mainAudioFile.length > endPosition - startPosition ? endPosition - startPosition : mainAudioFile.length);
    [self.audioDeputyPlayerNode scheduleSegment:deputyAudioFile startingFrame:startPosition  frameCount:frameCount atTime:nil completionHandler:nil];

    BOOL result = NO;
    if (@available(iOS 11.0, *)) {
        [self.audioMainPlayerNode play];
        [self.audioDeputyPlayerNode play];

        // start offline render
        result = [self renderAudioAndWriteToFile2];
    } else {
        
        [self.audioMainPlayerNode play];
        [self.audioDeputyPlayerNode play];
        [self.engine pause];
        
        // start offline render
        result = [self renderAudioAndWriteToFile];
    }
    
    [self.audioMainPlayerNode stop];
    [self.audioDeputyPlayerNode stop];
    [self.engine stop];
    
    return result;
}

#pragma mark - Audio setup

- (void)configureAudioEngine {
    self.engine = [AVAudioEngine new];
    
    // AVAudioPlayerNode
    self.audioMainPlayerNode = [[AVAudioPlayerNode alloc] init];
    [self.engine attachNode:self.audioMainPlayerNode];
    
    self.audioDeputyPlayerNode = [[AVAudioPlayerNode alloc] init];
    [self.engine attachNode:self.audioDeputyPlayerNode];
    
    AVAudioMixerNode *mixerNodel = [[AVAudioMixerNode alloc] init];
    [self.engine attachNode:mixerNodel];
    
    [self.engine connect:self.audioMainPlayerNode
                      to:mixerNodel
                  format:[mixerNodel outputFormatForBus:0]];
    
    [self.engine connect:self.audioDeputyPlayerNode
                      to:mixerNodel
                  format:[mixerNodel outputFormatForBus:0]];
    
    [self.engine connect:mixerNodel
                      to:[self.engine mainMixerNode]
                  format:[[self.engine mainMixerNode] outputFormatForBus:0]];
    
    if (@available(iOS 11.0, *)) {
        NSError *error;
        [self.engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:[[self.engine mainMixerNode] outputFormatForBus:0] maximumFrameCount:kFrameCount error:&error];
        if (error) {
            NSLog(@"enableManualRenderingMode Error %@",error.localizedDescription);
        }
    }
}

#pragma mark - Offline rendering  >= iOS 11
- (BOOL)renderAudioAndWriteToFile2{
    
    BOOL result = YES;
    if (@available(iOS 11.0, *)) {
        AVAudioOutputNode *outputNode = self.engine.outputNode;

        // 1. create ExtAudioFileRef
        AudioStreamBasicDescription const *audioDescription = [outputNode outputFormatForBus:0].streamDescription;
        ExtAudioFileRef extAudioFile = [self createAndSetupExtAudioFileWithASBD:audioDescription andFilePath:self.outputPath];
        if (!extAudioFile){
            NSLog(@"ExtAudioFileRef createError");
            return NO;
        }
        
        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.inputMainPath]];
        
        // 2. create audio buffer
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:self.engine.manualRenderingFormat frameCapacity:self.engine.manualRenderingMaximumFrameCount];

        // audio frame length
        NSUInteger lengthInFrames = (NSUInteger) (CMTimeGetSeconds(asset.duration) * audioDescription->mSampleRate);
        
        // 3. offline render
        while (self.engine.manualRenderingSampleTime < lengthInFrames) {
            NSError *error;
            AVAudioEngineManualRenderingStatus status = [self.engine renderOffline:buffer.frameCapacity toBuffer:buffer error:&error];
            switch (status) {
                case AVAudioEngineManualRenderingStatusSuccess:{
                    const AudioBufferList *bufferList = buffer.audioBufferList;
//                    int32_t *data = bufferList->mBuffers->mData;
//                    NSLog(@"%d",data[0]);
                    
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
        
        // 4. free buffer
        ExtAudioFileDispose(extAudioFile);
        
        NSLog(@"Audio FileLengthFrames %lld  size %d",fileLengthInFrames,size);
    }
    return result;
}

#pragma mark - Offline rendering

- (BOOL)renderAudioAndWriteToFile {
    AVAudioOutputNode *outputNode = self.engine.outputNode;
    
    // 1. create ExtAudioFileRef
    AudioStreamBasicDescription const *audioDescription = [outputNode outputFormatForBus:0].streamDescription;
    ExtAudioFileRef extAudioFile = [self createAndSetupExtAudioFileWithASBD:audioDescription andFilePath:self.outputPath];
    if (!extAudioFile){
        NSLog(@"ExtAudioFileRef createError");
        return NO;
    }
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.inputMainPath]];
    
    // 2. create audio buffer list
    AudioBufferList *bufferList = allocateAndInitAudioBufferList(*audioDescription, kFrameCount);
    
    // audio timeStamp
    AudioTimeStamp timeStamp;
    memset (&timeStamp, 0, sizeof(timeStamp));
    timeStamp.mFlags = kAudioTimeStampSampleTimeValid;
    
    // audio frame length
    NSUInteger lengthInFrames = (NSUInteger) (CMTimeGetSeconds(asset.duration) * audioDescription->mSampleRate);
    
    // 3. offline render
    OSStatus status = noErr;
    for (NSUInteger i = kFrameCount; i < lengthInFrames; i += kFrameCount) {
        status = [self renderToBufferList:bufferList writeToFile:extAudioFile bufferLength:kFrameCount timeStamp:&timeStamp];
        if (status != noErr)
            break;
    }
    
    if (status == noErr && timeStamp.mSampleTime < lengthInFrames) {
        NSUInteger restBufferLength = (NSUInteger) (lengthInFrames - timeStamp.mSampleTime);
        AudioBufferList *restBufferList = allocateAndInitAudioBufferList(*audioDescription, (UInt32)restBufferLength);
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
    destinationFormat.mChannelsPerFrame = 1;//CAF只能是单声道

    ExtAudioFileRef audioFile;
    
    OSStatus status = ExtAudioFileCreateWithURL((__bridge CFURLRef) [NSURL fileURLWithPath:path],
                                                kAudioFileCAFType,
                                                &destinationFormat,
                                                NULL,
                                                kAudioFileFlags_EraseFile,
                                                &audioFile);
    
    if (status != noErr) {
        NSError *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                             code:status
                                         userInfo:nil];
        NSLog(@"Can not create ext audio file Error: %@", [error localizedDescription]);
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
    
    UInt32 ioActionFlags = 0;
    OSStatus status = AudioUnitRender(outputUnit, &ioActionFlags, timeStamp, 0, bufferLength, bufferList);
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
