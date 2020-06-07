//
//  MVYGPUImageTextureModel.h
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/6/29.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MVYGPUImageConstants.h"

@interface MVYGPUImageTextureModel : NSObject {
@public
    GLuint texture;
}

@property (nonatomic, assign) CATransform3D transformMatrix;

@property (nonatomic, assign) CGFloat transparent;

@property (nonatomic, assign) MVYGPUImageRotationMode rotate;

@property (nonatomic, strong) UIImage *image;

@end
