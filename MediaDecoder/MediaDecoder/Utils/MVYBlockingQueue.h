//
//  MVYBlockingQueue.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/4/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MVYBlockingQueue : NSObject

- (instancetype)initWithCapacity:(int)capacity;

- (void)put:(id)data;

- (id)take:(int)timeout;

- (id)take;

- (void)clear;

@end
