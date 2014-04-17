//
//  SA_Sentinel.m
//  SABase
//
//  Created by Ben Gottlieb on 4/17/14.
//
//

#import "SA_Sentinel.h"

@interface SA_Sentinel ()

@property (nonatomic, copy) simpleBlock completion;
@property (nonatomic) NSUInteger watchCount;

@end

@implementation SA_Sentinel

+ (instancetype) sentinelWithCompletionBlock: (simpleBlock) block {
	SA_Sentinel				*sentinel = [SA_Sentinel new];
	
	sentinel.completion = block;
	return sentinel;
}

- (void) increment {
	@synchronized (self) {
		self.watchCount++;
	}
}

- (void) decrement {
	@synchronized (self) {
		if (self.watchCount > 0) self.watchCount--;
		if (self.watchCount == 0 && self.completion) {
			self.completion();
			self.completion = nil;
		}
	}
}


@end
