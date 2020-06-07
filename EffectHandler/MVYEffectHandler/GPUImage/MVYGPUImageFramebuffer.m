//
//  MVYGPUImageFramebuffer.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageFramebuffer.h"

#import "MVYGPUImageOutput.h"

@interface MVYGPUImageFramebuffer()
{
    GLuint framebuffer;
    CVPixelBufferRef renderTarget;
    CVOpenGLESTextureRef renderTexture;
    NSUInteger readLockCount;
}

- (void)generateFramebuffer;
- (void)generateTexture;
- (void)destroyFramebuffer;

@end

@implementation MVYGPUImageFramebuffer

@synthesize size = _size;
@synthesize textureOptions = _textureOptions;
@synthesize texture = _texture;
@synthesize missCVPixelBuffer = _missCVPixelBuffer;
@synthesize framebufferReferenceCount = _framebufferReferenceCount;

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(MVYGPUImageContext *)context size:(CGSize)framebufferSize textureOptions:(MVYGPUTextureOptions)fboTextureOptions missCVPixelBuffer:(BOOL)missCVPixelBuffer;
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    _textureOptions = fboTextureOptions;
    _size = framebufferSize;
    _framebufferReferenceCount = 0;
    _missCVPixelBuffer = missCVPixelBuffer;
    self.context = context;
    
    [self generateFramebuffer];
    
    NSLog(@"Aiya 创建一个 OpenGL frameBuffer %d",framebuffer);
    
    return self;
}

- (void)dealloc
{
    NSLog(@"Aiya 销毁一个 OpenGL frameBuffer %d",framebuffer);
    
    [self destroyFramebuffer];
}

#pragma mark -
#pragma mark Internal

- (void)generateTexture;
{
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
    // This is necessary for non-power-of-two textures
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
    
    // TODO: Handle mipmaps
}

- (void)generateFramebuffer;
{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        glGenFramebuffers(1, &(self->framebuffer));
        glBindFramebuffer(GL_FRAMEBUFFER, self->framebuffer);
        
        // By default, all framebuffers on iOS 5.0+ devices are backed by texture caches, using one shared cache
        if (!self->_missCVPixelBuffer)
        {
            CVOpenGLESTextureCacheRef coreVideoTextureCache = [self.context coreVideoTextureCache];
            // Code originally sourced from http://allmybrain.com/2011/12/08/rendering-to-a-texture-with-ios-5-texture-cache-api/
            
            CFDictionaryRef empty; // empty value for attr value.
            CFMutableDictionaryRef attrs;
            empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
            attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
            
            CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)self->_size.width, (int)self->_size.height, kCVPixelFormatType_32BGRA, attrs, &(self->renderTarget));
            if (err)
            {
                NSLog(@"FBO size: %f, %f", self->_size.width, self->_size.height);
                NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
            }
            
            err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, coreVideoTextureCache, self->renderTarget,
                                                                NULL, // texture attributes
                                                                GL_TEXTURE_2D,
                                                                self->_textureOptions.internalFormat, // opengl format
                                                                (int)self->_size.width,
                                                                (int)self->_size.height,
                                                                self->_textureOptions.format, // native iOS format
                                                                self->_textureOptions.type,
                                                                0,
                                                                &(self->renderTexture));
            if (err)
            {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            CFRelease(attrs);
            CFRelease(empty);
            
            glBindTexture(CVOpenGLESTextureGetTarget(self->renderTexture), CVOpenGLESTextureGetName(self->renderTexture));
            self->_texture = CVOpenGLESTextureGetName(self->renderTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self->_textureOptions.wrapS);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self->_textureOptions.wrapT);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(self->renderTexture), 0);
        }
        else
        {
            [self generateTexture];
            
            glBindTexture(GL_TEXTURE_2D, self->_texture);
            
            glTexImage2D(GL_TEXTURE_2D, 0, self->_textureOptions.internalFormat, (int)self->_size.width, (int)self->_size.height, 0, self->_textureOptions.format, self->_textureOptions.type, 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self->_texture, 0);
        }
        
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyFramebuffer;
{
    runMVYSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        
        if (self->framebuffer)
        {
            glDeleteFramebuffers(1, &(self->framebuffer));
            self->framebuffer = 0;
        }
        
        if (!self->_missCVPixelBuffer)
        {
            if (self->renderTarget)
            {
                CFRelease(self->renderTarget);
                self->renderTarget = NULL;
            }
            
            if (self->renderTexture)
            {
                CFRelease(self->renderTexture);
                self->renderTexture = NULL;
            }
        }
        else
        {
            glDeleteTextures(1, &(self->_texture));
        }
        
    });
}

#pragma mark -
#pragma mark Usage

- (void)activateFramebuffer;
{
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, (int)_size.width, (int)_size.height);
}

#pragma mark -
#pragma mark Reference counting

- (void)lock;
{
    _framebufferReferenceCount++;
}

- (void)unlock;
{
    NSAssert(_framebufferReferenceCount > 0, @"Tried to overrelease a framebuffer, did you forget to call -useNextFrameForImageCapture before using -imageFromCurrentFramebuffer?");
    
    _framebufferReferenceCount--;
    if (_framebufferReferenceCount < 1)
    {
        
        [self.context.framebufferCache returnFramebufferToCache:self];
    }
    
}

- (void)clearAllLocks;
{
    _framebufferReferenceCount = 0;
}

#pragma mark -
#pragma mark Raw data bytes

- (void)lockForReading
{
//    if ([MVYGPUImageContext supportsFastTextureUpload])
//    {
        if (readLockCount == 0)
        {
            CVPixelBufferLockBaseAddress(renderTarget, 0);
        }
        readLockCount++;
//    }
}

- (void)unlockAfterReading
{
//    if ([MVYGPUImageContext supportsFastTextureUpload])
//    {
        NSAssert(readLockCount > 0, @"Unbalanced call to -[MVYGPUImageFramebuffer unlockAfterReading]");
        readLockCount--;
        if (readLockCount == 0)
        {
            CVPixelBufferUnlockBaseAddress(renderTarget, 0);
        }
//    }
}

- (NSUInteger)bytesPerRow;
{
//    if ([MVYGPUImageContext supportsFastTextureUpload])
//    {
        return CVPixelBufferGetBytesPerRow(renderTarget);
//    }
//    else
//    {
//        return _size.width * 4;
//    }
}

- (GLubyte *)byteBuffer;
{
    [self lockForReading];
    GLubyte * bufferBytes = CVPixelBufferGetBaseAddress(renderTarget);
    [self unlockAfterReading];
    return bufferBytes;
}

- (CVPixelBufferRef )pixelBuffer;
{
    return renderTarget;
}

- (GLuint)texture;
{
    return _texture;
}

- (UIImage *)image{
    
    CVPixelBufferLockBaseAddress(renderTarget, 0);
    
    //从 CVImageBufferRef 取得影像的细部信息
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(renderTarget);
    width = CVPixelBufferGetWidth(renderTarget);
    height = CVPixelBufferGetHeight(renderTarget);
    bytesPerRow = CVPixelBufferGetBytesPerRow(renderTarget);
    
    //利用取得影像细部信息格式化 CGContextRef
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    //透过 CGImageRef 将 CGContextRef 转换成 UIImage
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(renderTarget, 0);
    
    //成功转换成 UIImage
    return image;
}

@end
