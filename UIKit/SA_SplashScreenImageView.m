//
//  SA_SplashScreenImageView.m
//
//  Created by Ben Gottlieb on 9/1/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "SA_SplashScreenImageView.h"


@interface SA_SplashScreenImageView ()
- (void) setupImage;

@end


@implementation SA_SplashScreenImageView


- (void) dealloc {
    [super dealloc];
}

+ (id) splashScreenViewInParent: (UIView *) parent {
	SA_SplashScreenImageView				*view = [[[self alloc] initWithFrame: parent.bounds] autorelease];
	
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	view.contentMode = UIViewContentModeBottom;
	[view setupImage];
	[parent addSubview: view];
	return view;
}

- (void) layoutSubviews {
	[self setupImage];
	[super layoutSubviews];
}


- (void) setupImage {
	if (self.bounds.size.width > self.bounds.size.height) {			//landscape
		self.image = [UIImage imageNamed: @"Default-Landscape.png"];
	} else {
		self.image = [UIImage imageNamed: @"Default-Portrait.png"];
	}
}

- (void) fadeOutOverPeriod: (NSTimeInterval) period {
	[UIView beginAnimations: nil context: nil];
	[UIView setAnimationDuration: period];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector(fadeOutComplete)];
	self.alpha = 0.0;
	[UIView commitAnimations];
}

- (void) fadeOutComplete {
	[self removeFromSuperview];
}

@end
