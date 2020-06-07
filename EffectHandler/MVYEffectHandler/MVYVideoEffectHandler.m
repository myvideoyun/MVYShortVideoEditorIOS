//
//  MVYVideoEffectHandler.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/4/17.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYVideoEffectHandler.h"
#import "MVYGPUImageI420DataInput.h"
#import "MVYGPUImageBGRADataOutput.h"
#import "MVYGPUImageStickerFilter.h"
#import "MVYGPUImageMagicShaderFilter.h"
#import "MVYGPUImageMirrorFilter.h"

@interface MVYVideoEffectHandler () {
    GLuint bindingFrameBuffer;
    GLuint bindingRenderBuffer;
    GLuint viewPoint[4];
    NSMutableArray<NSNumber *>* vertexAttribEnableArray;
    NSInteger vertexAttribEnableArraySize;
}

@property (nonatomic, strong) MVYGPUImageContext *glContext;
@property (nonatomic, strong) MVYGPUImageI420DataInput *i420DataInput;
@property (nonatomic, strong) MVYGPUImageBGRADataOutput *bgraDataOutput;

@property (nonatomic, strong) MVYGPUImageFilter *commonInputFilter;
@property (nonatomic, strong) MVYGPUImageFilter *commonOutputFilter;
@property (nonatomic, strong) MVYGPUImageStickerFilter *stickerFilter;
@property (nonatomic, strong) MVYGPUImageMagicShaderFilter *shortVideoFilter;
@property (nonatomic, strong) MVYGPUImageMirrorFilter *mirrorFilter;

@property (nonatomic, assign) BOOL initCommonProcess;
@property (nonatomic, assign) BOOL initProcess;

@end

@implementation MVYVideoEffectHandler

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
        
        _i420DataInput = [[MVYGPUImageI420DataInput alloc] initWithContext:_glContext];
        
        _bgraDataOutput = [[MVYGPUImageBGRADataOutput alloc] initWithContext:_glContext];
        
        _stickerFilter = [[MVYGPUImageStickerFilter alloc] initWithContext:_glContext];
        
        _shortVideoFilter = [[MVYGPUImageMagicShaderFilter alloc] initWithContext:_glContext];
        
        _mirrorFilter = [[MVYGPUImageMirrorFilter alloc] initWithContext:_glContext];
        
        _rotateMode = kMVYGPUImageNoRotation;
    }
    return self;
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

- (void)setTypeOfMagicShaderEffect:(NSInteger)type {
    self.shortVideoFilter.type = type;
}

- (void)resetMagicShaderEffect {
    [self.shortVideoFilter reset];
}

- (void)setRotateMode:(MVYGPUImageRotationMode)rotateMode{
    _rotateMode = rotateMode;
    
    self.i420DataInput.rotateMode = rotateMode;
    
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
    [filterChainArray addObject:self.stickerFilter];
    [filterChainArray addObject:self.shortVideoFilter];

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

- (void)processWithYBuffer:(NSData *)yBuffer uBuffer:(NSData *)uBuffer vBuffer:(NSData *)vBuffer width:(int)width height:(int)height bgraBuffer:(void *)bgraBuffer {
    
    [self saveOpenGLState];
    
    [self commonProcess];
    
    if (!self.initProcess) {
        [self.i420DataInput addTarget:self.commonInputFilter];
        [self.commonOutputFilter addTarget:self.bgraDataOutput];
        self.initProcess = YES;
    }

    [self.bgraDataOutput setOutputWithBGRAData:bgraBuffer width:width height:height];

    // 设置输入的Filter, 同时开始处理YUV数据
    [self.i420DataInput processWithYData:yBuffer.bytes uData:uBuffer.bytes vData:vBuffer.bytes width:width height:height];
    
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
    _i420DataInput = nil;
    _bgraDataOutput = nil;
    
    _commonInputFilter = nil;
    _commonOutputFilter = nil;
    
    _stickerFilter = nil;
    _shortVideoFilter = nil;
    _mirrorFilter = nil;

    _glContext = nil;
}

- (void)dealloc{
    [self destroy];
}

@end
