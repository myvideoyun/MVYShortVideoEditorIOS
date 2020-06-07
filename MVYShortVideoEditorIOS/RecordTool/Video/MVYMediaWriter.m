//
//  MVYMediaWriter.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYMediaWriter.h"

#import <UIKit/UIDevice.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface MVYMediaWriter (){
    dispatch_queue_t writerQueue; // AVAssetWriter 不能并行调用, 会出错.
}

@property (nonatomic, strong) AVAssetWriter *assetVideoWriter;
@property (nonatomic, strong) AVAssetWriter *assetAudioWriter;
@property (nonatomic, strong) AVAssetWriter *assetMediaWriter;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdapter;
@property (nonatomic, assign) BOOL videoAlreadySetup;
@property (nonatomic, assign) BOOL audioAlreadySetup;
@property (nonatomic, assign) BOOL isFinish;

@property (atomic, assign) BOOL canStartWrite;
@property (atomic, assign) BOOL hasFirstFrameTime;

@property (nonatomic, assign) CMTime firstTime;

@property (nonatomic, assign) CMTime lastFramePresentationTimeStamp;

@end

@implementation MVYMediaWriter

#pragma mark - init

// 视频的码率
//static const int  = 4; // videoBitRate = width * height * kVideoBitRateFactor;

// 帧率
//static const int kVideoFrameRate = 30;

// 画面旋转方向
static const float radian = M_PI_2;

+ (MVYMediaWriter *)sharedInstance {
    static MVYMediaWriter *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MVYMediaWriter alloc] init];
    });
    
    return instance;
}

- (id)init{
    self = [super init];
    if (self) {
        writerQueue = dispatch_queue_create("com.myvideoyun.videorecord", DISPATCH_QUEUE_SERIAL);
        
        self.videoSpeed = CMTimeMake(1, 1);
    }
    return self;
}

- (void)setOutputVideoURL:(NSURL *)outputVideoURL{
    _outputVideoURL = outputVideoURL;
    
    NSError *error = nil;
    _assetVideoWriter = [AVAssetWriter assetWriterWithURL:outputVideoURL fileType:AVFileTypeAppleM4V error:&error];
    if (error) {
        NSLog(@"error setting up the asset writer (%@)", error);
        self.assetVideoWriter = nil;
        return;
    }
    
    self.assetVideoWriter.shouldOptimizeForNetworkUse = YES;
    self.assetVideoWriter.metadata = [self _metadataArray];
    
    _videoAlreadySetup = NO;
    _audioAlreadySetup = NO;
    _isFinish = NO;
    _canStartWrite = NO;
    _hasFirstFrameTime = NO;
    
    _lastFramePresentationTimeStamp = kCMTimeZero;
}

- (void)setOutputAudioURL:(NSURL *)outputAudioURL{
    _outputAudioURL = outputAudioURL;
    
    NSError *error = nil;
    _assetAudioWriter = [AVAssetWriter assetWriterWithURL:outputAudioURL fileType:AVFileTypeAppleM4A error:&error];
    if (error) {
        NSLog(@"error setting up the asset writer (%@)", error);
        self.assetAudioWriter = nil;
        return;
    }
    
    self.assetAudioWriter.shouldOptimizeForNetworkUse = YES;
    self.assetAudioWriter.metadata = [self _metadataArray];
    
    _videoAlreadySetup = NO;
    _audioAlreadySetup = NO;
    _isFinish = NO;
    _canStartWrite = NO;
    _hasFirstFrameTime = NO;
}

- (void)setOutputMediaURL:(NSURL *)outputMediaURL {
    NSError *error = nil;
    _assetMediaWriter = [AVAssetWriter assetWriterWithURL:outputMediaURL fileType:AVFileTypeMPEG4 error:&error];
    if (error) {
        NSLog(@"error setting up the asset writer (%@)", error);
        self.assetMediaWriter = nil;
        return;
    }
    
    self.assetMediaWriter.shouldOptimizeForNetworkUse = YES;
    self.assetMediaWriter.metadata = [self _metadataArray];
    
    _videoAlreadySetup = NO;
    _audioAlreadySetup = NO;
    _isFinish = NO;
    _canStartWrite = NO;
    _hasFirstFrameTime = NO;
    
    _lastFramePresentationTimeStamp = kCMTimeZero;
    
    _assetVideoWriter = _assetMediaWriter;
    _assetAudioWriter = _assetMediaWriter;
}

