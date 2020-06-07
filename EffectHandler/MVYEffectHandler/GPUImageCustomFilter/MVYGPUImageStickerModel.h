//
//  MVYGPUImageStickerModel.h
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/5/8.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MVYGPUImageStickerModel : NSObject {
@public
    GLuint texture;
}

@property (nonatomic, assign) CATransform3D transformMatrix;

@property (nonatomic, strong) UIImage *image;

@end
