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
@property (nonatomic, strong) NSMutableArray *actionBlocks;
@end


@implementation SA_BlockButton
@synthesize actionBlocks;
- (void) addBlock: (simpleBlock) block forControlEvent: (UIControlEvents) event {
	if (self.actionBlocks == nil) self.actionBlocks = [NSMutableArray array];
	
	[self.actionBlocks addObject: block];
	[self addTarget: self action: @selector(evaluateActionBlocks) forControlEvents: event];
}

- (void) evaluateActionBlocks {
	for (simpleBlock block in self.actionBlocks) {
		block();
	}
}
@end
