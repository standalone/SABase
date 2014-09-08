//
//  SA_CustomAlert.m
//  Words Play
//
//  Created by Ben Gottlieb on 5/23/14.
//  Copyright (c) 2014 Stand Alone, Inc. All rights reserved.
//

#import "SA_CustomAlert.h"
#import "UIWindow+SA_Additions.h"
#import "dispatch_additions_SA.h"
#import "CGContextRef_additions.h"
#import "SA_ProgressView.h"
#import "SA_AlertView.h"

static NSMutableArray *s_alerts;
static UIFont *s_titleFont, *s_messageFont, *s_buttonFont, *s_defaultButtonFont;
static UIColor *s_backgroundColor, *s_buttonBackgroundColor, *s_buttonTitleColor, *s_defaultButtonTitleColor, *s_titleColor, *s_messageColor, *s_buttonSeparatorColor;
static CGFloat s_viewWidth, s_viewMargin, s_titleMessageSpacing, s_messageButtonSpacing, s_buttonSpacing, s_buttonHeight;
static NSTimeInterval s_showAlertDuration, s_hideAlertDuration;
static BOOL s_useStandardAlerts = NO;

@interface SA_CustomAlertBackgroundView : UIView
@property (nonatomic, strong) NSMutableArray *separatorLines;

- (void) addSeparatorLineFrom: (CGPoint) start to: (CGPoint) end;
@end

@interface SA_CustomAlertBlockerView : UIView
@end
@interface SA_CustomAlertBlockerLayer : CALayer
@end

@interface UIWindow (SA_CustomAlert)
+ (UIWindow *) alertWindow;
+ (void) closeAlertWindow;

@property (nonatomic, readonly) BOOL isAlertWindow;
@end

@interface SA_CustomAlert ()
@property (nonatomic, strong) UITextView *messageTextView;
@property (nonatomic, strong) SA_CustomAlertBackgroundView *backgroundView;
@end

static UIWindow *s_alertWindow;
static SA_CustomAlertBlockerView *s_blockingView;
static SA_CustomAlert *s_currentAlert;

@implementation SA_CustomAlert

+ (void) initialize {
	@autoreleasepool {
		s_alerts = [NSMutableArray array];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(willChangeStatusBarOrientation:) name: UIApplicationWillChangeStatusBarOrientationNotification object: nil];
		
		self.titleFont = [UIFont boldSystemFontOfSize: 20.0];
		self.messageFont = [UIFont systemFontOfSize: 16.0];
		self.viewWidth = 300.0;
		self.viewMargin = 10.0;
		self.titleMessageSpacing = 10;
		self.buttonSpacing = 10;
		self.messageButtonSpacing = 10;
		self.buttonHeight = 44;
		
		self.showAlertDuration = 0.5;
		self.hideAlertDuration = 0.5;
		
		self.defaultButtonFont = [UIFont boldSystemFontOfSize: 20];
		self.buttonFont = [UIFont systemFontOfSize: 20];
		self.backgroundColor = [UIColor colorWithWhite: 0.25 alpha: 0.95];
		self.buttonBackgroundColor = [UIColor clearColor];
		self.buttonTitleColor = [UIColor whiteColor];
		self.titleColor = [UIColor whiteColor];
		self.messageColor = [UIColor colorWithWhite: 0.92 alpha: 1.0];
		self.buttonSeparatorColor = [UIColor colorWithWhite: 0.8 alpha: 1.0];
	}
}

//================================================================================================================
+ (instancetype) showAlertWithTitle: (NSString *) title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (alertButtonHitBlock) buttonHitBlock {
	if (s_useStandardAlerts) {
		[SA_CustomAlert showAlertWithTitle: title message: message buttons: buttons buttonBlock: buttonHitBlock];
		return nil;
	}
	
	SA_CustomAlert			*alert = [self new];
	
	alert.title = title;
	alert.message = message;
	alert.buttonTitles = buttons;
	alert.buttonHitBlock = buttonHitBlock;
	alert.defaultButtonIndex = buttons.count > 1 ? 1 : 0;
	
	[s_alerts addObject: alert];
	
	dispatch_async_main_queue(^{
		[alert show: YES];
	});
	return alert;
}

