//
//  SA_BlockButton.m
//  SABase
//
//  Created by Ben Gottlieb on 1/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SA_BlockButton.h"
#import "SA_Utilities.h"
#import "NSObject+SA_Additions.h"

@interface SA_BlockButton ()
@property (nonatomic, retain) NSMutableArray *actionBlocks;
@end


@implementation SA_BlockButton
@synthesize actionBlocks;
- (void) dealloc {
	self.actionBlocks = nil;
	[super dealloc];
}

- (id) addBlock: (simpleBlock) block forControlEvent: (UIControlEvents) event {
	if (self.actionBlocks == nil) self.actionBlocks = [NSMutableArray array];
	id				wrapper = [SA_BlockWrapper wrapperWithBlock: block];
	
	[self.actionBlocks addObject: wrapper];
	[self addTarget: wrapper action: @selector(evaluate) forControlEvents: event];

	return wrapper;
}
@end
