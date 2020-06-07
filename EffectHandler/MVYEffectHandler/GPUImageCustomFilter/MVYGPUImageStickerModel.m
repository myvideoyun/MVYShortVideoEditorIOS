//
//  MVYGPUImageStickerModel.m
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/5/8.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageStickerModel.h"

@implementation MVYGPUImageStickerModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _transformMatrix = CATransform3DIdentity;
    }
    return self;
}

@end