+ (instancetype) showAlertWithTitle: (NSString *) title message: (NSString *) message { return [self showAlertWithTitle: title message: message buttons: @[ NSLocalizedString(@"OK", @"OK") ] buttonBlock: nil]; }
+ (instancetype) showAlertWithTitle: (NSString *) title error: (NSError *) error { return [self showAlertWithTitle: title message: error.localizedDescription]; }

- (void) addCustomView: (UIView *) view {
	if (self.customViews == nil) self.customViews = [NSMutableArray array];
	[self.customViews addObject: view];
}

//================================================================================================================
#pragma mark Actions
- (void) alertButtonTouched: (UIButton *) button {
	if (self.buttonHitBlock) self.buttonHitBlock(button.tag);
	[self dismiss: YES];
}

- (void) show: (BOOL) animated {
	if (s_currentAlert) return;			//already showing an alert
	
	s_currentAlert = self;
	[[UIWindow alertWindow] addSubview: self.alertBaseView];
	if (animated) [self animateAlertIn];
}

- (void) animateAlertIn {
	self.alertBaseView.alpha = 0.0;
	self.alertBaseView.transform = CGAffineTransformScale(UIWindow.sa_transformForCurrentUserInterfaceOrientation, 0.001, 0.001);
	
	[UIView animateWithDuration: SA_CustomAlert.showAlertDuration	delay: 0.0 usingSpringWithDamping: 0.8 initialSpringVelocity: 0.0 options: UIViewAnimationOptionCurveEaseOut animations:^{
		self.alertBaseView.transform = UIWindow.sa_transformForCurrentUserInterfaceOrientation;
		s_blockingView.alpha = 1.0;
		self.alertBaseView.alpha = 1.0;
	} completion:^(BOOL finished) {
		
	}];
}

- (void) animateOutWithCompletion: (simpleBlock) completion {
	[UIView animateWithDuration: SA_CustomAlert.hideAlertDuration delay: 0.0 usingSpringWithDamping: 0.8 initialSpringVelocity: 0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
		self.alertBaseView.transform = CGAffineTransformScale(UIWindow.sa_transformForCurrentUserInterfaceOrientation, 0.001, 0.001);;
		self.alertBaseView.alpha = 0.0;
		if (s_alerts.count == 1) s_blockingView.alpha = 0.0;
	} completion: ^(BOOL finished) {
		[self.alertBaseView removeFromSuperview];
		if (completion) completion();
	}];
}

- (void) dismiss: (BOOL) animated {
	s_currentAlert = nil;
	SA_CustomAlert			*next = s_alerts.count > 1 ? s_alerts[1] : nil;
	
	[self animateOutWithCompletion: ^{
		[s_alerts removeObject: self];
		if (s_alerts.count == 0) [UIWindow closeAlertWindow];
	}];
	[next show: animated];
}


//================================================================================================================
#pragma mark Notifications
+ (void) willChangeStatusBarOrientation: (NSNotification *) note {
	UIInterfaceOrientation		newOrientation = [note.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
	CGAffineTransform			newTransform = [UIWindow sa_transformForUserInterfaceOrientation: newOrientation];
	
	[UIView animateWithDuration: 0.2 animations:^{
		for (SA_CustomAlert *alert in s_alerts) {
			alert.alertBaseView.transform = newTransform;
		}
	}];
}



//================================================================================================================
#pragma mark Properties
- (UILabel *) titleLabel {
	if (_titleLabel == nil) {
		CGSize				size = self.titleSize;
		
		_titleLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, SA_CustomAlert.viewWidth - SA_CustomAlert.viewMargin * 2, size.height)];
		_titleLabel.font = SA_CustomAlert.titleFont;
		_titleLabel.numberOfLines = 10000;
		_titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
		_titleLabel.text = self.title;
		_titleLabel.textColor = SA_CustomAlert.titleColor;
		_titleLabel.textAlignment = NSTextAlignmentCenter;
	}
	return _titleLabel;
}

