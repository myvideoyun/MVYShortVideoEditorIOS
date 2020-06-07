//
//  MVYAudioResample.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/8/19.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#ifndef MVYAudioResample_h
#define MVYAudioResample_h

#include <stdio.h>

uint64_t mvy_resample_s16(const int16_t *input, int16_t *output, int inSampleRate, int outSampleRate, uint64_t inputSize, uint32_t channels) ;

#endif /* MVYAudioResample_h */
