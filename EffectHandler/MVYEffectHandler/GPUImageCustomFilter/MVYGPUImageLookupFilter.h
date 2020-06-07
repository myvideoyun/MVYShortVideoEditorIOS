//
//  MVYGPUImageLookupFilter.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/22.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYGPUImageFilter.h"

@interface MVYGPUImageLookupFilter : MVYGPUImageFilter

@property (nonatomic, strong) UIImage* lookup;

@property (nonatomic, assign) CGFloat intensity;

@end
