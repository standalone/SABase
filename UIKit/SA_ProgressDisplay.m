//
//  SA_ProgressDisplay.m
//  RESTFramework Harness
//
//  Created by Ben Gottlieb on 5/26/14.
//  Copyright (c) 2014 Stand Alone, Inc. All rights reserved.
//

#import "SA_ProgressDisplay.h"
#import "UIWindow+SA_Additions.h"
#import "dispatch_additions_SA.h"
#import "CGContextRef_additions.h"
#import "SA_ProgressView.h"

#define LINEAR_PROGRESS_COMPONENT_SIZE			20
#define ROUND_PROGRESS_COMPONENT_SIZE			60

@interface SA_ProgressDisplayBackgroundView : UIView
@end

@interface SA_ProgressDisplayBlockerView : UIView
@end

@interface SA_ProgressDisplayBlockerLayer : CALayer
@end

@interface UIWindow (SA_ProgressDisplay)
+ (UIWindow *) progressDisplayWindow;
+ (void) closeProgressDisplayWindow;

@property (nonatomic, readonly) BOOL isProgressDisplayWindow;
@end

static UIWindow *s_progressWindow;
static SA_ProgressDisplayBlockerView *s_blockingView;
static SA_ProgressDisplay *s_progressDisplay;

static UIFont *s_titleFont, *s_detailFont, *s_buttonFont, *s_defaultButtonFont;
static UIColor *s_backgroundColor, *s_buttonBackgroundColor, *s_buttonTitleColor, *s_defaultButtonTitleColor, *s_titleColor, *s_detailColor;
static CGFloat s_viewWidth, s_viewMargin, s_detailButtonSpacing, s_titleDetailSpacing, s_buttonSpacing, s_buttonHeight, s_componentSpacing;

@interface SA_ProgressDisplay ()
@property (nonatomic, strong) UIView *progressBaseView;
@property (nonatomic, strong) UILabel						*titleLabel, *detailLabel;
@property (nonatomic, strong) UIActivityIndicatorView		*activityIndicatorView;
@property (nonatomic, strong) SA_ProgressView				*progressView;
@property (nonatomic, strong) UIButton						*button;
@end

@implementation SA_ProgressDisplay

+ (void) load {
	@autoreleasepool {
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(willChangeStatusBarOrientation:) name: UIApplicationWillChangeStatusBarOrientationNotification object: nil];
		
		self.titleFont = [UIFont boldSystemFontOfSize: 20.0];
		self.detailFont = [UIFont systemFontOfSize: 16.0];
		self.viewWidth = RUNNING_ON_IPAD ? 300 : 250.0;
		self.viewMargin = 10.0;
		self.buttonSpacing = 10;
		self.titleDetailSpacing = 10;
		self.detailButtonSpacing = 10;
		self.buttonHeight = 44;
		self.componentSpacing = 5;
				
		self.defaultButtonFont = [UIFont boldSystemFontOfSize: 20];
		self.buttonFont = [UIFont systemFontOfSize: 20];
		self.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.85];
		self.buttonBackgroundColor = [UIColor clearColor];
		self.buttonTitleColor = [UIColor whiteColor];
		self.titleColor = [UIColor whiteColor];
		self.detailColor = [UIColor colorWithWhite: 0.92 alpha: 1.0];
	}
}

+ (instancetype) progressDisplay { return s_progressDisplay; }

+ (instancetype) showProgressStyle: (SA_ProgressDisplay_style) style withTitle: (NSString *) title detail: (NSString *) detail {
	if (s_progressDisplay == nil) {
		s_progressDisplay = [self new];
		s_progressDisplay.style = SA_ProgressDisplay_style_activityIndicator;
		s_progressDisplay.roundProgressDiameter = ROUND_PROGRESS_COMPONENT_SIZE;
		s_progressDisplay.linearProgressHeight = LINEAR_PROGRESS_COMPONENT_SIZE;
	}
	
	dispatch_async_main_queue(^{
		if (style != SA_ProgressDisplay_style_unchanged) s_progressDisplay.style = style;
		s_progressDisplay.title = title;
		s_progressDisplay.detail = detail;
		
		if (!s_progressDisplay.isVisible) [s_progressDisplay show: YES];
	});
	
	return s_progressDisplay;
}

