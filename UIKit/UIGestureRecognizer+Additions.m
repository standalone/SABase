//
//  UIGestureRecognizer+Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 7/17/12.
//
//

#import "UIGestureRecognizer+Additions.h"
#import "NSObject+Additions.h"


#define GESTURE_BLOCK_KEY			@"SA_GESTURE_BLOCK_KEY"

@implementation UIGestureRecognizer (SA_Additions)

- (void) sa_blockRecognizerAction: (UIGestureRecognizer *) recog {
	SA_BlockWrapper			*wrapper = [self associatedValueForKey: GESTURE_BLOCK_KEY];
	
	if (wrapper) wrapper.idBlock(recog);
}

- (id) initWithBlock: (gestureArgumentBlock) block {
	if ((self = [self initWithTarget: self action: @selector(sa_blockRecognizerAction:)])) {
		[self associateValue: [SA_BlockWrapper wrapperWithIDBlock: (idArgumentBlock) block] forKey: GESTURE_BLOCK_KEY];
	}
	return self;
}

@end
