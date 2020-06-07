//
//  MVYReadWriteLock.m
//  MVYMediaDecoder
//
//  Created by myvideoyun on 2019/4/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

#import "MVYReadWriteLock.h"
#import <pthread.h>

@interface MVYReadWriteLock () {
    pthread_rwlock_t rwlock;
}

@end

@implementation MVYReadWriteLock

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_rwlock_init(&rwlock, NULL);
    }
    return self;
}

- (MVYReadLock *)readLock {
    if (_readLock == NULL) {
        _readLock = [[MVYReadLock alloc] initWithLock:&rwlock];
    }
    
    return _readLock;
}

- (MVYWriteLock *)writeLock {
    if (_writeLock == NULL) {
        _writeLock = [[MVYWriteLock alloc] initWithLock:&rwlock];
    }
    
    return _writeLock;
}

@end

@interface MVYReadLock () {
    pthread_rwlock_t *rwlock;
}

@end

@implementation MVYReadLock

- (instancetype)initWithLock:(pthread_rwlock_t *)lock
{
    self = [super init];
    if (self) {
        rwlock = lock;
    }
    return self;
}

- (void)lock {
    pthread_rwlock_rdlock(self->rwlock);
}

- (void)unlock {
    pthread_rwlock_unlock(self->rwlock);
}

@end

@interface MVYWriteLock () {
    pthread_rwlock_t *rwlock;
}

@end

@implementation MVYWriteLock

- (instancetype)initWithLock:(pthread_rwlock_t *)lock
{
    self = [super init];
    if (self) {
        rwlock = lock;
    }
    return self;
}

- (void)lock {
    pthread_rwlock_wrlock(self->rwlock);
}

- (void)unlock {
    pthread_rwlock_unlock(self->rwlock);
}

@end
