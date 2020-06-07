//
//  MVYReadWriteLock.h
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/4/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <pthread.h>

@interface MVYReadLock : NSObject

- (instancetype)initWithLock:(pthread_rwlock_t *)lock;

- (void)lock;

- (void)unlock;

@end

@interface MVYWriteLock : NSObject

- (instancetype)initWithLock:(pthread_rwlock_t *)lock;

- (void)lock;

- (void)unlock;

@end

@interface MVYReadWriteLock : NSObject

@property (nonatomic, strong) MVYReadLock *readLock;

@property (nonatomic, strong) MVYWriteLock *writeLock;

@end
