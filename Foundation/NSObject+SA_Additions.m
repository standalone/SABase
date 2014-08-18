//
//  NSObject+Additions.m
//
//  Created by Ben Gottlieb on 8/30/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSObject+SA_Additions.h"
#import "SA_Utilities.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (SA_SA_Additions)

- (id) nonNullValue { return self; }

- (void) cancelPendingSelector: (SEL) aSelector withObject: (id) anArgument {
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: aSelector object: anArgument];
}

- (void) cancelAndPerformSelector: (SEL) aSelector withObject: (id) anArgument afterDelay: (NSTimeInterval) delay {
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: aSelector object: anArgument];

	if (GCD_AVAILABLE) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self performSelector: aSelector withObject: anArgument afterDelay: delay];
		});
	} else {
		[self performSelector: aSelector withObject: anArgument afterDelay: delay];
	}
}

- (void) associateValue: (id) value forKey: (id) key {
	objc_setAssociatedObject(self, (__bridge const void *)(key), value, OBJC_ASSOCIATION_RETAIN);
}

- (void) removeAssociateValueForKey: (id) key {
	objc_setAssociatedObject(self, (__bridge const void *)(key), nil, OBJC_ASSOCIATION_RETAIN);
}

- (void) associateValueCopy: (id) value forKey: (id) key {
	objc_setAssociatedObject(self, (__bridge const void *)(key), value, OBJC_ASSOCIATION_COPY);
}

- (id) associatedValueForKey: (id) key {
	return objc_getAssociatedObject(self, (__bridge const void *)(key));
}

- (BOOL) hasValueForKey: (NSString *) key {
	if ([self respondsToSelector: NSSelectorFromString(key)]) return YES;
	
	unsigned int				propertyCount;
	objc_property_t				*props = class_copyPropertyList([self class], &propertyCount);
	
	for (NSUInteger i = 0; i < propertyCount; i++) {
		const char				*propName = property_getName(props[i]);
		
		if (strcmp([key UTF8String], propName) == 0) {
			free(props);
			return YES;
		}
	}
	free(props);
	
	if ([self respondsToSelector: @selector(objectForKey:)]) return [(id) self objectForKey: key] != nil;
	return NO;
}

- (id) performSelector: (SEL) selector withObject: (id) arg1 withObject: (id) arg2 withObject: (id) arg3 {
	return (id) objc_msgSend(self, selector, arg1, arg2, arg3);
}

- (void) addAsObserverForNotificationName: (NSString *) note selector: (SEL) selector object: (id) object {
	if (![self respondsToSelector: selector]) {
		NSLog(@"********************* Adding as an observer, but selector (%@) not present on %@! *********************", NSStringFromSelector(selector), NSStringFromClass([self class]));
	}
	[[NSNotificationCenter defaultCenter] addObserver: self selector: selector name: note object: object];
}

- (void) addAsObserverForName: (NSString *) note selector: (SEL) selector {
	if (![self respondsToSelector: selector]) {
		NSLog(@"********************* Adding as an observer, but selector (%@) not present on %@! *********************", NSStringFromSelector(selector), NSStringFromClass([self class]));
	}
	[[NSNotificationCenter defaultCenter] addObserver: self selector: selector name: note object: nil];
}

- (void) removeAsObserver {
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

+ (void) performBlock: (simpleBlock) block afterDelay: (NSTimeInterval) delay {
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), block);
}

- (void) sa_callBlock {
	void (^block)(void) = (id) self;
	block();
}

+ (void) performBlock: (simpleBlock) block onThread: (NSThread *) thread waitUntilDone: (BOOL) waitUntilDone {
	[self performSelector: @selector(performBlock:) onThread: thread withObject: [block copy] waitUntilDone: waitUntilDone];
}

+ (void) performBlock: (simpleBlock) block {
	block();
}

+ (void) performBlockOnMainThread: (simpleBlock) block {
	dispatch_async(dispatch_get_main_queue(), block);
}

//=============================================================================================================================
#pragma mark KVO
- (void) observeKey: (NSString *) key onObject: (id) object {
	[self observeKey: key onObject: object options: NSKeyValueObservingOptionNew context: nil];
}

- (void) observeKey: (NSString *) key onObject: (id) object options: (NSKeyValueObservingOptions) options context: (void *) ctx {
	[object addObserver: self forKeyPath: key options: options context: ctx];
}

- (void) observeValueForKeyPath: (NSString *) keyPath ofObject: (id) object change: (NSDictionary *) change context: (void *)context {
	SEL					changeSelector = NSSelectorFromString([NSString stringWithFormat: @"%@ChangedOn:change:", keyPath]);
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	if ([self respondsToSelector: changeSelector]) [self performSelector: changeSelector withObject: object withObject: change];
#pragma clang diagnostic pop
}


@end

@interface  NSNull (SA_Additions)
@end

@implementation NSNull (SA_Additions)
- (id) nonNullValue { return nil; }
@end
