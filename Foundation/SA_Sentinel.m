//
//  SA_Sentinel.m
//  SABase
//
//  Created by Ben Gottlieb on 4/17/14.
//
//

#import "SA_Sentinel.h"
#import "NSError+SA_Additions.h"
#import "SA_Utilities.h"
#import "dispatch_additions_SA.h"

static NSMutableSet			*s_activeSentinels = nil;

@interface SA_Sentinel ()

@property (nonatomic, copy) booleanArgumentBlock completion;
@property (nonatomic) unsigned long watchCount;
@property (nonatomic, weak) NSTimer *timeoutTimer, *decrementTimeoutTimer;

@end

@implementation SA_Sentinel

- (void) dealloc {
	[self.decrementTimeoutTimer invalidate];
	[self.timeoutTimer invalidate];
}

+ (instancetype) sentinelWithCompletionBlock: (booleanArgumentBlock) block {
	SA_Sentinel				*sentinel = [SA_Sentinel new];
	
	sentinel.completion = block;
	sentinel.watchCount = 1;
	[sentinel performSelector: @selector(decrement) withObject: nil afterDelay: 0.0];
	
	if (s_activeSentinels == nil) s_activeSentinels = [NSMutableSet new];
	[s_activeSentinels addObject: sentinel];
	dispatch_async_main_queue(^{ [sentinel decrement]; });
	return sentinel;
}

- (NSString *) description {
	return $S(@"Sentinel: %d remaining", (UInt16) self.watchCount);
}


//================================================================================================================
#pragma mark Properties
- (void) setTimeout: (NSTimeInterval) timeout {
	[self.timeoutTimer invalidate];
	if (timeout)
		self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval: timeout target: self selector: @selector(sentinelTimedOut) userInfo: nil repeats: NO];
}

- (void) setDecrementTimeout: (NSTimeInterval) decrementTimeout {
	[self.decrementTimeoutTimer invalidate];
	if (decrementTimeout)
		self.decrementTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval: decrementTimeout target: self selector: @selector(decremenetTimedOut) userInfo: nil repeats: NO];
}

- (void) sentinelTimedOut {
	[self abortWithError: [NSError errorWithDomain: SA_BaseErrorDomain code: sa_base_error_sentinel_timeout userInfo: nil]];
}

- (void) decremenetTimedOut {
	[self abortWithError: [NSError errorWithDomain: SA_BaseErrorDomain code: sa_base_error_sentinel_decrement_timeout userInfo: nil]];
}


//================================================================================================================
#pragma mark Actions

- (void) increment {
	@synchronized (self) {
		self.watchCount++;
	}
}

- (void) decrement {
	@synchronized (self) {
		self.decrementTimeout = self.decrementTimeout;
		if (self.watchCount > 0) self.watchCount--;
		if (self.watchCount == 0) {
			[self completion: YES];
		}
	}
}

- (void) decrementWithError: (NSError *) error {
	if (self.errorBlock) self.errorBlock(error);
	[self decrement];
}

- (void) abort {
	[self completion: NO];
}

- (void) abortWithError: (NSError *) error {
	if (self.errorBlock) self.errorBlock(error);
	[self abort];
}


- (void) completion: (BOOL) complete {
	if (self.completion) self.completion(complete);
	self.completion = nil;
	[s_activeSentinels removeObject: self];
}

@end
