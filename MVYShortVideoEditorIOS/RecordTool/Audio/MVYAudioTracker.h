//
//  MVYAudioTracker.h
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/13.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MVYAudioTracker : NSObject

@property (nonatomic, assign) CGFloat volume;

- (instancetype)initWithSampleRate:(Float64)sampleRate;

- (void)play;

- (void)write:(NSData *)data;

- (void)stop;

@end
