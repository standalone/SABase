//
//  NSObject+Additions.h
//
//  Created by Ben Gottlieb on 8/30/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SA_Utilities.h"

@interface NSObject (SA_Additions)
- (void) cancelAndPerformSelector: (SEL)aSelector withObject: (id)anArgument afterDelay: (NSTimeInterval) delay;
- (void) cancelPendingSelector: (SEL) selector withObject: (id) anArgument;
- (void) associateValue: (id) value forKey: (id) key;
- (id) associatedValueForKey: (id) key;
- (id) performSelector: (SEL) selector withObject: (id) arg1 withObject: (id) arg2 withObject: (id) arg3;
- (void) associateValueCopy: (id) value forKey: (id) key;
- (void) addAsObserverForName: (NSString *) note selector: (SEL) selector;
- (void) removeAsObserver;
- (BOOL) hasValueForKey: (NSString *) key;

#if NS_BLOCKS_AVAILABLE
+ (void) performBlock: (simpleBlock) block afterDelay: (NSTimeInterval) delay;
+ (void) performBlock: (simpleBlock) block onThread: (NSThread *) thread waitUntilDone: (BOOL) waitUntilDone;
- (void) sa_callBlock;
+ (void) performBlock: (simpleBlock) block;
+ (void) performBlockOnMainThread: (simpleBlock) block;
#endif

@end


#if NS_BLOCKS_AVAILABLE
@interface SA_BlockWrapper : NSObject
@property (nonatomic, copy) simpleBlock block;
@property (nonatomic, copy) idArgumentBlock idBlock;
+ (id) wrapperWithBlock: (simpleBlock) block;
+ (id) wrapperWithIDBlock: (idArgumentBlock) block;
- (void) evaluate;
- (void) evaluate: (id) arg;
@end
#endif