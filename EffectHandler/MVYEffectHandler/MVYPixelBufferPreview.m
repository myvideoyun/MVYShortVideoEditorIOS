//
//  MVYPreview.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYPixelBufferPreview.h"

static const NSString * kVertexShaderString = @""
"  attribute vec4 position;\n"
"  attribute vec2 inputTextureCoordinate;\n"
"  varying mediump vec2 v_texCoord;\n"
"  \n"
"  void main()\n"
"  {\n"
"    gl_Position = position;\n"
"    v_texCoord = inputTextureCoordinate;\n"
"  }\n";

static const NSString *kFragmentShaderString = @""
"  precision lowp float;\n"
"  uniform sampler2D u_texture;\n"
"  varying highp vec2 v_texCoord;\n"
"  \n"
"  void main()\n"
"  {\n"
"    gl_FragColor = texture2D(u_texture, v_texCoord);\n"
"  }\n";

@interface MVYPixelBufferPreview () {
    dispatch_queue_t queue;
    
    CAEAGLLayer *eaglLayer;
    
    EAGLContext *glContext;
    
    GLuint renderBuffer, frameBuffer;
    GLint backingWidth, backingHeight;
    GLuint program;
    GLint positionAttribute, textureCoordinateAttribute;
    GLint inputTextureUniform;

    GLuint texture;
}
@end

@implementation MVYPixelBufferPreview

+ (Class)layerClass{
    return [CAEAGLLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([self respondsToSelector:@selector(setContentScaleFactor:)]){
            self.contentScaleFactor = [[UIScreen mainScreen] scale];
        }
        
        self.opaque = YES;
        self.hidden = NO;
        eaglLayer = (CAEAGLLayer *)self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    
        queue = dispatch_queue_create("com.myvideoyun.textureview", nil);
        
        glContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        dispatch_sync(queue, ^{
            [EAGLContext setCurrentContext:self->glContext];
            
            [self createProgram];
            
            [self createDisplayRenderBuffer];
        });
        
        _previewRotationMode = kMVYPreviewNoRotation;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self destroyDisplayFramebuffer];
}

- (void)setPreviewRotationMode:(MVYPreviewRotationMode)previewRotationMode {
    switch (previewRotationMode) {
        case kMVYPreviewNoRotation:
            _previewRotationMode = kMVYPreviewFlipVertical;
            break;
        case kMVYPreviewRotateLeft:
            _previewRotationMode = kMVYPreviewRotateRightFlipHorizontal;
            break;
        case kMVYPreviewRotateRight:
            _previewRotationMode = kMVYPreviewRotateRightFlipVertical;
            break;
        case kMVYPreviewRotate180:
            _previewRotationMode = kMVYPreviewFlipHorizonal;
            break;
        case kMVYPreviewFlipVertical:
            _previewRotationMode = kMVYPreviewNoRotation;
            break;
        case kMVYPreviewRotateRightFlipHorizontal:
            _previewRotationMode = kMVYPreviewRotateLeft;
            break;
        case kMVYPreviewRotateRightFlipVertical:
            _previewRotationMode = kMVYPreviewRotateRight;
            break;
        case kMVYPreviewFlipHorizonal:
            _previewRotationMode = kMVYPreviewRotate180;
            break;
    }
}

- (void)render:(CVPixelBufferRef)pixelBuffer {
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int lineSize = (int)CVPixelBufferGetBytesPerRow(pixelBuffer) / 4;
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    void *bgraData = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    [self renderWithBgraData:bgraData width:width height:height lineSize:lineSize];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
}

- (void)renderWithBgraData:(void *)bgraData width:(int)width height:(int)height lineSize:(int)lineSize {

    dispatch_sync(queue, ^{
        [EAGLContext setCurrentContext:self->glContext];
        
        int outputWidth = width;
        int outputHeight = height;
        
        if ([MVYPixelBufferPreview needExchangeWidthAndHeightWithPreviewRotation:self.previewRotationMode]) {
            int temp = outputWidth;
            outputWidth = outputHeight;
            outputHeight = temp;
        }
        
        // 创建Program
        if (!self->program) {
            [self createProgram];
        }
        
        // 创建显示时的RenderBuffer
        if (!self->renderBuffer) {
            [self createDisplayRenderBuffer];
        }
        
        // 创建纹理
        if (!self->texture) {
            glGenTextures(1, &self->texture);
            glBindTexture(GL_TEXTURE_2D, self->texture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        }
        
        glBindFramebuffer(GL_FRAMEBUFFER, self->frameBuffer);

        glViewport(0, 0, self->backingWidth, self->backingHeight);

        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        glUseProgram(self->program);

        glActiveTexture(GL_TEXTURE1);

        glBindTexture(GL_TEXTURE_2D, self->texture);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, lineSize, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, bgraData);

        glUniform1i(self->inputTextureUniform, 1);

        CGFloat heightScaling, widthScaling;

        CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(outputWidth, outputHeight), CGRectMake(0, 0, self->backingWidth, self->backingHeight));
        switch (self.previewContentMode) {
            case MVYPreivewContentModeScaleToFill: // 填充
                widthScaling = 1.0;
                heightScaling = 1.0;
                break;

            case MVYPreivewContentModeScaleAspectFit: //保持宽高比
                widthScaling = insetRect.size.width / self->backingWidth;
                heightScaling = insetRect.size.height / self->backingHeight;
                break;

            case MVYPreivewContentModeScaleAspectFill: //保持宽高比同时填满整个屏幕
                widthScaling = self->backingHeight / insetRect.size.height;
                heightScaling = self->backingWidth / insetRect.size.width;
                break;
        }

        GLfloat squareVertices[8];
        squareVertices[0] = -widthScaling;
        squareVertices[1] = -heightScaling;
        squareVertices[2] = widthScaling;
        squareVertices[3] = -heightScaling;
        squareVertices[4] = -widthScaling;
        squareVertices[5] = heightScaling;
        squareVertices[6] = widthScaling;
        squareVertices[7] = heightScaling;

        glVertexAttribPointer(self->positionAttribute, 2, GL_FLOAT, 0, 0, squareVertices);

        const GLfloat *textureCoordinates = [MVYPixelBufferPreview textureCoordinatesForRotation:self.previewRotationMode];
        
        // 处理lineSize != width
        GLfloat coordinates[8];
        for (int x = 0; x < 8; x++) {
            if (x % 2 == 0 && textureCoordinates[x] == 1) {
                coordinates[x] = (float)width / (float)lineSize;
            } else {
                coordinates[x] = textureCoordinates[x];
            }
        }

        glVertexAttribPointer(self->textureCoordinateAttribute, 2, GL_FLOAT, 0, 0, coordinates);

        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        
        glBindRenderbuffer(GL_RENDERBUFFER, self->renderBuffer);
        
        [self->glContext presentRenderbuffer:GL_RENDERBUFFER];
    });
}