- (instancetype) addButtonWithTitle: (NSString *) title andBlock: (simpleBlock) block {
	dispatch_async_main_queue(^{
		self.buttonTitle = title;
		self.buttonBlock = block;
		
		[self.button setTitle: title forState: UIControlStateNormal];
		[self.progressBaseView addSubview: self.button];

		[self updateFrame: YES];
	});
	return self;
}


//================================================================================================================
#pragma mark Actions
- (void) show: (BOOL) animated {
	dispatch_async_main_queue(^{
		if (self.isVisible) return;

		[[UIWindow progressDisplayWindow] addSubview: self.progressBaseView];
		if (animated) {
			CGFloat						duration = 0.2;
			
			self.progressBaseView.alpha = 0.0;
			self.progressBaseView.transform = CGAffineTransformScale(UIWindow.sa_transformForCurrentUserInterfaceOrientation, 0.001, 0.001);
			
			[UIView animateWithDuration: duration delay: 0.0 usingSpringWithDamping: 0.8 initialSpringVelocity: 0.0 options: UIViewAnimationOptionCurveEaseOut animations:^{
				self.progressBaseView.transform = UIWindow.sa_transformForCurrentUserInterfaceOrientation;
				s_blockingView.alpha = 1.0;
				self.progressBaseView.alpha = 1.0;
			} completion:^(BOOL finished) {
				
			}];
		}
	});
}

- (void) hide: (BOOL) animated {
	dispatch_async_main_queue(^{
		if (animated) {
			CGFloat						duration = 0.2;

			[UIView animateWithDuration: duration delay: 0.0 usingSpringWithDamping: 1.0 initialSpringVelocity: 0.0 options: UIViewAnimationOptionCurveEaseIn animations:^{
				self.progressBaseView.transform = CGAffineTransformScale(UIWindow.sa_transformForCurrentUserInterfaceOrientation, 0.001, 0.001);;
				self.progressBaseView.alpha = 0.0;
				s_blockingView.alpha = 0.0;
			} completion: ^(BOOL finished) {
				self.title = nil;
				self.buttonTitle = nil;
				self.detail = nil;
				
				[UIWindow closeProgressDisplayWindow];
				s_progressDisplay = nil;
			}];
		} else {
			[UIWindow closeProgressDisplayWindow];
			self.title = nil;
			self.buttonTitle = nil;
			self.detail = nil;
			s_progressDisplay = nil;
		}
	});
}


//================================================================================================================
#pragma mark Properties
- (UIView *) progressBaseView {
	if (_progressBaseView == nil) {
		_progressBaseView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, SA_ProgressDisplay.viewWidth, [self viewHeight])];
		_progressBaseView.backgroundColor = SA_ProgressDisplay.backgroundColor;
		_progressBaseView.transform = [UIWindow sa_transformForCurrentUserInterfaceOrientation];
		_progressBaseView.layer.cornerRadius = 15;
		_progressBaseView.layer.masksToBounds = YES;
		_progressBaseView.center = [UIWindow progressDisplayWindow].contentCenter;
		
		[_progressBaseView addSubview: self.titleLabel];
		[_progressBaseView addSubview: self.detailLabel];
	}
	
	return _progressBaseView;
}

- (CGFloat) viewHeight {
	CGFloat					baseHeight = 150;
	
	if (self.buttonTitle) baseHeight += SA_ProgressDisplay.buttonHeight + SA_ProgressDisplay.detailButtonSpacing;
	if (self.style == SA_ProgressDisplay_style_activityIndicator || self.style == SA_ProgressDisplay_style_linearProgressAndActivityIndicator) baseHeight += s_progressDisplay.roundProgressDiameter + SA_ProgressDisplay.componentSpacing;
	if (self.style == SA_ProgressDisplay_style_roundProgress) baseHeight += self.roundProgressDiameter + SA_ProgressDisplay.componentSpacing;
	if (self.style == SA_ProgressDisplay_style_linearProgressAndActivityIndicator || self.style == SA_ProgressDisplay_style_linearProgress) baseHeight += self.linearProgressHeight + SA_ProgressDisplay.componentSpacing;
	
	return baseHeight;
}