- (UILabel *) messageLabel {
	if (_messageLabel == nil) {
		CGSize				size = self.messageSize;
		BOOL				useTextView = NO;
		
		if (size.height > 200) {
			size.height = 200;
			useTextView = YES;
		}
		
		_messageLabel = [[UILabel alloc] initWithFrame: CGRectMake(0, 0, SA_CustomAlert.viewWidth - SA_CustomAlert.viewMargin * 2, size.height)];
		_messageLabel.font = SA_CustomAlert.messageFont;
		_messageLabel.numberOfLines = 10000;
		_messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
		_messageLabel.textColor = SA_CustomAlert.messageColor;
		_messageLabel.textAlignment = NSTextAlignmentCenter;
		
		if (useTextView) {
			self.messageTextView = [[UITextView alloc] initWithFrame: CGRectFromSize(_messageLabel.frame.size)];
			[_messageLabel addSubview: self.messageTextView];
			self.messageTextView.backgroundColor = [UIColor clearColor];
			self.messageTextView.font = SA_CustomAlert.messageFont;
			self.messageTextView.textColor = SA_CustomAlert.messageColor;
			self.messageTextView.editable = NO;
			_messageLabel.text = nil;
			_messageLabel.userInteractionEnabled = YES;
			self.messageTextView.text = self.message;
		} else
			_messageLabel.text = self.message;
}
	return _messageLabel;
}

- (CGSize) titleSize {
	return [self.title boundingRectWithSize: CGSizeMake(SA_CustomAlert.viewWidth - 2 * SA_CustomAlert.viewMargin, 10000.0) options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: SA_CustomAlert.titleFont } context: nil].size;
}

- (CGSize) messageSize {
	return [self.message boundingRectWithSize: CGSizeMake(SA_CustomAlert.viewWidth - 2 * SA_CustomAlert.viewMargin, 10000.0) options: NSStringDrawingUsesLineFragmentOrigin attributes: @{ NSFontAttributeName: SA_CustomAlert.messageFont } context: nil].size;
}

- (CGFloat) totalContentHeight {
	CGFloat				total = 0;
	
	total += self.messageSize.height;
	total += self.titleSize.height;
	
	total += self.numberOfButtonRows * (SA_CustomAlert.buttonHeight + SA_CustomAlert.buttonSpacing) - SA_CustomAlert.buttonSpacing;
	total += SA_CustomAlert.messageButtonSpacing + SA_CustomAlert.titleMessageSpacing + SA_CustomAlert.viewMargin * 2;
	
	if (self.customViews.count) {
		total += SA_CustomAlert.messageButtonSpacing;
		for (UIView *view in self.customViews) {
			total += view.bounds.size.height + SA_CustomAlert.buttonSpacing;
		}
	}
	
	return total;
}

- (CGFloat) alertViewHeight {
	CGFloat				total = 0;
	
	total += self.messageLabel.bounds.size.height;
	total += self.titleLabel.bounds.size.height;
	
	total += self.numberOfButtonRows * (SA_CustomAlert.buttonHeight + SA_CustomAlert.buttonSpacing) - SA_CustomAlert.buttonSpacing;
	total += SA_CustomAlert.messageButtonSpacing + SA_CustomAlert.titleMessageSpacing + SA_CustomAlert.viewMargin * 2;
	
	if (self.customViews.count) {
		total += SA_CustomAlert.messageButtonSpacing;
		for (UIView *view in self.customViews) {
			total += view.bounds.size.height + SA_CustomAlert.buttonSpacing;
		}
	}
	
	return total;
}