- (NSInteger)videoBitRate {
    if (_videoBitRate == 0) {
        return 4 * 1000 * 1000;
    } else {
        return _videoBitRate;
    }
}

- (NSInteger)audioBitRate {
    if (_audioBitRate == 0) {
        return 64000;
    } else {
        return _audioBitRate;
    }
}

- (NSInteger)videoFrameRate {
    if (_videoFrameRate == 0) {
        return 30;
    } else {
        return _videoFrameRate;
    }
}

#pragma mark - private

- (NSArray *)_metadataArray{
    
    UIDevice *currentDevice = [UIDevice currentDevice];

    // device model
    AVMutableMetadataItem *modelItem = [[AVMutableMetadataItem alloc] init];
    [modelItem setKeySpace:AVMetadataKeySpaceCommon];
    [modelItem setKey:AVMetadataCommonKeyModel];
    [modelItem setValue:[currentDevice localizedModel]];

    // creation date
    AVMutableMetadataItem *creationDateItem = [[AVMutableMetadataItem alloc] init];
    [creationDateItem setKeySpace:AVMetadataKeySpaceCommon];
    [creationDateItem setKey:AVMetadataCommonKeyCreationDate];
    [creationDateItem setValue:[MVYMediaWriter AiyaVideoFormattedTimestampStringFromDate:[NSDate date]]];

    return @[modelItem, creationDateItem];
}

#pragma mark - setup

- (BOOL)setupAudioWithSettings:(CMSampleBufferRef)sampleBuffer{
    
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);
    if (!asbd) {
        NSLog(@"audio stream description used with non-audio format description");
        return NO;
    }
    
    double sampleRate = asbd->mSampleRate;
    
    AudioChannelLayout acl;
    bzero(&acl, sizeof(AudioChannelLayout));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
//    size_t aclSize = 0;
//    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(formatDescription, &aclSize);
//    NSData *currentChannelLayoutData = ( currentChannelLayout && aclSize > 0 ) ? [NSData dataWithBytes:currentChannelLayout length:aclSize] : [NSData data];
    
    NSDictionary *audioSettings = @{ AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                     AVNumberOfChannelsKey : @(1),
                                     AVSampleRateKey :  @(sampleRate),
                                     AVEncoderBitRateKey : @(self.audioBitRate),
                                     AVChannelLayoutKey : [NSData dataWithBytes:&acl length:sizeof(AudioChannelLayout)] };

    if (!self.assetWriterAudioInput && [self.assetAudioWriter canApplyOutputSettings:audioSettings forMediaType:AVMediaTypeAudio]) {

        self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioSettings];
        self.assetWriterAudioInput.expectsMediaDataInRealTime = YES;

        if (self.assetWriterAudioInput && [self.assetAudioWriter canAddInput:self.assetWriterAudioInput]) {
            [self.assetAudioWriter addInput:self.assetWriterAudioInput];
        } else {
            NSLog(@"couldn't add asset writer audio input");
            self.assetWriterAudioInput = nil;
            return NO;
        }

    } else {

        self.assetWriterAudioInput = nil;
        NSLog(@"couldn't apply audio output settings");
        return NO;
    }

    return YES;
}

- (BOOL)setupVideoWithSettings:(CVImageBufferRef)pixelBuffer {
    
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    if (self.videoWidth && self.videoHeight) { // 视频是画面是旋转了90度的
        width = (int)self.videoHeight;
        height = (int)self.videoWidth;
        
        NSLog(@"height %d , width %d",height ,width);
    }
    
    NSDictionary *videoSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
                                     AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                     AVVideoWidthKey : @(width),
                                     AVVideoHeightKey : @(height),
                                     AVVideoCompressionPropertiesKey : @{
                                             AVVideoAverageBitRateKey : @(self.videoBitRate),
                                             AVVideoExpectedSourceFrameRateKey : @(self.videoFrameRate),
                                             AVVideoMaxKeyFrameIntervalKey : @(self.videoFrameRate)
                                             }
                                    };
    
    if (!self.assetWriterVideoInput && [self.assetVideoWriter canApplyOutputSettings:videoSettings forMediaType:AVMediaTypeVideo]) {

        self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        self.assetWriterVideoInput.expectsMediaDataInRealTime = YES;
        self.assetWriterVideoInput.transform = CGAffineTransformMakeRotation(radian); //CGAffineTransformConcat(CGAffineTransformMakeRotation(radian), CGAffineTransformMakeTranslation(height, 0));
        
        if (self.assetWriterVideoInput && [self.assetVideoWriter canAddInput:self.assetWriterVideoInput]) {
            
            [self.assetVideoWriter addInput:self.assetWriterVideoInput];
        } else {
            
            self.assetWriterVideoInput = nil;
            NSLog(@"couldn't add asset writer video input");
            return NO;
        }
        
        self.pixelBufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.assetWriterVideoInput sourcePixelBufferAttributes:@{(NSString *)kCVPixelBufferPixelFormatTypeKey: @(CVPixelBufferGetPixelFormatType(pixelBuffer))}];

    } else {

        self.assetWriterVideoInput = nil;
        NSLog(@"couldn't apply video output settings");
        return NO;
    }

    return YES;
}