- (CGRect) titleFrame {
	CGFloat				margin = SA_ProgressDisplay.viewMargin;
	CGFloat				top = margin;
	
	if (self.labelPlacement == SA_ProgressDisplay_labelPlacement_bottom) {
		top = self.viewHeight - self.bottomContentHeight;
	}
	return CGRectMake(margin, top, SA_ProgressDisplay.viewWidth - margin * 2, ceilf(SA_ProgressDisplay.titleFont.lineHeight * 1.1));
}

- (CGFloat) bottomContentHeight {
	CGFloat				height = SA_ProgressDisplay.viewMargin;
	
	if (_buttonTitle.length) height += (SA_ProgressDisplay.buttonHeight + SA_ProgressDisplay.detailButtonSpacing);
	
	switch (self.labelPlacement) {
		case SA_ProgressDisplay_labelPlacement_topAndBottom:
			height += SA_ProgressDisplay.detailFont.lineHeight;
			break;
			
		case SA_ProgressDisplay_labelPlacement_top:
			break;
			
		case SA_ProgressDisplay_labelPlacement_bottom:
			height += (SA_ProgressDisplay.detailFont.lineHeight + SA_ProgressDisplay.titleFont.lineHeight + SA_ProgressDisplay.titleDetailSpacing);
			break;
	}
	
	return height;
}

- (CGFloat) topContentHeight {
	CGFloat				height = SA_ProgressDisplay.viewMargin;
		
	switch (self.labelPlacement) {
		case SA_ProgressDisplay_labelPlacement_topAndBottom:
			height += SA_ProgressDisplay.detailFont.lineHeight;
			break;
			
		case SA_ProgressDisplay_labelPlacement_top:
			height += SA_ProgressDisplay.detailFont.lineHeight + SA_ProgressDisplay.titleFont.lineHeight + SA_ProgressDisplay.titleDetailSpacing;
			break;
			
		case SA_ProgressDisplay_labelPlacement_bottom:
			break;
	}
	
	return height;
}

- (CGRect) detailFrame {
	CGFloat						lineHeight = SA_ProgressDisplay.detailFont.lineHeight;
	CGFloat						top = self.viewHeight - (lineHeight + SA_ProgressDisplay.viewMargin);

	if (self.labelPlacement == SA_ProgressDisplay_labelPlacement_top) {
		top = SA_ProgressDisplay.viewMargin + SA_ProgressDisplay.titleFont.lineHeight + SA_ProgressDisplay.titleDetailSpacing;
	} else if (self.buttonTitle)
		top -= (SA_ProgressDisplay.detailButtonSpacing + SA_ProgressDisplay.buttonHeight);
				
	return CGRectMake(SA_ProgressDisplay.viewMargin, top, SA_ProgressDisplay.viewWidth - SA_ProgressDisplay.viewMargin * 2, lineHeight);
}

- (CGRect) buttonFrame {
	CGFloat					buttonWidth = ceilf([self.buttonTitle sizeWithAttributes: @{ NSFontAttributeName: SA_ProgressDisplay.buttonFont }].width * 1.4);
	CGFloat					top = ceilf([self viewHeight] - (SA_ProgressDisplay.viewMargin + SA_ProgressDisplay.buttonHeight));
	
	return CGRectMake((SA_ProgressDisplay.viewWidth - buttonWidth) / 2, top, buttonWidth, SA_ProgressDisplay.buttonHeight);
}

