//
//  MVYAudioFrame.m
//  MediaDecoder
//
//  Created by myvideoyun on 2019/4/14.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYAudioFrame.h"
#include "MVYAudioResample.h"

@implementation MVYAudioFrame

-(void)resampleUseTempo {
    if (self.tempo != 0 && self.tempo != 1) {
        
        uint16_t *output = (uint16_t *) malloc(self.bufferSize * self.tempo);
        
        int count = mvy_resample_s16(self.buffer.bytes, output, self.sampleRate, self.sampleRate * self.tempo, self.bufferSize / self.channels / sizeof(uint16_t), self.channels);
        
        self.buffer = [NSData dataWithBytes:output length:self.bufferSize * self.tempo];
        self.bufferSize = self.bufferSize * self.tempo;
        self.sampleRate = self.sampleRate * self.tempo;
        
        free(output);
    }
}

@end
