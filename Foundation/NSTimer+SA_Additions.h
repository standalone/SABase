//
//  NSTimer+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^timerArgumentBlock)(NSTimer *timer);


@interface NSTimer (SA_SA_Additions)

+ (NSTimer *) scheduledTimerWithTimeInterval: (NSTimeInterval) ti block: (timerArgumentBlock) block repeats: (BOOL) repeats;
@end
