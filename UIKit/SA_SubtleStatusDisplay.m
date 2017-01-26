//
//  SA_SubtleStatusDisplay.m
//  ManualOverride
//
//  Created by Ben Gottlieb on 11/28/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "SA_SubtleStatusDisplay.h"

static SA_SubtleStatusDisplay		*s_statusDisplay = nil;
static NSUInteger					s_displayHeight = 30.0;

@interface SA_SubtleStatusDisplay ()
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) NSTimeInterval dismissInterval;
@property (nonatomic, strong) NSTimer *dismissTimer;
@property (nonatomic, strong) UIGestureRecognizer *tappedGesture;
@end

@implementation SA_SubtleStatusDisplay
- (void) dealloc {
	self.label = nil;
	self.activityIndicator = nil;
}

+ (void) dismissAfter: (NSTimeInterval) seconds {
	s_statusDisplay.dismissInterval = seconds;
	[s_statusDisplay.dismissTimer invalidate];
	
	s_statusDisplay.dismissTimer = seconds ? [NSTimer scheduledTimerWithTimeInterval: seconds target: self selector: @selector(hideStatus) userInfo: nil repeats: NO] : nil;
}

+ (SA_SubtleStatusDisplay *) display { return s_statusDisplay; }

+ (BOOL) isVisible {
	return s_statusDisplay != nil;
}

+ (void) setDisplayHeight: (NSUInteger) height {
	s_displayHeight = height;
	[s_statusDisplay heightChanged];
}

+ (UIView *) parentView {
	UINavigationController			*controller = (id) [[[[UIApplication sharedApplication] delegate] window] rootViewController];
	
	if ([controller isKindOfClass: [UINavigationController class]] && controller.viewControllers.count) controller = controller.viewControllers[0];
	return controller.view;
}

+ (SA_SubtleStatusDisplay *) showStatusText: (NSString *) text onSide: (subtleStatusSide) side withActivityIndicator: (BOOL) showActivityIndicator {
	simpleBlock					block = ^{
		UIView							*parent = [self parentView];
		CGRect							frame = [self frameForSide: side inView: parent];

		if (s_statusDisplay == nil) {
			s_statusDisplay = [[self alloc] initWithFrame: frame];
			
			s_statusDisplay.label = [[UILabel alloc] initWithFrame: CGRectFromSize(frame.size)];
			s_statusDisplay.layer.zPosition = 100;
			s_statusDisplay.side = side;
			s_statusDisplay.label.textAlignment = NSTextAlignmentCenter;
			s_statusDisplay.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.75];
			s_statusDisplay.layer.cornerRadius = frame.size.height * 0.3;
			s_statusDisplay.clipsToBounds = YES;
			s_statusDisplay.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
			s_statusDisplay.label.lineBreakMode = NSLineBreakByWordWrapping;
			s_statusDisplay.label.font = [UIFont boldSystemFontOfSize: 14.0];
			s_statusDisplay.label.backgroundColor = [UIColor clearColor];
			s_statusDisplay.label.textColor = [UIColor whiteColor];
			[s_statusDisplay addSubview: s_statusDisplay.label];
			
			s_statusDisplay.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
		} else if (s_statusDisplay.superview != parent) {
			s_statusDisplay.frame = frame;
		}
		
		SA_Assert(parent != nil, @"Status Displays must have a parent; none found.");
		
		[parent addSubview: s_statusDisplay];
		if ([text isKindOfClass: [NSAttributedString class]]) {
			s_statusDisplay.label.text = @"";
			s_statusDisplay.label.attributedText = (id) text;
		} else {
			s_statusDisplay.label.attributedText = nil;
			s_statusDisplay.label.text = text;
		}

		s_statusDisplay.text = text;
		s_statusDisplay.showActivityIndicator = showActivityIndicator;
		if (s_statusDisplay.dismissInterval) [self dismissAfter: s_statusDisplay.dismissInterval];
	};
	
	if ([NSThread isMainThread])
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
	
	return s_statusDisplay;
}

+ (void) hideStatus { [self hideStatus: YES]; }

+ (void) hideStatus: (BOOL) animated {
	[s_statusDisplay.dismissTimer invalidate];
	
	if (animated) {
		[UIView animateWithDuration: 0.2 animations: ^{
			s_statusDisplay.alpha = 0.0;
		} completion:^(BOOL finished) {
			[s_statusDisplay removeFromSuperview];
			s_statusDisplay = nil;
		}];
	} else {
		[s_statusDisplay removeFromSuperview];
		s_statusDisplay = nil;
	}
	
}

- (void) heightChanged {
	self.label.numberOfLines = (s_displayHeight - 10) / 14;
	self.frame = [SA_SubtleStatusDisplay frameForSide: self.side inView: self.superview];
}

- (void) setTouchedBlock: (simpleBlock) touchedBlock {
	_touchedBlock = [(id) touchedBlock copy];
	
	if (touchedBlock && self.tappedGesture == nil) {
		self.tappedGesture = [[UITapGestureRecognizer alloc] initWithTarget: self action: @selector(tapped:)];
		[self addGestureRecognizer: self.tappedGesture];
	} else if (touchedBlock == nil && self.tappedGesture) {
		[self removeGestureRecognizer: self.tappedGesture];
		self.tappedGesture = nil;
	}
}

- (void) tapped: (UIGestureRecognizer *) recog {
	if (recog.state == UIGestureRecognizerStateRecognized && self.touchedBlock) self.touchedBlock();
}

+ (CGRect) frameForSide: (subtleStatusSide) side inView: (UIView *) view {
	CGRect				bounds = view.bounds;
	CGFloat				height = s_displayHeight, width = 290;
	
	switch (side) {
		case subtleStatusSide_bottom:
			return CGRectMake((bounds.size.width - width) / 2, bounds.size.height - (height + 20), width, height);
			
		case subtleStatusSide_top:
			return CGRectMake((bounds.size.width - width) / 2, 20, width, height);
			
		default:
			break;
	}
	
	return CGRectZero;
}

- (void) setShowActivityIndicator: (BOOL) showActivityIndicator {
	if (showActivityIndicator != self.showActivityIndicator) {
		if (showActivityIndicator) {
			self.label.transform = CGAffineTransformMakeTranslation(-30, 0);
			if (self.activityIndicator == nil) {
				self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
				self.activityIndicator.center = CGPointMake(self.bounds.size.width - 20, self.bounds.size.height / 2);
				self.activityIndicator.hidesWhenStopped = YES;
				[self addSubview: self.activityIndicator];
			}
			
			[self.activityIndicator startAnimating];
		} else {
			[self.activityIndicator stopAnimating];
		}
	}
	_showActivityIndicator = showActivityIndicator;

}

@end
