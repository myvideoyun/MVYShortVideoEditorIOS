//
//  MVYGPUImageContext.m
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageContext.h"

#import "MVYGLProgram.h"
#import "MVYGPUImageFramebuffer.h"

#define MAXSHADERPROGRAMSALLOWEDINCACHE 40

dispatch_queue_attr_t MVYGPUImageDefaultQueueAttribute(void)
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)
    {
        return dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    }
    return nil;
}

void runMVYSynchronouslyOnContextQueue(MVYGPUImageContext *context, void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [context contextQueue];
    if (videoProcessingQueue) {
        if (dispatch_get_specific([context contextKey]))
        {
            block();
        }else
        {
            dispatch_sync(videoProcessingQueue, block);
        }
    }else {
        block();
    }
}

@interface MVYGPUImageContext()
{
    NSMutableDictionary *shaderProgramCache;
    EAGLSharegroup *_sharegroup;
    
    BOOL _newGLContext;
}

@end

@implementation MVYGPUImageContext

@synthesize context = _context;
@synthesize contextQueue = _contextQueue;
@synthesize contextKey = _contextKey;
@synthesize coreVideoTextureCache = _coreVideoTextureCache;
@synthesize framebufferCache = _framebufferCache;

static int specificKey;

- (instancetype)init {
    @throw [NSException exceptionWithName:@"init Exception" reason:@"use initWithNewGLContext or initWithCurrentGLContext" userInfo:nil];
}

- (instancetype)initWithNewGLContext;
{
    self = [super init];
    if (self) {
        _contextQueue = dispatch_queue_create("com.myvideoyun.MVYGPUImage", MVYGPUImageDefaultQueueAttribute());
        
        CFStringRef specificValue = CFSTR("MVYGPUImageQueue");
        dispatch_queue_set_specific(_contextQueue,
                                    &specificKey,
                                    (void*)specificValue,
                                    (dispatch_function_t)CFRelease);
        
        shaderProgramCache = [[NSMutableDictionary alloc] init];
        
        dispatch_sync(_contextQueue, ^{
            self->_context = [self createContext];
        });
    }
    return self;
}

- (instancetype)initWithCurrentGLContext
{
    self = [super init];
    if (self) {
        shaderProgramCache = [[NSMutableDictionary alloc] init];
        
        _context = [EAGLContext currentContext];
    }
    return self;
}

- (void *)contextKey {
    return &specificKey;
}

- (void)useAsCurrentContext;
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext)
    {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

- (void)presentBufferForDisplay;
{
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (MVYGLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;
{
    NSString *lookupKeyForShaderProgram = [NSString stringWithFormat:@"V: %@ - F: %@", vertexShaderString, fragmentShaderString];
    MVYGLProgram *programFromCache = [shaderProgramCache objectForKey:lookupKeyForShaderProgram];
    
    if (programFromCache == nil)
    {
        programFromCache = [[MVYGLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        [shaderProgramCache setObject:programFromCache forKey:lookupKeyForShaderProgram];
    }
    
    return programFromCache;
}

- (void)useSharegroup:(EAGLSharegroup *)sharegroup;
{
    NSAssert(_context == nil, @"Unable to use a share group when the context has already been created. Call this method before you use the context for the first time.");
    
    _sharegroup = sharegroup;
}

- (EAGLContext *)createContext;
{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_sharegroup];
    NSAssert(context != nil, @"Unable to create an OpenGL ES 2.0 context. The AYGPUImage framework requires OpenGL ES 2.0 support to work.");
    return context;
}

- (void)dealloc
{
    if (_coreVideoTextureCache)
    {
        CFRelease(_coreVideoTextureCache);
        _coreVideoTextureCache = NULL;
    }
}

#pragma mark -
#pragma mark Accessors

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache;
{
    if (_coreVideoTextureCache == NULL)
    {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);
        
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
        
    }
    
    return _coreVideoTextureCache;
}

- (MVYGPUImageFramebufferCache *)framebufferCache;
{
    if (_framebufferCache == nil)
    {
        _framebufferCache = [[MVYGPUImageFramebufferCache alloc] initWithContext:self];
    }
    
    return _framebufferCache;
}
@end