#pragma mark - sample buffer writing

- (void)writeAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (self.isFinish) {
        return;
    }
    
    if (!self.audioAlreadySetup){
        dispatch_sync(writerQueue, ^{
            self.audioAlreadySetup = [self setupAudioWithSettings:sampleBuffer];
        });
        
        if (!self.audioAlreadySetup) {
            NSLog(@"设置音频参数失败");
            return;
        } else {
            NSLog(@"设置音频参数成功");
        }
    }
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        return;
    }
    
    while (!self.hasFirstFrameTime && !self.isFinish) {
        [NSThread sleepForTimeInterval:0.001];
    }

    // setup the writer
    if ( self.assetAudioWriter.status == AVAssetWriterStatusUnknown ) {
        NSLog(@"audio writer unknown");
        return;
    }

    // check for completion state
    if ( self.assetAudioWriter.status == AVAssetWriterStatusFailed ) {
        NSLog(@"audio writer failure, (%@)", self.assetAudioWriter.error.localizedDescription);
        return;
    }

    if (self.assetAudioWriter.status == AVAssetWriterStatusCancelled) {
        NSLog(@"audio writer cancelled");
        return;
    }

    if ( self.assetAudioWriter.status == AVAssetWriterStatusCompleted) {
        return;
    }
    
    // perform write
    if ( self.assetAudioWriter.status == AVAssetWriterStatusWriting && _canStartWrite && self.hasFirstFrameTime) {
        
        CFRetain(sampleBuffer);
        
        dispatch_async(writerQueue, ^{
            if (self.assetWriterAudioInput) {
                
                for (int x = 0; x < 10; x++) {
                    if ([self.assetWriterAudioInput isReadyForMoreMediaData] == false) {
                        [NSThread sleepForTimeInterval:0.001];
                    }
                }
                
                if (self.assetWriterAudioInput.readyForMoreMediaData) {
                
                    CMSampleBufferRef adjustedSampleBuffer = [self adjustTime:sampleBuffer by:self.firstTime];

                    if (adjustedSampleBuffer ) {
                        if (![self.assetWriterAudioInput appendSampleBuffer:adjustedSampleBuffer]) {
                            NSLog(@"audio writer error appending audio (%@)", self.assetAudioWriter.error);
                        }else {
                            NSLog(@"audio write success. pts : %.2f", CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(adjustedSampleBuffer)));
                        }
                        
                        CFRelease(adjustedSampleBuffer);
                    }
                }else {
                    NSLog(@"audio writer is not ready");
                }
            }
            CFRelease(sampleBuffer);
        });
    }
}

