//
//  MVYCameraEffectHandler.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYCameraEffectHandler.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/glext.h>

#import "MVYGPUImageBGRADataInput.h"
#import "MVYGPUImageBGRADataOutput.h"

#import "MVYGPUImageLookupFilter.h"
#import "MVYGPUImageBeautyFilter.h"
#import "MVYGPUImageBrightnessFilter.h"
#import "MVYGPUImageSaturationFilter.h"
#import "MVYGPUImageStickerFilter.h"
#import "MVYGPUImageZoomFilter.h"
#import "MVYGPUImageMirrorFilter.h"

@interface MVYCameraEffectHandler () {
    GLint bindingFrameBuffer;
    GLint bindingRenderBuffer;
    GLint viewPoint[4];
    NSMutableArray<NSNumber *>* vertexAttribEnableArray;
    NSInteger vertexAttribEnableArraySize;
}

@property (nonatomic, strong) MVYGPUImageContext *glContext;
@property (nonatomic, strong) MVYGPUImageBGRADataInput *bgraDataInput;
@property (nonatomic, strong) MVYGPUImageBGRADataOutput *bgraDataOutput;

@property (nonatomic, strong) MVYGPUImageFilter *commonInputFilter;
@property (nonatomic, strong) MVYGPUImageFilter *commonOutputFilter;

@property (nonatomic, strong) MVYGPUImageLookupFilter *lookupFilter;
@property (nonatomic, strong) MVYGPUImageBeautyFilter *beautyFilter;
@property (nonatomic, strong) MVYGPUImageBrightnessFilter *brightnessFilter;
@property (nonatomic, strong) MVYGPUImageSaturationFilter *saturationFilter;
@property (nonatomic, strong) MVYGPUImageStickerFilter *stickerFilter;
@property (nonatomic, strong) MVYGPUImageZoomFilter *zoomFilter;
@property (nonatomic, strong) MVYGPUImageMirrorFilter *mirrorFilter;

@property (nonatomic, assign) BOOL initCommonProcess;
@property (nonatomic, assign) BOOL initProcess;

@end

@implementation MVYCameraEffectHandler

- (instancetype)init
{
    @throw [NSException exceptionWithName:@"init Exception" reason:@"use initWithProcessTexture:" userInfo:nil];
}

- (instancetype)initWithProcessTexture:(Boolean)isProcessTexture {
    if (self = [super init]) {
        vertexAttribEnableArraySize = 5;
        vertexAttribEnableArray = [NSMutableArray array];
        
        if (isProcessTexture) {
            _glContext = [[MVYGPUImageContext alloc] initWithCurrentGLContext];
        } else {
            _glContext = [[MVYGPUImageContext alloc] initWithNewGLContext];
        }
        
        _commonInputFilter = [[MVYGPUImageFilter alloc] initWithContext:_glContext];
        _commonOutputFilter = [[MVYGPUImageFilter alloc] initWithContext:_glContext];
        
        _bgraDataInput = [[MVYGPUImageBGRADataInput alloc] initWithContext:_glContext];
        _bgraDataOutput = [[MVYGPUImageBGRADataOutput alloc] initWithContext:_glContext];
        
        _lookupFilter = [[MVYGPUImageLookupFilter alloc] initWithContext:_glContext];
        _beautyFilter = [[MVYGPUImageBeautyFilter alloc] initWithContext:_glContext];
        _brightnessFilter = [[MVYGPUImageBrightnessFilter alloc] initWithContext:_glContext];
        _saturationFilter = [[MVYGPUImageSaturationFilter alloc] initWithContext:_glContext];
        _stickerFilter = [[MVYGPUImageStickerFilter alloc] initWithContext:_glContext];
        _zoomFilter = [[MVYGPUImageZoomFilter alloc] initWithContext:_glContext];
        _mirrorFilter = [[MVYGPUImageMirrorFilter alloc] initWithContext:_glContext];
        
        _rotateMode = kMVYGPUImageNoRotation;
    }
    return self;
}

- (void)setStyle:(UIImage *)style{
    _style = style;
    
    [self.lookupFilter setLookup:style];
}

- (void)setIntensityOfStyle:(CGFloat)intensityOfStyle{
    _intensityOfStyle = intensityOfStyle;
    
    [self.lookupFilter setIntensity:intensityOfStyle];
}

- (void)setIntensityOfBeauty:(CGFloat)intensityOfBeauty {
    _intensityOfBeauty = intensityOfBeauty;
    
    [self.beautyFilter setIntensity:intensityOfBeauty];
}

- (void)setIntensityOfBrightness:(CGFloat)intensityOfBrightness {
    _intensityOfBrightness = intensityOfBrightness;
    
    [self.brightnessFilter setIntensity:intensityOfBrightness];
}

- (void)setIntensityOfSaturation:(CGFloat)intensityOfSaturation {
    _intensityOfSaturation = intensityOfSaturation;
    
    [self.saturationFilter setIntensity:intensityOfSaturation];
}

