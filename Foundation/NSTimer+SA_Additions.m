//
//  NSTimer+Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSTimer+SA_Additions.h"
#import "dispatch_additions_SA.h"

@implementation NSTimer (SA_SA_Additions)

+ (NSTimer *) scheduledTimerWithTimeInterval: (NSTimeInterval) ti block: (timerArgumentBlock) block repeats: (BOOL) repeats {
	if (!repeats) {
		dispatch_after_main_queue(ti, ^{block(nil); });
		return nil;
	}
	
	return [NSTimer scheduledTimerWithTimeInterval: ti 
											target: self 
										  selector: @selector(SA_BlockTimerFired:) 
										  userInfo: block
										   repeats: YES];
}

+ (void) SA_BlockTimerFired: (NSTimer *) timer {
	timerArgumentBlock				block = (timerArgumentBlock) timer.userInfo;
	
	if (block) block(timer);
}


@end