- (CMSampleBufferRef) adjustTime:(CMSampleBufferRef) sample by:(CMTime) offset{
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    
    for (CMItemCount i = 0; i < count; i++){
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

- (void)writeVideoPixelBuffer:(CVPixelBufferRef)pixelBuffer time:(CMTime)frameTime {
    if (self.isFinish) {
        return;
    }
    
    if (!self.videoAlreadySetup){
        dispatch_sync(writerQueue, ^{
            self.videoAlreadySetup = [self setupVideoWithSettings:pixelBuffer];
        });
        
        if (!self.videoAlreadySetup){
            NSLog(@"设置视频参数失败");
            return;
        } else {
            NSLog(@"设置视频参数成功");
        }
    }
    
    // 等待音频初始化完成
    if (self.assetAudioWriter && self.assetVideoWriter != self.assetAudioWriter) {
        for (int i = 0; i < 1000; i++) {
            if (self.audioAlreadySetup) {
                break;
            } else {
                [NSThread sleepForTimeInterval:0.001];
            }
        }
    }
    
        
    if ( self.assetVideoWriter.status == AVAssetWriterStatusUnknown ) {
        
        dispatch_sync(writerQueue, ^{
            if (!self.canStartWrite){
                //开始视频录制
                Boolean videoStartWriting = [self.assetVideoWriter startWriting];
                Boolean audioStartWriting = true;
                if (!self.assetAudioWriter) {
                    audioStartWriting = true;
                } else if (self.assetVideoWriter == self.assetAudioWriter) {
                    audioStartWriting = videoStartWriting;
                } else {
                    audioStartWriting = [self.assetAudioWriter startWriting];
                }
                
                if (videoStartWriting && audioStartWriting) {
                    self.canStartWrite = YES;
                } else {
                    NSLog(@"vudio error when starting to write (%@)", [self.assetVideoWriter error]);
                    NSLog(@"audio error when starting to write (%@)", [self.assetAudioWriter error]);
                }
            }
        });
    }
    
    // check for completion state
    if ( self.assetVideoWriter.status == AVAssetWriterStatusFailed ) {
        NSLog(@"video writer failure, (%@)", self.assetVideoWriter.error.localizedDescription);
        return;
    }
    
    if (self.assetVideoWriter.status == AVAssetWriterStatusCancelled) {
        NSLog(@"video writer cancelled");
        return;
    }
    
    if ( self.assetVideoWriter.status == AVAssetWriterStatusCompleted) {
        NSLog(@"video writer completed");
        return;
    }
    
    // perform write
    if ( self.assetVideoWriter.status == AVAssetWriterStatusWriting && _canStartWrite) {
        if (!self.canStartWrite) {
            NSLog(@"video canStartWrite");
        }
        
        for (int x = 0; x < 30; x++) {
            if ([self.assetWriterVideoInput isReadyForMoreMediaData] == false) {
                [NSThread sleepForTimeInterval:0.001];
            }
        }
        
        if ([self.assetWriterVideoInput isReadyForMoreMediaData]) {

            CVPixelBufferRetain(pixelBuffer);

            dispatch_async(writerQueue, ^{
                if (self.isFinish){

                    CVPixelBufferRelease(pixelBuffer);
                    return;
                }
                
                CMTime videoTime;
                
                if (!self.hasFirstFrameTime) {
                    
                    self.firstTime = frameTime;
                    
                    videoTime = kCMTimeZero;
                    [self.assetVideoWriter startSessionAtSourceTime:videoTime];
                    if (self.assetVideoWriter != self.assetAudioWriter) {
                        [self.assetAudioWriter startSessionAtSourceTime:videoTime];
                    }
                    self.hasFirstFrameTime = YES;
                    NSLog(@"设置第一帧的时间");
                }else {
                    videoTime = CMTimeSubtract(frameTime, self.firstTime);
                    videoTime = CMTimeMultiplyByRatio(videoTime, self.videoSpeed.timescale, (int32_t)self.videoSpeed.value);
                }
                
                if (![self.pixelBufferAdapter appendPixelBuffer:pixelBuffer withPresentationTime:videoTime]) {
                    NSLog(@"video writer error appending video (%@)", self.assetVideoWriter.error);
                } else {
                    NSLog(@"video write success. pts : %.2f", CMTimeGetSeconds(videoTime));
                    self.lastFramePresentationTimeStamp = videoTime;
                }
                
                CVPixelBufferRelease(pixelBuffer);
            });
            
        } else {
            NSLog(@"video writer is not ready");
        }
    }
}

- (void)finishWritingWithCompletionHandler:(void (^)(void))handler{
    dispatch_async(writerQueue, ^{//等待数据全部完成写入
        if (self.isFinish) {
            return;
        }
        
        self.isFinish = YES;
        self.canStartWrite = NO;
        self.hasFirstFrameTime = NO;
        
        if (self.assetVideoWriter.status == AVAssetWriterStatusUnknown ||
            self.assetVideoWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"asset video writer was in an unexpected state (%@)", @(self.assetVideoWriter.status));
            return;
        }
        
        if (self.assetVideoWriter != self.assetAudioWriter) {
            if (self.assetAudioWriter && (self.assetAudioWriter.status == AVAssetWriterStatusUnknown ||
                                          self.assetAudioWriter.status == AVAssetWriterStatusCompleted)) {
                NSLog(@"asset audio writer was in an unexpected state (%@)", @(self.assetAudioWriter.status));
                return;
            }
        }
        
        
        [self.assetWriterVideoInput markAsFinished];
        [self.assetWriterAudioInput markAsFinished];

        if (self.assetAudioWriter && self.assetVideoWriter != self.assetAudioWriter) {
            [self.assetVideoWriter finishWriting];
            [self.assetAudioWriter finishWritingWithCompletionHandler:handler];
        } else {
            [self.assetVideoWriter finishWritingWithCompletionHandler:handler];
        }
        
        self.assetWriterVideoInput = nil;
        self.assetWriterAudioInput = nil;
        
        self.assetVideoWriter = nil;
        self.assetAudioWriter = nil;
    });
}

- (void)cancelWriting{
    dispatch_async(writerQueue, ^{//等待数据全部完成写入
        if (self.isFinish) {
            return;
        }
        
        self.isFinish = YES;
        self.canStartWrite = NO;
        self.hasFirstFrameTime = NO;
        
        if (self.assetVideoWriter.status == AVAssetWriterStatusUnknown ||
            self.assetVideoWriter.status == AVAssetWriterStatusCompleted) {
            NSLog(@"asset video writer was in an unexpected state (%@)", @(self.assetVideoWriter.status));
            return;
        }
        
        if (self.assetVideoWriter != self.assetAudioWriter) {
            if (self.assetAudioWriter.status == AVAssetWriterStatusUnknown ||
                self.assetAudioWriter.status == AVAssetWriterStatusCompleted) {
                NSLog(@"asset audio writer was in an unexpected state (%@)", @(self.assetAudioWriter.status));
                return;
            }
        }
        
        [self.assetWriterVideoInput markAsFinished];
        [self.assetWriterAudioInput markAsFinished];
        
        [self.assetVideoWriter cancelWriting];
        if (self.assetVideoWriter != self.assetAudioWriter) {
            [self.assetAudioWriter cancelWriting];
        }

        self.assetWriterAudioInput = nil;
        self.assetWriterVideoInput = nil;
        
        self.assetVideoWriter = nil;
        self.assetAudioWriter = nil;
    });
}

- (BOOL)isWriteFinish{
    __block BOOL isWriteFinish;
    
    dispatch_sync(writerQueue, ^{
        isWriteFinish = self.isFinish;
    });
    
    return isWriteFinish;
}

+ (NSString *)AiyaVideoFormattedTimestampStringFromDate:(NSDate *)date{
    if (!date)
        return nil;
    
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"];
        [dateFormatter setLocale:[NSLocale autoupdatingCurrentLocale]];
    });
    
    return [dateFormatter stringFromDate:date];
}

