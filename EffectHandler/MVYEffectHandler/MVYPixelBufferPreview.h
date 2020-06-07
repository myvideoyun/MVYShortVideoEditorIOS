//
//  MVYPreview.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/gltypes.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/EAGLDrawable.h>
#import <AVKit/AVKit.h>

typedef NS_ENUM(NSUInteger, MVYPreivewContentMode) {
    MVYPreivewContentModeScaleToFill,
    MVYPreivewContentModeScaleAspectFit,
    MVYPreivewContentModeScaleAspectFill
};

typedef NS_ENUM(NSUInteger, MVYPreviewRotationMode) {
    kMVYPreviewNoRotation,
    kMVYPreviewRotateLeft,
    kMVYPreviewRotateRight,
    kMVYPreviewFlipVertical,
    kMVYPreviewFlipHorizonal,
    kMVYPreviewRotateRightFlipVertical,
    kMVYPreviewRotateRightFlipHorizontal,
    kMVYPreviewRotate180
};

@interface MVYPixelBufferPreview : UIView

/**
 内容填充方式
 */
@property (nonatomic, assign) MVYPreivewContentMode previewContentMode;

/**
 内容方向
 */
@property (nonatomic, assign) MVYPreviewRotationMode previewRotationMode;

/**
 渲染BGRA数据
 */
- (void)render:(CVPixelBufferRef)CVPixelBuffer;

/**
 当不使用GL时及时释放, 在使用时会自动重新创建
 */
- (void)releaseGLResources;

@end

@interface MVYPixelBufferPreview (OpenGLHelper)

// 创建 program
+ (GLuint)createProgramWithVert:(const NSString *)vShaderString frag:(const NSString *)fShaderString;

// 通过旋转方向创建纹理坐标
+ (const GLfloat *)textureCoordinatesForRotation:(MVYPreviewRotationMode)rotationMode;

+ (BOOL)needExchangeWidthAndHeightWithPreviewRotation:(MVYPreviewRotationMode)rotationMode;

@end
