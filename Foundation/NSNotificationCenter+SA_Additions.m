//
//  NSNotificationCenter+Additions.m
//
//  Created by Ben Gottlieb on 5/29/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "NSNotificationCenter+SA_Additions.h"


static NSMutableArray *s_fireAndForgetNotificationBlocks = nil;

@implementation NSNotificationCenter (NSNotificationCenter_SA_Additions)

- (void) postNotificationOnMainThreadName: (NSString *) name object: (id) object info: (NSDictionary *) info {
	if ([NSThread isMainThread]) {
		[[NSNotificationCenter defaultCenter] postNotificationName: name object: object userInfo: info];
	} else dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName: name object: object userInfo: info];
	});
}

- (void) postNotificationOnMainThreadName: (NSString *) name object: (id) object {
	[self postNotificationOnMainThreadName: name object: object info: nil];
}

- (void) postDeferredNotificationOnMainThreadName: (NSString *) name object: (id) object info: (NSDictionary *) info {
	dispatch_async_main_queue(^{
		[[NSNotificationCenter defaultCenter] postNotificationName: name object: object userInfo: info];
	});
}

- (void) postDeferredNotificationOnMainThreadName: (NSString *) name object: (id) object {
	[self postDeferredNotificationOnMainThreadName: name object: object info: nil];
}

- (id) addFireAndForgetBlockFor: (NSString *) name object: (id) object block: (notificationArgumentBlock) block {
	NSMutableDictionary					*notificationInfo = [NSMutableDictionary dictionary];
	@synchronized (self) {
		if (s_fireAndForgetNotificationBlocks == nil) s_fireAndForgetNotificationBlocks = [[NSMutableArray alloc] init];
		[s_fireAndForgetNotificationBlocks addObject: notificationInfo];
	}

	
	id			removeKey = [self addObserverForName: name object: object queue: [NSOperationQueue currentQueue] usingBlock: ^(NSNotification *note) {
		block(note);
		
		[[NSNotificationCenter defaultCenter] removeObserver: [notificationInfo objectForKey: @"observer"]];
		[s_fireAndForgetNotificationBlocks removeObject: notificationInfo]; 
	}];

	[notificationInfo setObject: removeKey forKey: @"observer"];
	return notificationInfo;
}

- (void) removeFireAndForgetNotification: (id) notificationInfo {
	[[NSNotificationCenter defaultCenter] removeObserver: [notificationInfo objectForKey: @"observer"]];
	[s_fireAndForgetNotificationBlocks removeObject: notificationInfo]; 
}

+ (void) postNotificationNamed: (NSString *) name object: (id) object {
	if ([NSThread isMainThread]) {
		[[NSNotificationCenter defaultCenter] postNotificationName: name object: object];
	} else dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName: name object: object];
	});
}

+ (void) postNotificationNamed: (NSString *) name {
	if ([NSThread isMainThread]) {
		[[NSNotificationCenter defaultCenter] postNotificationName: name object: nil];
	} else dispatch_async(dispatch_get_main_queue(), ^{
		[[NSNotificationCenter defaultCenter] postNotificationName: name object: nil];
	});
}



@end
