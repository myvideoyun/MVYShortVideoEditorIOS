//
//  MVYLicenseManager.h
//  MVYMagicShader
//
//  Created by myvideoyun on 2019/5/26.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^MVYAuthCallback)(int);

@interface MVYLicenseManager : NSObject

+ (void)initLicenseWithAppKey:(NSString *)appKey callback:(MVYAuthCallback)callback;

@end
