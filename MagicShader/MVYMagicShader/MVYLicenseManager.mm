//
//  MVYLicenseManager.m
//  MVYMagicShader
//
//  Created by myvideoyun on 2019/5/26.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYLicenseManager.h"
#import "mvy_magicshader.h"
#import "Observer.h"

MVYAuthCallback authCallback = nil;

void mvy_auth_func(int type, int ret, const char *info) {
    if (type == ObserverMsg::MSG_TYPE_AUTH) {
        
        if (authCallback != nil) {
            authCallback(ret);
            authCallback = nil;
        }
    }
}

Observer mvy_auth_observer = {mvy_auth_func};

@implementation MVYLicenseManager

+ (void)initLicenseWithAppKey:(NSString *)appKey callback:(MVYAuthCallback)callback{
    
    authCallback = [callback copy];
    MVY_MagicShader_Auth("com.myvideoyun.ShortVideoEditorIOS", appKey.UTF8String, "", &mvy_auth_observer, 64);
    
}

@end
