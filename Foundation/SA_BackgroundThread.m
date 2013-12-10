//
//  SA_BackgroundThread.m
//  Express News
//
//  Created by Ben Gottlieb on 7/14/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "SA_BackgroundThread.h"

static SA_BackgroundThread			*s_backgroundThread = nil;

@implementation SA_BackgroundThread
@synthesize thread = _thread;

+ (id) startBackgroundThread {
	SA_Assert(s_backgroundThread == nil, @"Trying to start a second background thread.");
	s_backgroundThread = [self spawnThread];
	return s_backgroundThread;
}

+ (NSThread *) thread {
	SA_Assert(s_backgroundThread != nil, @"Trying to access the background thread before starting it.");
	return s_backgroundThread.thread;
}

+ (SA_BackgroundThread *) backgroundThread {
	SA_Assert(s_backgroundThread != nil, @"Trying to access the background thread before starting it.");
	return s_backgroundThread;
}

+ (BOOL) inBackgroundThread {
	return [NSThread currentThread] == [self thread];
}

+ (id) spawnThread {
	SA_BackgroundThread			*thread = [[SA_BackgroundThread alloc] init];
	
	thread->_running = YES;
	thread->_thread = [[NSThread alloc] initWithTarget: thread selector: @selector(main:) object: nil];
	[thread.thread start];
	
	return thread;
}

+ (void) performSelector: (SEL) selector onObject: (id) object {
	[self performSelector: selector onObject: object withObject: nil waitUntilDone: NO];
}

+ (void) performSelector: (SEL) selector onObject: (id) object withObject: (id) anotherObject {
	[self performSelector: selector onObject: object withObject: anotherObject waitUntilDone: NO];
}

+ (void) performSelector: (SEL) selector onObject: (id) object withObject: (id) anotherObject waitUntilDone: (BOOL) waitUntilDone {
	[object performSelector: selector onThread: [self thread] withObject: anotherObject waitUntilDone: waitUntilDone];
}

#if NS_BLOCKS_AVAILABLE
+ (void) performBlockInBackgroundThread: (simpleBlock) block {
	[[self backgroundThread] performSelector: @selector(performWithBlock:) onThread: [self backgroundThread].thread withObject: [block copy] waitUntilDone: NO];
}

- (void) performWithBlock: (simpleBlock) block {
	block();
}
#endif

void BackgroundRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);
void BackgroundRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
	
}

- (void) doNothing {
	
}

- (void) main: (id) unused {
	@autoreleasepool {
		#if 0
			while (_running) {
				SInt32    result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 100000, YES);
				if ((result == kCFRunLoopRunStopped)) {
					_running = NO;
				}
			}
		#else
			NSRunLoop								*loop = [NSRunLoop currentRunLoop];
			
			[NSTimer scheduledTimerWithTimeInterval: 100000.0 target: self selector: @selector(doNothing) userInfo: nil repeats: YES];
			
			while (_running) {
				[loop runUntilDate: [NSDate distantFuture]];
			}
		#endif
	}
}

@end
