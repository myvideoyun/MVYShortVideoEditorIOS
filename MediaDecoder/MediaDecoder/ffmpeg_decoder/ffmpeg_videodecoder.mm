//
//  ffmpeg_videodecoder.m
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/14.
//  Copyright © 2019 myvideoyun. All rights reserved.
//
#pragma clang diagnostic ignored"-Wdeprecated-declarations"

#import "ffmpeg_videodecoder.h"

#include <string>
#include <sys/param.h>
#include <vector>
#include <sstream>

static const char *TAG = "FFVideoDecoder";

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
}

namespace MVY {
    
    // 视频帧数据
    typedef struct VideoFrame{
        float width;
        float height;
        int lineSize;
        int rotate;
        int64_t pts;
        int64_t duration;
        int64_t length;
        uint8_t *Y_Data;
        uint8_t *U_Data;
        uint8_t *V_Data;
        int isKeyFrame;
    } VideoFrame;
    
    // 错误枚举
    typedef enum {
        MovieErrorNone,
        MovieErrorOpenFile,
        MovieErrorStreamInfoNotFound,
        MovieErrorStreamNotFound,
        MovieErrorCodecNotFound,
        MovieErrorOpenCodec,
        MovieErrorAllocateFrame,
    } MovieError;
    
    
    typedef struct VideoDecoder {
        
        // 解码器
        AVCodecContext *mvyCodecContext;
        
        // 视频流ID
        int mvyVideoStream;
        
        // 视频帧
        AVFrame *mvyVideoFrame;
        
        // 文件格式
        AVFormatContext *mvyFormatContext;
        
        // eos 标记
        int eos;
        
        // 没有更多帧可读
        int no_decoded_frame;
        
        // 内部错误
        int internal_error;
    } VideoDecoder;
}

using MVY::VideoDecoder;
using MVY::VideoFrame;

// 创建对象
static VideoDecoder* initVideoDecoder() {
    VideoDecoder *videoDecoder = (VideoDecoder *)malloc(sizeof(VideoDecoder));
    memset(videoDecoder, 0, sizeof(VideoDecoder));
    return videoDecoder;
}

// 销毁对象
static void deinitVideoDecoder(VideoDecoder* videoDecoder) {
    NSLog(@"%s %s", TAG, "free video Decoder1");
    free(videoDecoder);
}

// 打开文件
static MVY::MovieError openFile(VideoDecoder* videoDecoder, const char *path, const char *fileName) {
    AVFormatContext *formatCtx = NULL;
    
    int result = avformat_open_input(&formatCtx, path, NULL, NULL);
    if (result < 0) {
        if (formatCtx) {
            avformat_free_context(formatCtx);
        }
        
        std::ostringstream ss;
        ss << "MovieErrorOpenFile ";
        ss << result;
        ss << " ";
        ss << path;
        
        NSLog(@"%s %s", TAG, ss.str().data());
        return MVY::MovieErrorOpenFile;
    }
    
    if (avformat_find_stream_info(formatCtx, NULL) < 0) {
        avformat_close_input(&formatCtx);
        
        NSLog(@"%s %s", TAG, "MovieErrorStreamInfoNotFound");
        return MVY::MovieErrorStreamInfoNotFound;
    }
    
    av_dump_format(formatCtx, 0, fileName, false);
    
    videoDecoder->mvyFormatContext = formatCtx;
    return MVY::MovieErrorNone;
}