- (UILabel *) titleLabel {
	if (_titleLabel == nil) {
		_titleLabel = [[UILabel alloc] initWithFrame: self.titleFrame];
		_titleLabel.font = SA_ProgressDisplay.titleFont;
		_titleLabel.textColor = SA_ProgressDisplay.titleColor;
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.text = self.title;
		_titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
		_titleLabel.textAlignment = NSTextAlignmentCenter;
	}
	return _titleLabel;
}

- (UILabel *) detailLabel {
	if (_detailLabel == nil) {
		_detailLabel = [[UILabel alloc] initWithFrame: self.detailFrame];
		_detailLabel.font = SA_ProgressDisplay.detailFont;
		_detailLabel.textColor = SA_ProgressDisplay.detailColor;
		_detailLabel.text = self.detail;
		_detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		_detailLabel.textAlignment = NSTextAlignmentCenter;
	}
	return _detailLabel;
}

- (BOOL) isVisible { return _progressBaseView.superview != nil; }

- (void) setStyle: (SA_ProgressDisplay_style) style {
	if (style == _style) return;
	
	_style = style;
		
	dispatch_async_main_queue(^{
		switch (style) {
			case SA_ProgressDisplay_style_labelsOnly:
				_activityIndicatorView.hidden = YES;
				_progressView.hidden = YES;
				break;
				
			case SA_ProgressDisplay_style_activityIndicator:
				self.activityIndicatorView.hidden = NO;
				[self.progressBaseView addSubview: self.activityIndicatorView];
				_progressView.hidden = YES;
				break;
				
			case SA_ProgressDisplay_style_linearProgress:
				_activityIndicatorView.hidden = YES;
				self.progressView.hidden = NO;
				self.progressView.type = SA_ProgressView_linear;
				self.progressView.frame = self.progressFrame;
				[self.progressBaseView addSubview: self.progressView];
				break;
				
			case SA_ProgressDisplay_style_linearProgressAndActivityIndicator:
				self.activityIndicatorView.hidden = NO;
				[self.progressBaseView addSubview: self.activityIndicatorView];
				self.progressView.hidden = NO;
				self.progressView.type = SA_ProgressView_linear;
				self.progressView.frame = self.progressFrame;
				[self.progressBaseView addSubview: self.progressView];
				break;
				
			case SA_ProgressDisplay_style_roundProgress:
				_activityIndicatorView.hidden = YES;
				self.progressView.hidden = NO;
				self.progressView.frame = self.progressFrame;
				self.progressView.type = SA_ProgressView_round;
				[self.progressBaseView addSubview: self.progressView];
				break;
				
			default:
				break;
		}
		
		[self updateFrame: YES];
	});
}

- (void) updateFrame: (BOOL) animated {
	dispatch_on_main_queue(^{
		NSTimeInterval							duration = animated ? 0.2 : 0.0;
		
		[UIView animateWithDuration: duration animations: ^{
			self.progressBaseView.bounds = CGRectMake(0, 0, SA_ProgressDisplay.viewWidth, self.viewHeight);
			
			self.titleLabel.frame = self.titleFrame;
			self.button.frame = self.buttonFrame;
			self.detailLabel.frame = self.detailFrame;
			
			_activityIndicatorView.center = self.activityIndicatorCenter;
			
			if (self.style == SA_ProgressDisplay_style_linearProgress || self.style == SA_ProgressDisplay_style_linearProgressAndActivityIndicator || self.style == SA_ProgressDisplay_style_roundProgress) self.progressView.frame = self.progressFrame;
		} completion:^(BOOL finished) {
		}];
	});
}

- (void) setRoundProgressDiameter:(CGFloat)roundProgressDiameter { _roundProgressDiameter = roundProgressDiameter; [self updateFrame: self.isVisible]; }
- (void) setLinearProgressHeight:(CGFloat)linearProgressHeight { _linearProgressHeight = linearProgressHeight; [self updateFrame: self.isVisible]; }

- (void) setTitle: (NSString *) title {
	_title = title;
	if (_titleLabel) dispatch_async_main_queue(^{ self.titleLabel.text = title; });
}

