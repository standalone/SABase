//
//  UIGestureRecognizer+Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 7/17/12.
//
//


#import "UIGestureRecognizer+SA_Additions.h"
#import "NSObject+SA_Additions.h"
#import "SA_Utilities.h"


#define GESTURE_BLOCK_KEY			@"SA_GESTURE_BLOCK_KEY"

@implementation UIGestureRecognizer (SA_SA_Additions)

- (void) sa_blockRecognizerAction: (UIGestureRecognizer *) recog {
	idArgumentBlock			block = (idArgumentBlock) [self associatedValueForKey: GESTURE_BLOCK_KEY];
	
	if (block) block(recog);
}

- (id) initWithSA_Block: (gestureArgumentBlock) block {
	if ((self = [self initWithTarget: self action: @selector(sa_blockRecognizerAction:)])) {
		[self associateValue: (block) forKey: GESTURE_BLOCK_KEY];
	}
	return self;
}

+ (id) SA_longPressRecognizerWithPressBlock: (gestureArgumentBlock) block {
	return [[UILongPressGestureRecognizer alloc] initWithSA_Block: ^(UIGestureRecognizer *recog) {
		static BOOL			presented = NO;
		
		switch (recog.state) {
			case UIGestureRecognizerStateBegan:
				if (presented) return;
				block(recog);
				presented = YES;
				break;
				
			case UIGestureRecognizerStatePossible:
			case UIGestureRecognizerStateEnded:
			case UIGestureRecognizerStateCancelled:
			case UIGestureRecognizerStateFailed:
				presented = NO;
				break;
				
			default:
				break;
		}
	}];

}

- (UIView *) SA_touchedView {
	CGPoint					pt = [self locationInView: self.view];
	UIView					*hit = [self.view hitTest: pt withEvent: nil];
	
	return hit;
	
}

@end