// 打开视频流
static MVY::MovieError openVideoStream(VideoDecoder* videoDecoder) {
    MVY::MovieError errCode = MVY::MovieErrorStreamNotFound;
    videoDecoder->mvyVideoStream = -1;
    
    for (int i=0; i<videoDecoder->mvyFormatContext->nb_streams; ++i) {
        if (AVMEDIA_TYPE_VIDEO == videoDecoder->mvyFormatContext->streams[i]->codec->codec_type) {
            if (0 == (videoDecoder->mvyFormatContext->streams[i]->disposition & AV_DISPOSITION_ATTACHED_PIC)) {
                
                AVCodecContext *codecCtx = videoDecoder->mvyFormatContext->streams[i]->codec;
                
                AVCodec *codec = avcodec_find_decoder(codecCtx->codec_id);
                if (!codec) {
                    
                    NSLog(@"%s %s", TAG, "MovieErrorCodecNotFound");
                    errCode = MVY::MovieErrorCodecNotFound;
                    continue;
                }
                
                codecCtx->thread_count = 4;
                codecCtx->thread_type = FF_THREAD_FRAME;
                
                if (avcodec_open2(codecCtx, codec, NULL) < 0) {
                    NSLog(@"%s %s", TAG, "MovieErrorOpenCodec");
                    errCode = MVY::MovieErrorOpenCodec;
                    continue;
                }
                
                std::ostringstream ss;
                ss << "thread count : ";
                ss << codecCtx->thread_count;
                ss << " codecName : ";
                ss << codecCtx->codec->name;
                NSLog(@"%s %s", TAG, ss.str().data());
                
                videoDecoder->mvyVideoFrame = av_frame_alloc();
                
                if (!videoDecoder->mvyVideoFrame) {
                    avcodec_close(codecCtx);
                    
                    NSLog(@"%s %s", TAG, "MovieErrorAllocateFrame");
                    errCode = MVY::MovieErrorAllocateFrame;
                    continue;
                }
                
                videoDecoder->mvyVideoStream = i;
                videoDecoder->mvyCodecContext = codecCtx;
                
                errCode = MVY::MovieErrorNone;
                break;
            }
        }
    }
    
    return errCode;
}

static void clearStatus(VideoDecoder *videoDecoder){
    NSLog(@"%s %s", TAG, "Clear decoder status\n");
    videoDecoder->eos = 0;
    videoDecoder->internal_error = 0;
    videoDecoder->no_decoded_frame = 0;
}

// 关闭视频流
static void closeVideoStream(VideoDecoder* videoDecoder) {
    NSLog(@"%s %s", TAG, "Close Video Stream");
    videoDecoder->mvyVideoStream = -1;
    
    clearStatus(videoDecoder);
    
    if (videoDecoder->mvyVideoFrame) {
        av_free(videoDecoder->mvyVideoFrame);
        videoDecoder->mvyVideoFrame = NULL;
    }
    
    if (videoDecoder->mvyCodecContext) {
        avcodec_close(videoDecoder->mvyCodecContext);
        videoDecoder->mvyCodecContext = NULL;
    }
}


// 关闭文件
static void closeFile(VideoDecoder* videoDecoder) {
    videoDecoder->mvyVideoStream = NULL;
    
    if (videoDecoder->mvyFormatContext) {
        avformat_close_input(&(videoDecoder->mvyFormatContext));
        videoDecoder->mvyFormatContext = NULL;
    }
}

