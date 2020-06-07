//
//  MVYGPUImageBGRADataOutput.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/4/16.
//  Copyright © 2019年 myvideoyun. All rights reserved.
//

#import "MVYGPUImageBGRADataOutput.h"

#import "MVYGLProgram.h"
#import "MVYGPUImageFramebuffer.h"

@interface MVYGPUImageBGRADataOutput (){
    MVYGPUImageFramebuffer *firstInputFramebuffer;
    
    MVYGLProgram *dataProgram;
    GLint dataPositionAttribute, dataTextureCoordinateAttribute;
    GLint dataInputTextureUniform;
    
    MVYGPUImageFramebuffer *outputFramebuffer;
}

@property (nonatomic, weak) MVYGPUImageContext *context;
@property (nonatomic, assign) CGSize inputSize;

@property (nonatomic, assign) CVPixelBufferRef outputPixelBuffer;
@property (nonatomic, assign) void *outputData;
@property (nonatomic, assign) int outputWidth;
@property (nonatomic, assign) int outputHeight;
@end

@implementation MVYGPUImageBGRADataOutput

- (instancetype)initWithContext:(MVYGPUImageContext *)context
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _context = context;
    
    runMVYSynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        self->dataProgram = [context programForVertexShaderString:kMVYGPUImageVertexShaderString fragmentShaderString:kMVYGPUImagePassthroughFragmentShaderString];
        
        if (!self->dataProgram.initialized)
        {
            if (![self->dataProgram link])
            {
                NSString *progLog = [self->dataProgram programLog];
                NSLog(@"Program link log: %@", progLog);
                NSString *fragLog = [self->dataProgram fragmentShaderLog];
                NSLog(@"Fragment shader compile log: %@", fragLog);
                NSString *vertLog = [self->dataProgram vertexShaderLog];
                NSLog(@"Vertex shader compile log: %@", vertLog);
                self->dataProgram = nil;
            }
        }
        
        self->dataPositionAttribute = [self->dataProgram attributeIndex:@"position"];
        self->dataTextureCoordinateAttribute = [self->dataProgram attributeIndex:@"inputTextureCoordinate"];
        self->dataInputTextureUniform = [self->dataProgram uniformIndex:@"inputImageTexture"];
    });
    
    return self;
}

// Raw格式的导出和导入此转换函数不一样
- (void)setRotateMode:(MVYGPUImageRotationMode)rotateMode {
    switch (rotateMode) {
        case kMVYGPUImageNoRotation:
            _rotateMode = kMVYGPUImageFlipVertical;
            break;
        case kMVYGPUImageRotateLeft:
            _rotateMode = kMVYGPUImageRotateRightFlipVertical;
            break;
        case kMVYGPUImageRotateRight:
            _rotateMode = kMVYGPUImageRotateRightFlipHorizontal;
            break;
        case kMVYGPUImageRotate180:
            _rotateMode = kMVYGPUImageFlipHorizonal;
            break;
        case kMVYGPUImageFlipVertical:
            _rotateMode = kMVYGPUImageNoRotation;
            break;
        case kMVYGPUImageRotateRightFlipHorizontal:
            _rotateMode = kMVYGPUImageRotateRight;
            break;
        case kMVYGPUImageRotateRightFlipVertical:
            _rotateMode = kMVYGPUImageRotateLeft;
            break;
        case kMVYGPUImageFlipHorizonal:
            _rotateMode = kMVYGPUImageRotate180;
            break;
    }
}

#pragma mark -
#pragma mark Data access

- (void)renderAtInternalSize;
{
    [self.context useAsCurrentContext];
    [dataProgram use];
    
    outputFramebuffer = [[self.context framebufferCache] fetchFramebufferForSize:CGSizeMake(self.outputWidth, self.outputHeight) missCVPixelBuffer:NO];
    [outputFramebuffer activateFramebuffer];
    
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
        
    glActiveTexture(GL_TEXTURE4);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(dataInputTextureUniform, 4);
    
    glVertexAttribPointer(dataPositionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);
    glVertexAttribPointer(dataTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [MVYGPUImageFilter textureCoordinatesForRotation:self.rotateMode]);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glFinish();
    
    [firstInputFramebuffer unlock];
    
    //导出数据
    if (self.outputPixelBuffer) {
        CVPixelBufferLockBaseAddress(self.outputPixelBuffer, 0);
        uint8_t *targetBuffer = CVPixelBufferGetBaseAddress(self.outputPixelBuffer);
        GLubyte *outputBuffer = outputFramebuffer.byteBuffer;
        memcpy(targetBuffer, outputBuffer, self.outputWidth * self.outputHeight * 4);
        CVPixelBufferUnlockBaseAddress(self.outputPixelBuffer, 0);
    }else if (self.outputData) {
        GLubyte *outputBuffer = outputFramebuffer.byteBuffer;
        memcpy(self.outputData, outputBuffer, self.outputWidth * self.outputHeight * 4);
    }
    
    [outputFramebuffer unlock];
}

- (void)setOutputWithBGRAData:(void *)bgraData width:(int)width height:(int)height{
    self.outputPixelBuffer = NULL;
    
    self.outputData = bgraData;
    
    self.outputWidth = width;
    self.outputHeight = height;
}

- (void)setOutputWithBGRAPixelBuffer:(CVPixelBufferRef)pixelBuffer{
    self.outputData = NULL;
    
    self.outputPixelBuffer = pixelBuffer;
    
    int bytesPerRow = (int) CVPixelBufferGetBytesPerRow(pixelBuffer);
    self.outputWidth = bytesPerRow / 4;
    self.outputHeight = (int)CVPixelBufferGetHeight(pixelBuffer);
}

#pragma mark -
#pragma mark GPUImageInput protocol

- (void)setInputSize:(CGSize)newSize;
{
    
}

- (void)setInputFramebuffer:(MVYGPUImageFramebuffer *)newInputFramebuffer;
{
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
}

- (void)newFrameReady;
{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        [self renderAtInternalSize];
    });
}

@end
