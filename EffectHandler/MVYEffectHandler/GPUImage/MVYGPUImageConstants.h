//
//  MVYGPUImageConstants.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#ifndef MVYGPUImageConstants_h
#define MVYGPUImageConstants_h

#import <OpenGLES/ES2/gl.h>
#import <Foundation/Foundation.h>

typedef struct MVYGPUTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} MVYGPUTextureOptions;

typedef struct MVYGPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
} MVYGPUVector4;

typedef struct MVYGPUVector3 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
} MVYGPUVector3;

typedef struct MVYGPUMatrix4x4 {
    MVYGPUVector4 one;
    MVYGPUVector4 two;
    MVYGPUVector4 three;
    MVYGPUVector4 four;
} MVYGPUMatrix4x4;

typedef struct MVYGPUMatrix3x3 {
    MVYGPUVector3 one;
    MVYGPUVector3 two;
    MVYGPUVector3 three;
} MVYGPUMatrix3x3;

typedef NS_ENUM(NSUInteger, MVYGPUImageContentMode) {
    kMVYGPUImageContentModeScaleToFill,
    kMVYGPUImageContentModeScaleAspectFit,
    kMVYGPUImageContentModeScaleAspectFill
};

typedef NS_ENUM(NSUInteger, MVYGPUImageRotationMode) {
    kMVYGPUImageNoRotation,
    kMVYGPUImageRotateLeft,
    kMVYGPUImageRotateRight,
    kMVYGPUImageFlipVertical,
    kMVYGPUImageFlipHorizonal,
    kMVYGPUImageRotateRightFlipVertical,
    kMVYGPUImageRotateRightFlipHorizontal,
    kMVYGPUImageRotate180
};

// BT.601 full range.
extern GLfloat kMVYColorConversion601FullRangeDefault[];

#endif /* MVYGPUImageConstants_h */
