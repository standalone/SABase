//
//  SA_FullScreenBlockingView.m
//  Crosswords7
//
//  Created by Ben Gottlieb on 3/22/15.
//  Copyright (c) 2015 Stand Alone, Inc. All rights reserved.
//

#import "SA_FullScreenBlockingView.h"
#import "SA_Utilities.h"

@interface SA_FullScreenBlockingView ()
@property (nonatomic, strong) NSArray *targets;
@property (nonatomic) BOOL checkingForHit;
@property (nonatomic) BOOL startingOffInPortrait;
@end

@implementation SA_FullScreenBlockingView
+ (instancetype) blockerForViews: (NSArray *) targets {
	if (targets.count == 0) return nil;
	
	UIView						*primary = targets[0];
	UIView						*base = primary.window.rootViewController.view;
	SA_FullScreenBlockingView	*view = [[self alloc] initWithFrame: base.bounds];
	
	view.targets = targets;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[base addSubview: view];
	view.backgroundColor = [UIColor clearColor];
	view.userInteractionEnabled = YES;
	view.startingOffInPortrait = UIInterfaceOrientationIsPortrait([UIDevice currentDevice].userInterfaceOrientation);
	
	[view addAsObserverForName: UIDeviceOrientationDidChangeNotification selector: @selector(deviceRotated)];
	
	return view;
}

- (void) deviceRotated {
	if ([UIDevice currentDevice].orientation == UIDeviceOrientationUnknown) return;
	
	BOOL			inPortrait = UIInterfaceOrientationIsPortrait([UIDevice currentDevice].userInterfaceOrientation);
	
	if (inPortrait != self.startingOffInPortrait) [self endBlocking];
}

- (UIView *) hitTest: (CGPoint) point withEvent: (UIEvent *) event {
	if (self.checkingForHit) return nil;
	
	self.checkingForHit = YES;
	UIView		*hit = [self.superview hitTest: point withEvent: event];
	
	self.checkingForHit = NO;

	if (hit && [self.targets containsObject: hit]) {
		return hit;
	}
	
	switch (self.mode) {
		case SA_FullScreenBlockingViewModeDismissAndEatEvent:
			[self performSelector: @selector(endBlocking) withObject: nil afterDelay: 0.0];
			break;
			
		case SA_FullScreenBlockingViewModeDismissAndPassThroughEvent:
			[self endBlocking];
			return hit;
			break;
	}
	
	return self;
}

- (void) endBlocking {
	if (self.didDismissBlock) self.didDismissBlock();
	[self dismiss];
}

- (void) dismiss {
	[self removeFromSuperview];
}
@end
