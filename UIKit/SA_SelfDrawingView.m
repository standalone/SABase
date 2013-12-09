//
//  SA_SelfDrawingView.m
//  SABase
//
//  Created by Ben Gottlieb on 3/11/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import "SA_SelfDrawingView.h"


@implementation SA_SelfDrawingView

#if NS_BLOCKS_AVAILABLE
@synthesize drawBlock = _drawBlock;

- (id) initWithFrame: (CGRect) frame {
	if ((self = [super initWithFrame: frame])) {
		self.backgroundColor = [UIColor clearColor];
		self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}

- (void) drawRect: (CGRect) rect {
	if (_drawBlock) _drawBlock(self, rect);
}

- (void) setDrawBlock: (simpleDrawingBlock) block {
	_drawBlock = block;
	[self setNeedsDisplay];
}
#endif


@end
