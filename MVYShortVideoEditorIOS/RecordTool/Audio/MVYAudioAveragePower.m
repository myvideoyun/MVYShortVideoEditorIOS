//
//  MVYAudioAveragePower.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYAudioAveragePower.h"
#import <AVFoundation/AVFoundation.h>

@implementation MVYAudioAveragePower

+ (NSArray *)averagePowerWithAudioURL:(NSURL *)url sampleCount:(NSUInteger)filteredSamplesCount{
    
    NSMutableArray *filteredSamplesArr = [[NSMutableArray alloc]init];
    NSData *data = [MVYAudioAveragePower pcmDataFromURL:url];
    
    //计算所有数据个数
    NSUInteger  sampleCount = data.length / sizeof(SInt16);
    
    //将数据分割，也就是按照我们的需求将数据分为一个个小包
    NSUInteger  spanSize     = sampleCount / filteredSamplesCount;
    
    SInt16 *bytes = (SInt16 *)data.bytes;
    
    //sint16两个字节的空间
    SInt16 maxSample = 0;
    
    //以spanSize为一个样本。每个样本中取一个最大数。也就是在固定范围取一个最大的数据保存，达到缩减目的
    //在sampleCount（所有数据）个数据中抽样，抽样方法为在spanSize个数据为一个样本，在样本中选取一个数据
    for (NSUInteger i= 0; i < sampleCount - spanSize; i += spanSize){
        
        SInt16 *sampleBin = (SInt16 *) malloc(spanSize * sizeof(SInt16));
        for (NSUInteger j = 0; j < spanSize; j++) {//先将每次抽样样本的spanSize个数据遍历出来
            sampleBin[j] = CFSwapInt16LittleToHost(bytes[i + j]);
        }
        
        //选取样本数据中的平均值
        SInt16 value = [MVYAudioAveragePower averageValueInArray:sampleBin ofSize:spanSize];
        
        //保存数据
        [filteredSamplesArr addObject:@(value)];
        
        //将所有数据中的最大数据保存，作为一个参考。可以根据情况对所有数据进行“缩放”
        if (value > maxSample) {
            maxSample = value;
        }
        
        free(sampleBin);
    }
    //计算比例因子
    CGFloat scaleFactor = 1.f / maxSample;
    
    //对所有数据进行“缩放”
    for (NSUInteger i = 0; i < filteredSamplesArr.count; i++) {
        filteredSamplesArr[i] = @([filteredSamplesArr[i] integerValue] * scaleFactor);
    }
    
    return filteredSamplesArr;
}

+ (NSData *)pcmDataFromURL:(NSURL *)url{
    NSError *error;
    
    // 创建音频数据读取器
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetReader *reader = [[AVAssetReader alloc]initWithAsset:asset error:&error];
    if (!reader) {
        NSLog(@"AVAssetReader error : %@",[error localizedDescription]);
        return nil;
    }
    
    // 设置音频数据输出参数
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    NSDictionary *dic   = @{AVFormatIDKey            :@(kAudioFormatLinearPCM),
                            AVLinearPCMIsBigEndianKey:@NO,
                            AVLinearPCMIsFloatKey    :@NO,
                            AVLinearPCMBitDepthKey   :@(16)
                            };
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:dic];
    
    // 开始读取音频数据
    [reader addOutput:output];
    [reader startReading];
    
    //用于保存音频数据
    NSMutableData *data = [[NSMutableData alloc]init];
    
    //读取是一个持续的过程，每次只读取后面对应的大小的数据。当读取的状态发生改变时，其status属性会发生对应的改变，我们可以凭此判断是否完成文件读取
    while (reader.status == AVAssetReaderStatusReading) {
        
        CMSampleBufferRef  sampleBuffer = [output copyNextSampleBuffer]; //读取到数据
        if (sampleBuffer) {
            
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(sampleBuffer);//取出数据
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef);   //返回一个大小，size_t针对不同的品台有不同的实现，扩展性更好
            SInt16 sampleBytes[length];
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes); //将数据放入数组
            [data appendBytes:sampleBytes length:length];                 //将数据附加到data中
            CMSampleBufferInvalidate(sampleBuffer);  //销毁
            CFRelease(sampleBuffer);                 //释放
        }
    }
    if (reader.status != AVAssetReaderStatusCompleted) {
        NSLog(@"AVAssetReader 音频数据读取失败");
        return nil;
    }
    
    return data;
}

+ (SInt16)averageValueInArray:(SInt16[])values ofSize:(NSUInteger)size {
    
    size = size > 3000 ? 3000 : size;
    
    SInt16 averageValue = 0;
    
    SInt64 countValue = 0;
    for (int i = 0; i < size; i++) {
        countValue += abs(values[i]);
    }
    
    averageValue = countValue / size;
    
    return averageValue;
}

@end

