//
//  MVYGPUImageStickerFilter.h
//  MVYEffectHandler
//
//  Created by myvideoyun on 2019/5/7.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageFilter.h"
#import "MVYGPUImageStickerModel.h"

@interface MVYGPUImageStickerFilter : MVYGPUImageFilter

- (void)addStickerWithModel:(MVYGPUImageStickerModel *)model;

- (void)removeStickerWithModel:(MVYGPUImageStickerModel *)model;

- (void)clear;

@end