- (void)setIntensityOfZoom:(CGFloat)intensityOfZoom {
    _intensityOfZoom = intensityOfZoom;
    
    [self.zoomFilter setZoom:intensityOfZoom];
}

- (void)addStickerWithModel:(MVYGPUImageStickerModel *)model {
    [self.stickerFilter addStickerWithModel:model];
}

- (void)removeStickerWithModel:(MVYGPUImageStickerModel *)model {
    [self.stickerFilter removeStickerWithModel:model];
}

- (void)clearSticker {
    [self.stickerFilter clear];
}

- (void)setRotateMode:(MVYGPUImageRotationMode)rotateMode{
    _rotateMode = rotateMode;
    
    self.bgraDataInput.rotateMode = rotateMode;
    
    if (rotateMode == kMVYGPUImageRotateLeft) {
        rotateMode = kMVYGPUImageRotateRight;
    }else if (rotateMode == kMVYGPUImageRotateRight) {
        rotateMode = kMVYGPUImageRotateLeft;
    }
    
    self.bgraDataOutput.rotateMode = rotateMode;
}

- (void)setMirror:(BOOL)mirror {
    _mirror = mirror;
    
    self.mirrorFilter.mirror = mirror;
}

/**
 通用处理
 */
- (void)commonProcess {
    
    NSMutableArray *filterChainArray = [NSMutableArray array];
    
    [filterChainArray addObject:self.mirrorFilter];
    [filterChainArray addObject:self.beautyFilter];
    [filterChainArray addObject:self.brightnessFilter];
    [filterChainArray addObject:self.saturationFilter];
    [filterChainArray addObject:self.lookupFilter];
    [filterChainArray addObject:self.stickerFilter];
    [filterChainArray addObject:self.zoomFilter];
    
    if (!self.initCommonProcess) {
        
        if (filterChainArray.count > 0) {
            [self.commonInputFilter addTarget:[filterChainArray firstObject]];

            for (int x = 0; x < filterChainArray.count - 1; x++) {
                [filterChainArray[x] addTarget:filterChainArray[x+1]];
            }
            
            [[filterChainArray lastObject] addTarget:self.commonOutputFilter];
            
        }else {
            [self.commonInputFilter addTarget:self.commonOutputFilter];
        }
        
        self.initCommonProcess = YES;
    }
}

- (void)processWithPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    
    [self saveOpenGLState];
    
    [self commonProcess];
    
    OSType formatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    
    if (formatType == kCVPixelFormatType_32BGRA) {
        if (!self.initProcess) {
            [self.bgraDataInput addTarget:self.commonInputFilter];
            [self.commonOutputFilter addTarget:self.bgraDataOutput];
            self.initProcess = YES;
        }
        
        // 设置输出的Filter
        [self.bgraDataOutput setOutputWithBGRAPixelBuffer:pixelBuffer];
        
        // 设置输入的Filter, 同时开始处理BGRA数据
        [self.bgraDataInput processWithBGRAPixelBuffer:pixelBuffer];
        
    }
    
    [self restoreOpenGLState];
}


/**
 保存opengl状态
 */
- (void)saveOpenGLState {
    // 获取当前绑定的FrameBuffer
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, (GLint *)&bindingFrameBuffer);
    
    // 获取当前绑定的RenderBuffer
    glGetIntegerv(GL_RENDERBUFFER_BINDING, (GLint *)&bindingRenderBuffer);
    
    // 获取viewpoint
    glGetIntegerv(GL_VIEWPORT, (GLint *)&viewPoint);
    
    // 获取顶点数据
    [vertexAttribEnableArray removeAllObjects];
    for (int x = 0 ; x < vertexAttribEnableArraySize; x++) {
        GLint vertexAttribEnable;
        glGetVertexAttribiv(x, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &vertexAttribEnable);
        if (vertexAttribEnable) {
            [vertexAttribEnableArray addObject:@(x)];
        }
    }
}

/**
 恢复opengl状态
 */
- (void)restoreOpenGLState {
    // 还原当前绑定的FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, bindingFrameBuffer);
    
    // 还原当前绑定的RenderBuffer
    glBindRenderbuffer(GL_RENDERBUFFER, bindingRenderBuffer);
    
    // 还原viewpoint
    glViewport(viewPoint[0], viewPoint[1], viewPoint[2], viewPoint[3]);
    
    // 还原顶点数据
    for (int x = 0 ; x < vertexAttribEnableArray.count; x++) {
        glEnableVertexAttribArray(vertexAttribEnableArray[x].intValue);
    }
}

- (void)destroy{
    
    _bgraDataInput = nil;
    _bgraDataOutput = nil;
    
    _commonInputFilter = nil;
    _commonOutputFilter = nil;
    
    _lookupFilter = nil;
    _beautyFilter = nil;
    _brightnessFilter = nil;
    _saturationFilter = nil;
    _stickerFilter = nil;
    _zoomFilter = nil;
    _mirrorFilter = nil;
    
    _glContext = nil;
}

- (void)dealloc{
    [self destroy];
}

@end