- (void) setDetail: (NSString *) detail {
	_detail = detail;
	if (self.isVisible) dispatch_async_main_queue(^{ self.detailLabel.text = detail; });
}

- (CGPoint) activityIndicatorCenter {
	CGFloat					contentHeight = self.bottomContentHeight + self.topContentHeight;
	CGFloat					y = (self.viewHeight - contentHeight) / 2;
	
	switch (self.labelPlacement) {
		case SA_ProgressDisplay_labelPlacement_topAndBottom: y += self.topContentHeight; break;
			
		case SA_ProgressDisplay_labelPlacement_top:
			y += contentHeight;
			if (_buttonTitle.length) y -= (SA_ProgressDisplay.buttonHeight + SA_ProgressDisplay.detailButtonSpacing);
			break;
			
		case SA_ProgressDisplay_labelPlacement_bottom:
			break;
	}
	
	return CGPointMake(SA_ProgressDisplay.viewWidth / 2, y);
}

- (UIActivityIndicatorView *) activityIndicatorView {
	if (_activityIndicatorView == nil) {
		_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
		_activityIndicatorView.center = self.activityIndicatorCenter;
		_activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
		[_activityIndicatorView startAnimating];
	}
	return _activityIndicatorView;
}

- (void) setPercentageComplete: (CGFloat) percentageComplete {
	self.progressView.progress = percentageComplete;
}

- (CGRect) progressFrame {
	CGFloat						parentWidth = SA_ProgressDisplay.viewWidth;
	CGFloat						width = parentWidth * 0.6, height = self.linearProgressHeight;
	
	if (self.style == SA_ProgressDisplay_style_roundProgress) {
		width = self.roundProgressDiameter;
		height = self.roundProgressDiameter;
	} else
		height = self.linearProgressHeight;
	 
	
	CGPoint						center = self.activityIndicatorCenter;
	
	return CGRectMake(center.x - width / 2, center.y - height / 2, width, height);
}

- (SA_ProgressView *) progressView {
	if (_progressView == nil) {
		_progressView = [[SA_ProgressView alloc] initWithFrame: self.progressFrame];
		_progressView.progress = self.percentageComplete;
		_progressView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
	}
	return _progressView;
}

- (UIButton *) button {
	if (_button == nil) {
		_button = [UIButton buttonWithType: UIButtonTypeCustom];
		[_button setTitle: self.buttonTitle forState: UIControlStateNormal];
		_button.frame = self.buttonFrame;
		_button.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
		_button.backgroundColor = SA_ProgressDisplay.buttonBackgroundColor;
		[_button setTitleColor: SA_ProgressDisplay.buttonTitleColor forState: UIControlStateNormal];
		_button.showsTouchWhenHighlighted = YES;
		_button.layer.borderColor = [SA_ProgressDisplay.buttonTitleColor colorWithAlphaComponent: 0.5].CGColor;
		_button.layer.borderWidth = 1.0;
		_button.layer.cornerRadius = 6;
		_button.layer.masksToBounds = YES;
		[_button addTarget: self action: @selector(buttonPressed:) forControlEvents: UIControlEventTouchUpInside];
	}
	return _button;
}

- (void) buttonPressed: (UIButton *) button {
	if (self.buttonBlock) self.buttonBlock();
}