- (void)createProgram {
    program = [MVYPixelBufferPreview createProgramWithVert:kVertexShaderString frag:kFragmentShaderString];
    positionAttribute = glGetAttribLocation(program, [@"position" UTF8String]);
    textureCoordinateAttribute = glGetAttribLocation(program, [@"inputTextureCoordinate" UTF8String]);
    inputTextureUniform = glGetUniformLocation(program, [@"u_texture" UTF8String]);
    
    glEnableVertexAttribArray(self->positionAttribute);
    glEnableVertexAttribArray(self->textureCoordinateAttribute);
}

- (void)destroyProgram {
    if (program) {
        glDeleteProgram(program);
        program = 0;
    }
}

- (void)createDisplayRenderBuffer {
    glGenFramebuffers(1, &frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, frameBuffer);

    glGenRenderbuffers(1, &renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderBuffer);

    [self->glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
    
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);

    if ((backingWidth == 0) || (backingHeight == 0)) {
        [self destroyDisplayFramebuffer];
        return;
    }

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderBuffer);
}

- (void)destroyDisplayFramebuffer {
    if (frameBuffer) {
        glDeleteFramebuffers(1, &frameBuffer);
        frameBuffer = 0;
    }

    if (renderBuffer) {
        glDeleteRenderbuffers(1, &renderBuffer);
        renderBuffer = 0;
    }
}

- (void)releaseGLResources {
    dispatch_sync(queue, ^{
        [EAGLContext setCurrentContext:self->glContext];
        
        [self destroyProgram];
        [self destroyDisplayFramebuffer];
    });
    
}

- (void)dealloc{
    [self releaseGLResources];
}

@end



@implementation MVYPixelBufferPreview (OpenGLHelper)

// 编译 shader
+ (GLuint)createProgramWithVert:(const NSString *)vShaderString frag:(const NSString *)fShaderString {
    
    GLuint program = glCreateProgram();
    GLuint vertShader = 0, fragShader = 0;
    if (![self compileShader:&vertShader
                        type:GL_VERTEX_SHADER
                      string:vShaderString]){
        NSLog(@"Failed to compile vertex shader");
    }
    
    if (![self compileShader:&fragShader
                        type:GL_FRAGMENT_SHADER
                      string:fShaderString]){
        NSLog(@"Failed to compile fragment shader");
    }
    
    glAttachShader(program, vertShader);
    glAttachShader(program, fragShader);
    
    
    GLint status;
    
    glLinkProgram(program);
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
        NSLog(@"Failed to link shader");
    
    if (vertShader)
    {
        glDeleteShader(vertShader);
        vertShader = 0;
    }
    if (fragShader)
    {
        glDeleteShader(fragShader);
        fragShader = 0;
    }
    
    return program;
}

+ (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(const NSString *)shaderString {
    
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[shaderString UTF8String];
    if (!source){
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status != GL_TRUE) {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0){
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            NSLog(@"Failed to compile shader %s", log);
            free(log);
        }
    }
    
    return status == GL_TRUE;
}

+ (const GLfloat *)textureCoordinatesForRotation:(MVYPreviewRotationMode)rotationMode {
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };
    
    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };
    
    switch(rotationMode)
    {
        case kMVYPreviewNoRotation: return noRotationTextureCoordinates;
        case kMVYPreviewRotateLeft: return rotateLeftTextureCoordinates;
        case kMVYPreviewRotateRight: return rotateRightTextureCoordinates;
        case kMVYPreviewFlipVertical: return verticalFlipTextureCoordinates;
        case kMVYPreviewFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kMVYPreviewRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kMVYPreviewRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kMVYPreviewRotate180: return rotate180TextureCoordinates;
    }
}

+ (BOOL)needExchangeWidthAndHeightWithPreviewRotation:(MVYPreviewRotationMode)rotationMode {
    switch(rotationMode)
    {
        case kMVYPreviewNoRotation: return NO;
        case kMVYPreviewRotateLeft: return YES;
        case kMVYPreviewRotateRight: return YES;
        case kMVYPreviewFlipVertical: return NO;
        case kMVYPreviewFlipHorizonal: return NO;
        case kMVYPreviewRotateRightFlipVertical: return YES;
        case kMVYPreviewRotateRightFlipHorizontal: return YES;
        case kMVYPreviewRotate180: return NO;
    }
}

@end