// 解码一帧视频
static std::vector<VideoFrame> decodeAFrame(VideoDecoder* videoDecoder) {
    std::vector<VideoFrame> result;
    
    if (videoDecoder->mvyVideoStream == -1) {
        return result;
    }
    
    AVPacket packet;
    
    if(videoDecoder->internal_error == 1){
        NSLog(@"%s %s", TAG, "Unexpected, decoder has error, should stop now\n");
        return result;
    }
    
    if(videoDecoder->no_decoded_frame){
        NSLog(@"%s %s", TAG, "No more decoded frame\n");
        return result;
    }
    
    // keep reading until we got one frame or encount end of
    while(true) {
        if(videoDecoder->eos == 0){
            auto code = av_read_frame(videoDecoder->mvyFormatContext, &packet);
            if (code < 0) {
                if (code == AVERROR_EOF) {
                    NSLog(@"%s %s", TAG, "prepare empty packet to notify decoder, set eos flags\n");
                    packet.data = NULL;
                    packet.size = 0;
                    videoDecoder->eos = 1;
                } else {
                    // some other errors
                    NSLog(@"%s %s", TAG, "Encount some other error");
                    videoDecoder->internal_error = 1;
                    return result;
                }
            } else if(packet.stream_index != videoDecoder->mvyVideoStream){
                // NSLog(@"%s %s", TAG, "Keep reading\n");
                av_free_packet(&packet);
                continue;
            }
        } else{ // eos is 1
            NSLog(@"%s %s", TAG, "Flush the decoded frame\n");
            packet.data = NULL;
            packet.size = 0;
        }
        
        // Usually call avcodec_decode_video2 once for one valid packet.
        // flush the decoder only
        int gotFrame = 0;
        
        avcodec_decode_video2(videoDecoder->mvyCodecContext, videoDecoder->mvyVideoFrame, &gotFrame, &packet);
        
        double timeBase = av_q2d(videoDecoder->mvyFormatContext->streams[videoDecoder->mvyVideoStream]->time_base);
        
        int64_t videoDuration = (int64_t)(videoDecoder->mvyFormatContext->streams[videoDecoder->mvyVideoStream]->duration * timeBase * 1000);
        
        if (gotFrame) {
            
            VideoFrame frame;
            frame.width = videoDecoder->mvyCodecContext->width;
            frame.height = videoDecoder->mvyCodecContext->height;
            frame.lineSize = videoDecoder->mvyVideoFrame->linesize[0];
            frame.rotate = 0;
            AVDictionaryEntry *tag = NULL;
            tag=av_dict_get(videoDecoder->mvyFormatContext->streams[videoDecoder->mvyVideoStream]->metadata, "rotate", tag, AV_DICT_IGNORE_SUFFIX);
            if (tag != NULL) {
                frame.rotate = atoi(tag->value);
            }
            
            frame.pts = (int64_t)(av_frame_get_best_effort_timestamp(videoDecoder->mvyVideoFrame) * timeBase * 1000);
            frame.duration =  (int64_t)(av_frame_get_pkt_duration(videoDecoder->mvyVideoFrame) * timeBase * 1000);
            frame.duration += (int64_t)(videoDecoder->mvyVideoFrame->repeat_pict * timeBase * 0.5);
            frame.length = videoDuration;
            
            frame.Y_Data = videoDecoder->mvyVideoFrame->data[0];
            frame.U_Data = videoDecoder->mvyVideoFrame->data[1];
            frame.V_Data = videoDecoder->mvyVideoFrame->data[2];
            
            frame.isKeyFrame = videoDecoder->mvyVideoFrame->key_frame;
            
            if (frame.pts < 30) {
                std::ostringstream ss;
                ss << "frame info width : " << frame.width << " height : " << frame.height;
                ss << " lineSize : " << frame.lineSize;
                ss << " rotate : " << frame.rotate;
                ss << " pts : " << frame.pts << " duration : " << frame.duration;
                ss << " length : " << frame.length;
                ss << " isKeyFrame : " << frame.isKeyFrame;
                NSLog(@"%s %s", TAG, ss.str().data());
            }
            
            std::ostringstream ss;
            ss << "pts : " << frame.pts << " duration : " << frame.duration;
            ss << " length : " << frame.length;
            ss << " isKeyFrame : " << frame.isKeyFrame;
            NSLog(@"%s %s", TAG, ss.str().data());
            
            result.push_back(frame);
            
            break;
        } else {
            NSLog(@"%s %s", TAG, "did not get video, read next packet\n");
            if (videoDecoder->eos) {
                NSLog(@"%s %s", TAG, "no frames in decoder\n");
                videoDecoder->no_decoded_frame = 1;
                
                break;
            }
        }
    }
    
    if(packet.data != NULL)
        av_free_packet(&packet);
    
    return result;
}

// 跳转到后一个I帧
static void backwardSeekTo2(VideoDecoder* videoDecoder, int frameIndex) {
    if (videoDecoder->mvyVideoStream != -1) {
        av_seek_frame(videoDecoder->mvyFormatContext, videoDecoder->mvyVideoStream, frameIndex, AVSEEK_FLAG_BACKWARD | AVSEEK_FLAG_FRAME);
        avcodec_flush_buffers(videoDecoder->mvyCodecContext);
        clearStatus(videoDecoder);
    }
}

// 跳转到后一个I帧
static void backwardSeekTo(VideoDecoder* videoDecoder, int64_t millisecond) {
    if (videoDecoder->mvyVideoStream != -1) {
        double timeBase = av_q2d(videoDecoder->mvyFormatContext->streams[videoDecoder->mvyVideoStream]->time_base);
        int64_t ts = (int64_t)(millisecond / 1000.f / timeBase);
        av_seek_frame(videoDecoder->mvyFormatContext, videoDecoder->mvyVideoStream, ts, AVSEEK_FLAG_BACKWARD);
        avcodec_flush_buffers(videoDecoder->mvyCodecContext);
        clearStatus(videoDecoder);
    }
}

static int64_t getVideoLength(VideoDecoder* videoDecoder) {
    if (videoDecoder->mvyVideoStream != -1) {
        double timeBase = av_q2d(videoDecoder->mvyFormatContext->streams[videoDecoder->mvyVideoStream]->time_base);
        int64_t videoDuration = (int64_t)(videoDecoder->mvyFormatContext->streams[videoDecoder->mvyVideoStream]->duration * timeBase * 1000);
        return videoDuration;
    } else {
        return 0;
    }
}

@implementation ffmpeg_videodecoder