- (void)dealloc{
}
@end

@implementation MVYMediaWriterTool

+ (CMSampleBufferRef)PCMDataToSampleBuffer:(NSData *)pcmData pts:(CMTime)pts duration:(CMTime)duration{
    
    AudioStreamBasicDescription asbd;
    asbd.mSampleRate = 44100;
    asbd.mFormatID = kAudioFormatLinearPCM;
    asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    asbd.mBytesPerPacket = 2;
    asbd.mFramesPerPacket = 1;
    asbd.mBytesPerFrame = 2;
    asbd.mChannelsPerFrame = 1;
    asbd.mBitsPerChannel = 16;
    asbd.mReserved = 0;

    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mNumberChannels = 1;
    bufferList.mBuffers[0].mData = (void *)pcmData.bytes;
    bufferList.mBuffers[0].mDataByteSize = (UInt32)pcmData.length;
    
    CMSampleTimingInfo timing;
    timing.presentationTimeStamp = pts;
    timing.duration = CMTimeMake(1, 44100);
    timing.decodeTimeStamp = kCMTimeInvalid;

    OSType error;
    
    CMAudioFormatDescriptionRef format;
    error = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &asbd, 0, 0, 0, 0, 0, &format);
    if (error) {
        NSLog(@"PCMData convert SampleBuffer error %d", error);
        return NULL;
    }
    
    CMSampleBufferRef sampleBuffer;
    error = CMSampleBufferCreate(kCFAllocatorDefault, 0, 0, 0, 0, format, pcmData.length/2, 1, &timing, 0, 0, &sampleBuffer);
    if (error) {
        NSLog(@"PCMData convert SampleBuffer error %d", error);
        return NULL;
    }
    
    error = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, &bufferList);
    if (error) {
        NSLog(@"PCMData convert SampleBuffer error %d", error);
        return NULL;
    }
    
    CFRelease(format);

    return sampleBuffer;
}

@end