- (UIView *) alertBaseView {
	if (_alertBaseView == nil) {
		self.backgroundView = [[SA_CustomAlertBackgroundView alloc] initWithFrame: CGRectMake(0, 0, SA_CustomAlert.viewWidth, self.alertViewHeight)];
		_alertBaseView = self.backgroundView;
		_alertBaseView.backgroundColor = [UIColor clearColor];
		self.backgroundView.userInteractionEnabled = YES;
		self.backgroundView.center = [UIWindow alertWindow].contentCenter;
		
		self.titleLabel.center = CGPointMake(SA_CustomAlert.viewWidth / 2, SA_CustomAlert.viewMargin + self.titleLabel.bounds.size.height / 2);
		[self.backgroundView addSubview: self.titleLabel];
		
		self.messageLabel.center = CGPointMake(SA_CustomAlert.viewWidth / 2, SA_CustomAlert.viewMargin + SA_CustomAlert.titleMessageSpacing + self.titleLabel.bounds.size.height + self.messageLabel.bounds.size.height / 2);
		[self.backgroundView addSubview: self.messageLabel];
		
		CGFloat				top = CGRectGetMaxY(self.messageLabel.frame) + SA_CustomAlert.messageButtonSpacing;
		
		for (UIView *view in self.customViews) {
			view.center = CGPointMake(self.alertBaseView.contentCenter.x, top + view.bounds.size.height / 2);
			top += view.bounds.size.height + SA_CustomAlert.buttonSpacing;
			[self.alertBaseView addSubview: view];
		}
		
		self.backgroundView.transform = [UIWindow sa_transformForCurrentUserInterfaceOrientation];
		
		for (int i = 0; i < self.buttonTitles.count; i++) {
			[self addButtonAtIndex: i];
		}

		Class							interpolator = NSClassFromString(@"UIInterpolatingMotionEffect");
		UIInterpolatingMotionEffect		*xAxisEffect = [[interpolator alloc] initWithKeyPath: @"center.x" type: UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
		xAxisEffect.minimumRelativeValue = @-10;
		xAxisEffect.maximumRelativeValue = @10;
		
		UIInterpolatingMotionEffect		*yAxisEffect = [[interpolator alloc] initWithKeyPath: @"center.y" type: UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
		yAxisEffect.minimumRelativeValue = @-10;
		yAxisEffect.maximumRelativeValue = @10;
		
		Class							groupClass = NSClassFromString(@"UIMotionEffectGroup");
		UIMotionEffectGroup				*group = [[groupClass alloc] init];
		group.motionEffects = @[ xAxisEffect, yAxisEffect ];
		[self.alertBaseView addMotionEffect: group];
	}
	
	return _alertBaseView;
}

- (NSUInteger) numberOfButtonRows {
	NSUInteger				count = self.buttonTitles.count;
	
	return count <= 2 ? MIN(count, 1) : count;
}

- (CGFloat) buttonTop {
	CGFloat				top = SA_CustomAlert.viewMargin + self.titleLabel.bounds.size.height + SA_CustomAlert.titleMessageSpacing + self.messageLabel.bounds.size.height + SA_CustomAlert.messageButtonSpacing;
	
	if (self.customViews.count) {
		top += SA_CustomAlert.messageButtonSpacing;
		for (UIView *view in self.customViews) {
			top += view.bounds.size.height + SA_CustomAlert.buttonSpacing;
		}
	}
	return top;
}

- (CGRect) frameForButtonAtIndex: (NSUInteger) index {
	if (self.numberOfButtonRows != self.buttonTitles.count) {
		NSUInteger				rowIndex = index / 2;
		CGFloat					midWay = SA_CustomAlert.viewWidth / 2, buttonWidth = (SA_CustomAlert.viewWidth - (SA_CustomAlert.buttonSpacing + SA_CustomAlert.viewMargin * 2)) / 2;
		
		if (index % 2)
			return CGRectMake(midWay + SA_CustomAlert.buttonSpacing / 2, self.buttonTop + (rowIndex * SA_CustomAlert.buttonSpacing), buttonWidth, SA_CustomAlert.buttonHeight);
	
		return CGRectMake(SA_CustomAlert.viewMargin, self.buttonTop + (rowIndex * SA_CustomAlert.buttonSpacing), buttonWidth, SA_CustomAlert.buttonHeight);
	} else {
		return CGRectMake(SA_CustomAlert.viewMargin, self.buttonTop + (index * (SA_CustomAlert.buttonSpacing + SA_CustomAlert.buttonHeight)), SA_CustomAlert.viewWidth - SA_CustomAlert.viewMargin * 2, SA_CustomAlert.buttonHeight);
	}
}

- (void) addButtonAtIndex: (NSUInteger) index {
	CGRect				buttonFrame = [self frameForButtonAtIndex: index];
	CGRect				bounds = self.alertBaseView.bounds;
	UIButton			*button = [UIButton buttonWithType: UIButtonTypeCustom];
	
	button.frame = buttonFrame;
	button.backgroundColor = SA_CustomAlert.buttonBackgroundColor;
	[button setTitle: self.buttonTitles[index] forState: UIControlStateNormal];
	[button setTitleColor: SA_CustomAlert.buttonTitleColor forState: UIControlStateNormal];
	button.titleLabel.font = (index == self.defaultButtonIndex) ? SA_CustomAlert.defaultButtonFont : SA_CustomAlert.buttonFont;
	button.titleLabel.adjustsFontSizeToFitWidth	= YES;
	button.titleLabel.minimumScaleFactor = 0.75;
	button.showsTouchWhenHighlighted = YES;
	button.tag = index;
	[button addTarget: self action: @selector(alertButtonTouched:) forControlEvents: UIControlEventTouchUpInside];
	[self.alertBaseView addSubview: button];
	
	if (self.buttons == nil) self.buttons = [NSMutableArray new];
	[self.buttons addObject: button];
	
	if (self.numberOfButtonRows != self.buttonTitles.count && index % 2) {
		[self.backgroundView addSeparatorLineFrom: CGPointMake(bounds.size.width / 2, buttonFrame.origin.y - 2) to: CGPointMake(bounds.size.width / 2, bounds.size.height)];
	} else
		[self.backgroundView addSeparatorLineFrom: CGPointMake(0, buttonFrame.origin.y - 2) to: CGPointMake(bounds.size.width, buttonFrame.origin.y - 2)];
}

//================================================================================================================
#pragma mark Class properties
+ (void) setTitleFont: (UIFont *) font { s_titleFont = font; }
+ (UIFont *) titleFont { return s_titleFont; }

+ (void) setMessageFont: (UIFont *) font { s_messageFont = font; }
+ (UIFont *) messageFont { return s_messageFont; }

+ (void) setViewWidth: (CGFloat) width { s_viewWidth = width; }
+ (CGFloat) viewWidth { return s_viewWidth; }

+ (void) setViewMargin: (CGFloat) margin { s_viewMargin = margin; }
+ (CGFloat) viewMargin { return s_viewMargin; }

+ (void) setTitleMessageSpacing: (CGFloat) spacing { s_titleMessageSpacing = spacing; }
+ (CGFloat) titleMessageSpacing { return s_titleMessageSpacing; }

+ (void) setMessageButtonSpacing: (CGFloat) spacing { s_messageButtonSpacing = spacing; }
+ (CGFloat) messageButtonSpacing { return s_messageButtonSpacing; }

+ (void) setButtonHeight: (CGFloat) height { s_buttonHeight = height; }
+ (CGFloat) buttonHeight { return s_buttonHeight; }

+ (void) setButtonSpacing: (CGFloat) spacing { s_buttonSpacing = spacing; }
+ (CGFloat) buttonSpacing { return s_buttonSpacing; }

+ (void) setBackgroundColor: (UIColor *) color { s_backgroundColor = color; }
+ (UIColor *) backgroundColor { return s_backgroundColor; }

+ (void) setTitleColor: (UIColor *) color { s_titleColor = color; }
+ (UIColor *) titleColor { return s_titleColor; }

+ (void) setMessageColor: (UIColor *) color { s_messageColor = color; }
+ (UIColor *) messageColor { return s_messageColor; }

+ (void) setButtonBackgroundColor: (UIColor *) color { s_buttonBackgroundColor = color; }
+ (UIColor *) buttonBackgroundColor { return s_buttonBackgroundColor; }

+ (void) setButtonTitleColor: (UIColor *) color { s_buttonTitleColor = color; }
+ (UIColor *) buttonTitleColor { return s_buttonTitleColor; }

+ (void) setDefaultButtonTitleColor: (UIColor *) color { s_defaultButtonTitleColor = color; }
+ (UIColor *) defaultButtonTitleColor { return s_defaultButtonTitleColor; }

+ (void) setButtonFont: (UIFont *) font { s_buttonFont = font; }
+ (UIFont *) buttonFont { return s_buttonFont; }

+ (void) setDefaultButtonFont: (UIFont *) font { s_defaultButtonFont = font; }
+ (UIFont *) defaultButtonFont { return s_defaultButtonFont; }

+ (void) setShowAlertDuration: (NSTimeInterval) interval { s_showAlertDuration = interval; }
+ (NSTimeInterval) showAlertDuration { return s_showAlertDuration; }

+ (void) setHideAlertDuration: (NSTimeInterval) interval { s_hideAlertDuration = interval; }
+ (NSTimeInterval) hideAlertDuration { return s_hideAlertDuration; }

+ (void) setButtonSeparatorColor: (UIColor *) color { s_buttonSeparatorColor = color; }
+ (UIColor *) buttonSeparatorColor { return s_buttonSeparatorColor; }

+ (void) setUseStandardAlerts: (BOOL) useStandard { s_useStandardAlerts = useStandard; }
+ (BOOL) useStandardAlerts { return s_useStandardAlerts; }

@end



//================================================================================================================
#pragma mark UIWindow additions


@implementation UIWindow (SA_CustomAlert)
+ (UIWindow *) alertWindow {
	if (s_alertWindow == nil) {
		CGRect					frame = [UIScreen mainScreen].bounds;
		
		s_alertWindow = [[UIWindow alloc] initWithFrame: frame];
		s_alertWindow.backgroundColor = [UIColor clearColor];
		s_alertWindow.windowLevel = UIWindowLevelAlert;
		s_alertWindow.userInteractionEnabled = YES;
		s_alertWindow.opaque = NO;
		
		s_blockingView = [[SA_CustomAlertBlockerView alloc] initWithFrame: CGRectFromSize(frame.size)];
		s_blockingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		s_blockingView.alpha = 0.0;
		s_blockingView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.25];
		[s_blockingView.layer setNeedsDisplay];
		[s_alertWindow addSubview: s_blockingView];
		
		[s_alertWindow makeKeyAndVisible];
	}
	return s_alertWindow;
}

+ (void) closeAlertWindow {
	s_alertWindow.hidden = YES;
	s_alertWindow = nil;
}

- (BOOL) isAlertWindow { return self == s_alertWindow; }

@end

//=============================================================================================================================
#pragma mark Background view

@implementation SA_CustomAlertBackgroundView
- (void) drawRect: (CGRect) rect {
	[SA_CustomAlert.backgroundColor setFill];
	[SA_CustomAlert.backgroundColor setStroke];
	[[UIBezierPath bezierPathWithRoundedRect: self.bounds cornerRadius: 12] fill];
	
	UIColor				*separatorColor = SA_CustomAlert.buttonSeparatorColor;
	[separatorColor setStroke];
	
	for (UIBezierPath *path in self.separatorLines) {
		if (separatorColor) {
			[path strokeWithBlendMode: kCGBlendModeNormal alpha: 1.0];
		} else {
			[path strokeWithBlendMode: kCGBlendModeClear alpha: 1.0];

			[path strokeWithBlendMode: kCGBlendModeNormal alpha: 0.25];
		}
	}
}

- (void) addSeparatorLineFrom: (CGPoint) start to: (CGPoint) end {
	if (self.separatorLines == nil) self.separatorLines = [NSMutableArray array];
	
	UIBezierPath		*path = [UIBezierPath bezierPath];
	
	[path moveToPoint: start];
	[path addLineToPoint: end];

	[self.separatorLines addObject: path];
	[self setNeedsDisplay];
}
@end

//=============================================================================================================================
#pragma mark Blocker view
@implementation SA_CustomAlertBlockerView
+ (Class) layerClass { return [SA_CustomAlertBlockerLayer class]; }
@end

@implementation SA_CustomAlertBlockerLayer
- (void) drawInContext: (CGContextRef) ctx {
	CGContextDrawRadialGradientInRect(ctx, self.bounds, [UIColor clearColor], [UIColor blackColor]);
}
@end