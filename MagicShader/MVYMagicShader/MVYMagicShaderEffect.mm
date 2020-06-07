//
//  MVYMagicShaderEffect.m
//  MVYMagicShader
//
//  Created by myvideoyun on 2019/5/26.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYMagicShaderEffect.h"
#import "mvy_magicshader.h"

@interface MVYMagicShaderEffect () {
    void *render;
    
    int type;
    
    BOOL initGL;
    
    BOOL initFourScreen;
    BOOL initThreeScreen;
    
    BOOL needReset;
}

@end

@implementation MVYMagicShaderEffect

- (instancetype)initWithType:(int)type
{
    self = [super init];
    if (self) {
        self->type = (int)type;
    }
    return self;
}

- (void)initGLResource {
    render = MVY_MagicShader_CreateShader(type);
    
    if (13 == type) {
        [self setFloatValue:-1 forKey:@"SubWindow"];
        [self setFloatValue:1 forKey:@"DrawGray"];
        
        initFourScreen = true;
        
    } else if (14 == type) {
        [self setFloatValue:-1 forKey:@"SubWindow"];
        [self setFloatValue:1 forKey:@"DrawGray"];
        
        initThreeScreen = true;
    }
}

- (void)releaseGLResource {
    if (render != nil) {
        MVY_MagicShader_DeinitGL(render);
        MVY_MagicShader_ReleaseShader(render);
    }
}

- (void)setFloatValue:(float)value forKey:(NSString *)key {
    if (render != nil) {
        MVY_MagicShader_SetParam(render, key.UTF8String, &value);
    }
}

- (void)processWithTexture:(int)texture width:(int)width height:(int)height {
    if (render != nil) {
        if (!initGL) {
            MVY_MagicShader_InitGL(render);
            
            initGL = true;
        }
        
        if (needReset) {
            if (13 == type) {
                [self setFloatValue:-1 forKey:@"SubWindow"];
                [self setFloatValue:1 forKey:@"DrawGray"];
                
                initFourScreen = true;
                
            } else if (14 == type) {
                [self setFloatValue:-1 forKey:@"SubWindow"];
                [self setFloatValue:1 forKey:@"DrawGray"];
                
                initThreeScreen = true;
            }
            
            needReset = false;
        }
        
        MVY_MagicShader_Draw(render, texture, width, height);
        
        if (initFourScreen) {
            [self setFloatValue:0 forKey:@"SubWindow"];
            [self setFloatValue:0 forKey:@"DrawGray"];
            
            initFourScreen = false;
        }
        
        if (initThreeScreen) {
            [self setFloatValue:0 forKey:@"SubWindow"];
            [self setFloatValue:0 forKey:@"DrawGray"];
            
            initThreeScreen = false;
        }
    }
}

- (void)reset {
    needReset = true;
}

@end