+ (void)registerFFmpeg {
    av_register_all();
    
    // 打印FFmpeg编解码器基本信息
    char *info = (char *)malloc(4000);
    
    AVCodec *c_temp = av_codec_next(NULL);
    
    while (c_temp != NULL) {
        memset(info, 0, 4000);
        
        if (c_temp->decode != NULL) {
            strcat(info, "[Decode]");
        } else {
            strcat(info, "[Encode]");
        }
        switch (c_temp->type) {
                case AVMEDIA_TYPE_VIDEO:
                strcat(info, "[Video]");
                break;
                case AVMEDIA_TYPE_AUDIO:
                strcat(info, "[Audio]");
                break;
            default:
                strcat(info, "[Other]");
                break;
        }
        
        sprintf(info, "%s %10s\n", info, c_temp->name);
        
        NSLog(@"%s %s", TAG, info);
        
        c_temp = c_temp->next;
    }
    
    free(info);
}

+ (long)initVideoDecoder {
    return reinterpret_cast<long>(initVideoDecoder());
}

+ (void)deinitVideoDecoder:(long)instance {
    if (instance) {
        VideoDecoder *videoDecoder = reinterpret_cast<VideoDecoder *>(instance);
        deinitVideoDecoder(videoDecoder);
    }
}

+ (bool)openFile:(long)instance path:(const char *)path fileName:(const char *)fileName {
    if (instance) {
        VideoDecoder *videoDecoder = reinterpret_cast<VideoDecoder *>(instance);
        
        MVY::MovieError errCode = openFile(videoDecoder, path, fileName);
        
        if (errCode == MVY::MovieErrorNone) {
            
            errCode = openVideoStream(videoDecoder);
            
            if (errCode != MVY::MovieErrorNone) {
                closeVideoStream(videoDecoder);
                closeFile(videoDecoder);
                
                return false;
            }
        } else {
            closeFile(videoDecoder);
            
            return false;
        }
    }

    return true;
}

+ (NSArray<MVYVideoFrame *> *)decodeAFrame:(long)instance {
    
    VideoDecoder *videoDecoder = reinterpret_cast<VideoDecoder *>(instance);
    
    int index = 0;
    std::vector<VideoFrame> frames = decodeAFrame(videoDecoder);
    
    NSMutableArray<MVYVideoFrame *> *videoFrames = [[NSMutableArray alloc] init];
    
    for (auto frame : frames) {
        
        MVYVideoFrame *videoFrame = [[MVYVideoFrame alloc] init];
        
        videoFrame.width = frame.width;
        videoFrame.height = frame.height;
        videoFrame.lineSize = frame.lineSize;
        videoFrame.rotate = frame.rotate;
        videoFrame.pts = frame.pts;
        videoFrame.duration = frame.duration;
        videoFrame.length = frame.length;
        
        videoFrame.yData = [[NSData alloc] initWithBytes:frame.Y_Data length:frame.lineSize * frame.height];
        videoFrame.uData = [[NSData alloc] initWithBytes:frame.U_Data length:frame.lineSize * frame.height / 4];
        videoFrame.vData = [[NSData alloc] initWithBytes:frame.V_Data length:frame.lineSize * frame.height / 4];
        
        videoFrame.isKeyFrame = frame.isKeyFrame;
        
        [videoFrames addObject:videoFrame];

        ++index;
    }
    
    return videoFrames;
}

+ (void)backwardSeekTo:(long)instance frameIndex:(int)frameIndex {
    if (instance) {
        VideoDecoder *videoDecoder = reinterpret_cast<VideoDecoder *>(instance);
        backwardSeekTo2(videoDecoder, frameIndex);
    }
}

+ (void)backwardSeekTo:(long)instance millisecond:(int64_t)millisecond {
    if (instance) {
        VideoDecoder *videoDecoder = reinterpret_cast<VideoDecoder *>(instance);
        backwardSeekTo(videoDecoder, millisecond);
    }
}

+ (int64_t)getVideoLength:(long)instance {
    if (instance) {
        VideoDecoder *videoDecoder = reinterpret_cast<VideoDecoder *>(instance);
        return getVideoLength(videoDecoder);
    } else {
        return 0;
    }
}

+ (void)closeFile:(long)instance {
    if (instance) {
        VideoDecoder *videoDecoder = reinterpret_cast<VideoDecoder *>(instance);
        
        closeVideoStream(videoDecoder);
        closeFile(videoDecoder);
    }
}

@end
