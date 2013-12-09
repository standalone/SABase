//
//  SA_Switch.m
//  SABase
//
//  Created by Ben Gottlieb on 7/28/13.
//
//

#import "SA_Switch.h"

@implementation SA_Switch

+ (id) switchWithSwitchedBlock: (switchedBlock) block {
	SA_Switch			*sw = [[self alloc] initWithSwitchedBlock: block];
				
	return sw;
}


- (id) initWithSwitchedBlock: (switchedBlock) block {
	if (self = [super initWithFrame: CGRectZero]) {
		self.switchedBlock = block;
	}
	return self;
}

- (void) setSwitchedBlock: (switchedBlock) block {
	if (_switchedBlock == nil)
		[self addTarget: self action: @selector(switchFlipped) forControlEvents: UIControlEventValueChanged];
	else
		Block_release(_switchedBlock);
		
	_switchedBlock = block ? Block_copy(block) : nil;
}

- (void) switchFlipped {
	if (self.switchedBlock) self.switchedBlock(self.isOn);
}

@end
