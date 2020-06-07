//
//  MVYGPUImageTextureModel.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/6/29.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageTextureModel.h"

@implementation MVYGPUImageTextureModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _transformMatrix = CATransform3DIdentity;
        _transparent = 1.0f;
        _rotate = kMVYGPUImageNoRotation;
    }
    return self;
}

@end
