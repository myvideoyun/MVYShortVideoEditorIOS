//
//  MVYImageEffectHandler.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/7/1.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYImageEffectHandler.h"
#import "MVYGPUImageTextureTransitionInput.h"
#import "MVYGPUImageBGRADataOutput.h"

@interface MVYImageEffectHandler () {
    GLuint bindingFrameBuffer;
    GLuint bindingRenderBuffer;
    GLuint viewPoint[4];
    NSMutableArray<NSNumber *>* vertexAttribEnableArray;
    NSInteger vertexAttribEnableArraySize;
}

@property (nonatomic, strong) MVYGPUImageContext *glContext;
@property (nonatomic, strong) MVYGPUImageTextureTransitionInput *textureInput;
@property (nonatomic, strong) MVYGPUImageBGRADataOutput *bgraDataOutput;

@property (nonatomic, assign) BOOL initCommonProcess;
@property (nonatomic, assign) BOOL initProcess;

@end

@implementation MVYImageEffectHandler

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
        
        _textureInput = [[MVYGPUImageTextureTransitionInput alloc] initWithContext:_glContext];
        
        _bgraDataOutput = [[MVYGPUImageBGRADataOutput alloc] initWithContext:_glContext];
    }
    return self;
}

- (void)setRenderTextures:(NSArray<MVYGPUImageTextureModel *> *)renderTextures {
    _textureInput.renderTextures = renderTextures;
}

- (void)processWithWidth:(int)width height:(int)height rotateMode:(MVYGPUImageRotationMode)rotateMode bgraBuffer:(void *)bgraBuffer {
    
    [self saveOpenGLState];
    
    if (!self.initProcess) {
        [self.textureInput addTarget:self.bgraDataOutput];
        self.initProcess = YES;
    }
    
    self.bgraDataOutput.rotateMode = rotateMode;
    [self.bgraDataOutput setOutputWithBGRAData:bgraBuffer width:width height:height];
    
    // 设置输入的Filter, 同时开始处理YUV数据
    if ([MVYGPUImageFilter needExchangeWidthAndHeightWithRotation:rotateMode]){
        [self.textureInput processWithWidth:height height:width];
    } else {
        [self.textureInput processWithWidth:width height:height];
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
    _textureInput = nil;
    _bgraDataOutput = nil;
    
    _glContext = nil;
}

- (void)dealloc{
    [self destroy];
}

@end