//================================================================================================================
#pragma mark Notifications
+ (void) willChangeStatusBarOrientation: (NSNotification *) note {
	UIInterfaceOrientation		newOrientation = [note.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
	CGAffineTransform			newTransform = [UIWindow sa_transformForUserInterfaceOrientation: newOrientation];
	
	[UIView animateWithDuration: 0.2 animations:^{
		s_progressDisplay.progressBaseView.transform = newTransform;
	}];
}



//================================================================================================================
#pragma mark Class properties
+ (void) setTitleFont: (UIFont *) font { s_titleFont = font; }
+ (UIFont *) titleFont { return s_titleFont; }

+ (void) setDetailFont: (UIFont *) font { s_detailFont = font; }
+ (UIFont *) detailFont { return s_detailFont; }

+ (void) setViewWidth: (CGFloat) width { s_viewWidth = width; }
+ (CGFloat) viewWidth { return s_viewWidth; }

+ (void) setViewMargin: (CGFloat) margin { s_viewMargin = margin; }
+ (CGFloat) viewMargin { return s_viewMargin; }

+ (void) setTitleDetailSpacing: (CGFloat) spacing { s_titleDetailSpacing = spacing; }
+ (CGFloat) titleDetailSpacing { return s_titleDetailSpacing; }

+ (void) setDetailButtonSpacing: (CGFloat) spacing { s_detailButtonSpacing = spacing; }
+ (CGFloat) detailButtonSpacing { return s_detailButtonSpacing; }

+ (void) setButtonHeight: (CGFloat) height { s_buttonHeight = height; }
+ (CGFloat) buttonHeight { return s_buttonHeight; }

+ (void) setButtonSpacing: (CGFloat) spacing { s_buttonSpacing = spacing; }
+ (CGFloat) buttonSpacing { return s_buttonSpacing; }

+ (void) setComponentSpacing: (CGFloat) spacing { s_componentSpacing = spacing; }
+ (CGFloat) componentSpacing { return s_componentSpacing; }

+ (void) setBackgroundColor: (UIColor *) color { s_backgroundColor = color; }
+ (UIColor *) backgroundColor { return s_backgroundColor; }

+ (void) setTitleColor: (UIColor *) color { s_titleColor = color; }
+ (UIColor *) titleColor { return s_titleColor; }

+ (void) setDetailColor: (UIColor *) color { s_detailColor = color; }
+ (UIColor *) detailColor { return s_detailColor; }

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

@end




//================================================================================================================
#pragma mark UIWindow additions


@implementation UIWindow (SA_ProgressDisplay)
+ (UIWindow *) progressDisplayWindow {
	if (s_progressWindow == nil) {
		CGRect					frame = [UIScreen mainScreen].bounds;
		
		s_progressWindow = [[UIWindow alloc] initWithFrame: frame];
		s_progressWindow.backgroundColor = [UIColor clearColor];
		s_progressWindow.windowLevel = UIWindowLevelAlert - 1.0;
		s_progressWindow.userInteractionEnabled = YES;
		s_progressWindow.opaque = NO;
		
		s_blockingView = [[SA_ProgressDisplayBlockerView alloc] initWithFrame: CGRectFromSize(frame.size)];
		s_blockingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		s_blockingView.alpha = 0.0;
		s_blockingView.backgroundColor = [UIColor colorWithWhite: 0.0 alpha: 0.25];
		[s_blockingView.layer setNeedsDisplay];
		[s_progressWindow addSubview: s_blockingView];
		
		[s_progressWindow makeKeyAndVisible];
	}
	return s_progressWindow;
}

+ (void) closeProgressDisplayWindow {
	s_progressWindow.hidden = YES;
	s_progressWindow = nil;
}

- (BOOL) isProgressDisplayWindow { return self == s_progressWindow; }

@end


//=============================================================================================================================
#pragma mark Background view

@implementation SA_ProgressDisplayBackgroundView
- (void) drawRect: (CGRect) rect {
	[SA_ProgressDisplay.backgroundColor setFill];
	[SA_ProgressDisplay.backgroundColor setStroke];
	[[UIBezierPath bezierPathWithRoundedRect: self.bounds cornerRadius: 12] fill];
}

@end

//=============================================================================================================================
#pragma mark Blocker view
@implementation SA_ProgressDisplayBlockerView
+ (Class) layerClass { return [SA_ProgressDisplayBlockerLayer class]; }
@end

@implementation SA_ProgressDisplayBlockerLayer
- (void) drawInContext: (CGContextRef) ctx {
	CGContextDrawRadialGradientInRect(ctx, self.bounds, [UIColor clearColor], [UIColor blackColor]);
}
@end