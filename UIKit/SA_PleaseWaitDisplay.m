//
//  SA_PleaseWaitDisplay.m
//
//  Created by Ben Gottlieb on 4/3/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "SA_PleaseWaitDisplay.h"
#import "NSString+SA_Additions.h"
#import "dispatch_additions_SA.h"
#import "NSObject+SA_Additions.h"
#import "UIDevice+SA_Additions.h"
#import "UIView+SA_Additions.h"

#define		kLabelBackgroundColor				[UIColor clearColor]

static SA_PleaseWaitDisplay *s_pleaseWaitDisplay = nil;
static NSString *g_cancelButtonImageName = @"black-button.png";
static NSString *g_cancelButtonImagePressedName = @"black-button-highlight.png";
static NSString *g_auxButtonImageName = @"black-button.png";
static NSString *g_auxButtonImagePressedName = @"black-button-highlight.png";

@implementation SA_PleaseWaitDisplay
@synthesize cancelTitle = _cancelTitle, auxTitle = _auxTitle, minorText = _minorText, majorText = _majorText, delegate = _delegate, view = _view, spinnerHidden = _spinnerHidden, progressBarHidden = _progressBarHidden, majorFont = _majorFont, minorFont = _minorFont;
@synthesize currentOrientation = _currentOrientation, cancelBlock = _cancelBlock;


+ (SA_PleaseWaitDisplay *) showPleaseWaitDisplay: (NSString *) major {
	return [self showPleaseWaitDisplayWithMajorText: major minorText: nil cancelLabel: nil showProgressBar: NO delegate: nil];
}

+ (SA_PleaseWaitDisplay *) showPleaseWaitDisplayWithMajorText: (NSString *) major minorText: (NSString *) minor cancelLabel: (NSString *) cancel showProgressBar: (BOOL) showProgressBar delegate: (id <SA_PleaseWaitDisplayDelegate>) delegate {

	if (s_pleaseWaitDisplay == nil) {
		s_pleaseWaitDisplay = [[self alloc] init];
		s_pleaseWaitDisplay.currentOrientation = [UIDevice currentDevice].userInterfaceOrientation;
		[s_pleaseWaitDisplay addAsObserverForName: UIDeviceOrientationDidChangeNotification selector: @selector(deviceOrientationDidChange:)];
		s_pleaseWaitDisplay->_hidden = YES;
	}
	

	simpleBlock				block = ^{
		if (s_pleaseWaitDisplay == nil) return;
		s_pleaseWaitDisplay.view.layer.zPosition = 100;
		s_pleaseWaitDisplay.majorText = major;
		s_pleaseWaitDisplay.minorText = minor;
		s_pleaseWaitDisplay.cancelTitle = cancel;
		s_pleaseWaitDisplay.delegate = delegate;
		if (s_pleaseWaitDisplay == nil) return;
		s_pleaseWaitDisplay->_progressBarHidden = !showProgressBar;
		s_pleaseWaitDisplay.spinnerHidden = showProgressBar;					//if there's a progress max, we hide the spinner
		s_pleaseWaitDisplay->_majorLabelPositionedWithSpinner = !s_pleaseWaitDisplay.spinnerHidden;
		s_pleaseWaitDisplay.minorFont = [UIFont systemFontOfSize: 15];
		s_pleaseWaitDisplay.majorFont = [UIFont boldSystemFontOfSize: 17];
		[s_pleaseWaitDisplay performSelector: @selector(display) withObject: nil afterDelay: 0.0];
	};
	
	dispatch_async_main_queue(block);
		
	return s_pleaseWaitDisplay;
}

+ (void) hidePleaseWaitDisplay {
	[s_pleaseWaitDisplay performSelectorOnMainThread: @selector(hide) withObject: nil waitUntilDone: NO];
}

+ (SA_PleaseWaitDisplay *) pleaseWaitDisplay {
	return s_pleaseWaitDisplay;
}

+ (void) setCancelButtonImageName: (NSString *) name withPressedImageName: (NSString *) pressed {
	g_cancelButtonImageName = name;
	g_cancelButtonImagePressedName = pressed;
}

+ (void) setAuxButtonImageName: (NSString *) name withPressedImageName: (NSString *) pressed {
	g_auxButtonImageName = name;
	g_auxButtonImagePressedName = pressed;
}

//=============================================================================================================================
#pragma mark Properties
- (void) hide {
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(display) object: nil];
	if (self.hidden) return;
	
	_hidden = YES;
	self.delegate = nil;
	self.cancelBlock = nil;
	
	[UIView beginAnimations: nil context: nil];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration: 0.1];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
	self.view.alpha = 0.0;
	[UIView commitAnimations];
	
	s_pleaseWaitDisplay = nil; 	
}
- (BOOL) hidden {return (_hidden);}
- (void) setProgressValueAsNumber: (NSNumber *) number {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self setProgressValueAsNumber: number]; });
		return;
	}
	[self setProgressValue: [number floatValue]];
}

- (void) setProgressValue: (float) value {
	if (value && _progressBarHidden) [self setProgressBarHidden: NO];
	_progressIndicator.progress = value;
}

- (void) setProgressBarHidden: (BOOL) hidden {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self setProgressBarHidden: hidden]; });
		return;
	}
	if (!hidden && _progressBarHidden) {
		_progressBarHidden = NO;
		_spinnerHidden = YES;
		_majorLabelPositionedWithSpinner = NO;
		
		[_majorLabel removeFromSuperview];
		_majorLabel = nil;
		[self setupProgressIndicator];
		_progressIndicator.alpha = 0.0;
		
		[UIView beginAnimations: nil context: nil];
		[UIView setAnimationDuration: 0.1];
		[self setupSpinner];
		[self setupMajorLabel];
		_progressIndicator.alpha = 1.0;
		[UIView commitAnimations];
	} else if (hidden) {
		_progressBarHidden = YES;
		_progressIndicator.hidden = YES;
	}
	_progressBarHidden = hidden;
}

- (float) progressValue {return _progressIndicator.progress;}
- (void) setAuxTitle: (NSString *) title {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self setAuxTitle: title]; });
		return;
	}
	_auxTitle = title;
	if (!self.hidden) [self setupButtons];
}

- (void) setCancelTitle: (NSString *) title {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self setCancelTitle: title]; });
		return;
	}

	_cancelTitle = title;
	if (!self.hidden) [self setupButtons];
}

- (void) setCancelBlock:(simpleBlock)cancelBlock {
	_cancelBlock = [cancelBlock copy];
	if (cancelBlock && self.cancelTitle == nil) self.cancelTitle = NSLocalizedString(@"Cancel", @"Cancel");
}

- (void) setMajorText: (NSString *) text {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self setMajorText: text]; });
		return;
	}

	_majorText = text;
	if (!self.hidden) [self setupMajorLabel];
}

- (void) setMinorText: (NSString *) text {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self setMinorText: text]; });
		return;
	}

	_minorText = text;
	if (!self.hidden) [self setupMinorLabel];
}

- (void) setMajorFont: (UIFont *) font {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self setMajorFont: font]; });
		return;
	}

	if (font == _majorFont) return;
	_majorFont = font;
	
	_majorLabel.font = font;
}

- (void) setMinorFont: (UIFont *) font {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self setMinorFont: font]; });
		return;
	}

	if (font == _minorFont) return;
	_minorFont = font;
	
	_minorLabel.font = font;
}

//=============================================================================================================================
#pragma mark Clean up
- (void) dealloc {
	[self removeAsObserver];
}

- (void) setDelegate: (id <SA_PleaseWaitDisplayDelegate>) delegate {
	_delegate = delegate;
}

//=============================================================================================================================
#pragma mark Properties
- (UIView *) sibling {
	UIWindow					*window = self.mainWindow;
	CGRect						screenFrame = [UIScreen mainScreen].bounds;
	
	for (UIView *view in window.subviews) {
		CGRect					frame = view.bounds;
		
		if (CGRectEqualToRect(frame, screenFrame)) return view;
	}
	
	UIView						*child = window.subviews.count ? [window.subviews objectAtIndex: 0] : window;
	return child;
}

- (CGRect) majorLabelFrame {
	CGRect							contentFrame = self.contentFrame;
	float							labelTop = contentFrame.origin.y + (RUNNING_ON_IPAD ? contentFrame.size.height * 0.1 :  contentFrame.size.height * 0.3);
	CGRect							bounds = CGRectMake(contentFrame.origin.x + 10, labelTop, contentFrame.size.width - 20, 21);

	[_majorLabel sizeToFit];

	if (_majorLabelPositionedWithSpinner) {
		float						textWidth = _majorLabel.bounds.size.width;
		float						spinnerWidth = 20, space = 10;
		float						textLeft = contentFrame.origin.x + (contentFrame.size.width - (textWidth + spinnerWidth + space)) / 2;
		
		bounds = CGRectMake(textLeft, labelTop, textWidth, 21);
	}
	
	return bounds;
	
}

- (CGRect) minorLabelBounds {
	CGRect							contentFrame = self.contentFrame;
	float							labelTop = contentFrame.origin.y + contentFrame.size.height - 70;
	
	labelTop -= 65;
	if (_auxTitle) labelTop -= 65;
	CGRect							frame = CGRectMake(contentFrame.origin.x + 10, labelTop, contentFrame.size.width - 20, 50);
	
	return frame;
}

- (CGRect) contentBounds {
	CGRect						newBounds = _view.bounds;
	
	if (RUNNING_ON_IPAD) {
		if (UIInterfaceOrientationIsPortrait(self.currentOrientation)) {
			newBounds.size.height -= 320;
			newBounds.size.width -= 120;
		} else {
			newBounds.size.width -= 400;
			newBounds.size.height -= 290;
		}
	}
		
	return newBounds;
}

- (CGRect) contentFrame {
	CGRect						bounds = self.contentBounds;
	
	bounds.origin.x = (self.view.bounds.size.width - bounds.size.width) / 2;
	bounds.origin.y = (self.view.bounds.size.height - bounds.size.height) / 2;
	
	return bounds;
}

- (CGRect) cancelButtonFrame {
	CGRect							contentFrame = self.contentFrame;
	float							margin = 20;
	float							width = MIN(200, contentFrame.size.width - margin * 2);
	
	return CGRectMake(contentFrame.origin.x + (contentFrame.size.width - width) / 2, contentFrame.origin.y + contentFrame.size.height - (margin + 44), width, 44);
}

- (CGRect) auxButtonFrame {
	CGRect							contentFrame = self.contentFrame;
	float							margin = 20;
	
	return CGRectMake(contentFrame.origin.x + margin, contentFrame.origin.y + contentFrame.size.height - 2 * (margin + 44), contentFrame.size.width - margin * 2, 44);
}

- (CGRect) spinnerFrame {
	CGRect						textFrame = self.majorLabelFrame;
	CGFloat						spinnerSize = 20;
	CGRect						spinnerFrame = CGRectMake(textFrame.origin.x + textFrame.size.width + 25, textFrame.origin.y + (textFrame.size.height - spinnerSize) / 2, spinnerSize, spinnerSize);

	return spinnerFrame;
}

- (CGRect) progressIndicatorFrame {
	CGRect				contentFrame = self.contentFrame;
	float				barTop = contentFrame.origin.y + contentFrame.size.height * 0.1 + 35;
	float				margin = 85;
	float				width = MIN(200, contentFrame.size.width - margin * 2);
	CGRect				frame = CGRectMake(contentFrame.origin.x + (contentFrame.size.width - width) / 2, barTop, width, 9);
	
	return frame;
}



//=============================================================================================================================
#pragma mark Setup
- (void) display {
	[UIView resignFirstResponder];
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self display]; });
		return;
	}
	
	UIWindow					*window = self.mainWindow;
	
	if (_view != nil) return;

	_hidden = NO;
	_view = [[UIView alloc] initWithFrame: CGRectZero];
	

	if (RUNNING_ON_IPAD) {
		_grayLayer = [CALayer layer];
		_grayLayer.bounds = self.contentBounds;
		
		_grayLayer.cornerRadius = 20;
		_grayLayer.position = _view.contentCenter;
		_grayLayer.backgroundColor = [UIColor colorWithWhite: 0.05 alpha: 0.85].CGColor;
		[_view.layer addSublayer: _grayLayer];
		
		_view.backgroundColor = [UIColor clearColor];
	} else {
		_view.backgroundColor = [UIColor colorWithWhite: 0.05 alpha: 0.85];
	}
	
	
	
	_view.alpha = 0.0;
	[self deviceOrientationDidChange: nil];

	[self setupMajorLabel];
	[self setupMinorLabel];
	[self setupButtons];
	[self setupSpinner];
	[self setupProgressIndicator];
	
	[window addSubview: self.view];
	[self setupBoundsAndTransform];
	
	[UIView beginAnimations: nil context: nil];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration: 0.1];
	_view.alpha = 1.0;
	[UIView commitAnimations];
}

- (UIWindow *) mainWindow {
	NSArray						*windows = [[UIApplication sharedApplication] windows];
	
	if (windows.count) return [windows objectAtIndex: 0];
	return [[UIApplication sharedApplication] keyWindow];
}

- (void) setupBoundsAndTransform {
//	_view.normalizedFrame = self.sibling.normalizedFrame;//[UIScreen mainScreen].bounds;
//	_view.transform = self.sibling.transform;
//	if (!RUNNING_ON_IPAD) return;

	
	CGRect					fullFrame = [[UIScreen mainScreen] bounds];
	CGAffineTransform		newTransform = CGAffineTransformIdentity;
	//UIView					*v = [self.mainWindow.subviews objectAtIndex: 0];
	float					maxDim = MAX(fullFrame.size.width, fullFrame.size.height), minDim = MIN(fullFrame.size.width, fullFrame.size.height);
	UIInterfaceOrientation	orientation = [UIDevice currentDevice].userInterfaceOrientation;
	
	switch (orientation) {
		case UIInterfaceOrientationPortrait:
			_view.bounds = CGRectMake(0, 0, minDim, maxDim);
			newTransform = kTransform_Portrait;//CGAffineTransformIdentity;
			break;
			
		case UIInterfaceOrientationLandscapeRight:
			_view.bounds = CGRectMake(0, 0, maxDim, minDim);
			newTransform = kTransform_LandscapeLeft;//CGAffineTransformMake(0, -1, 1, 0, 0, 0);
			break;
			
		case UIInterfaceOrientationLandscapeLeft:
			_view.bounds = CGRectMake(0, 0, maxDim, minDim);
			newTransform = kTransform_LandscapeRight;//CGAffineTransformMake(0, 1, -1, 0, 0, 0);
			break;
			
		case UIInterfaceOrientationPortraitUpsideDown:
			_view.bounds = CGRectMake(0, 0, minDim, maxDim);
			newTransform = kTransform_PortraitUpsideDown;//CGAffineTransformMake(-1, 0, 0, -1, 0, 0);
			break;
		default: break;
	}
	
//	_view.center = CGPointMake(_view.bounds.size.width / 2, _view.bounds.size.height / 2);
	_view.center = _view.superview.contentCenter;
	//SA_BASE_LOG(@"Tranform: %@ (theirs: %@)", NSStringFromCGAffineTransform(newTransform), NSStringFromCGAffineTransform(v.transform));
	if (RUNNING_ON_IPAD) _view.backgroundColor = [UIColor colorWithWhite: 0.2 alpha: 0.2];
	_view.transform = newTransform;
}

- (void) deviceOrientationDidChange: (NSNotification *) note {
	if (self.hidden) return;
	self.currentOrientation = [UIDevice currentDevice].userInterfaceOrientation;
	BOOL				animateTransition = (self.view.alpha > 0);
	
	if (animateTransition) {
		[UIView beginAnimations: nil context: nil];
		[UIView setAnimationDuration: 0.2];
	}
	[self setupBoundsAndTransform];
	if (RUNNING_ON_IPAD) {
		_grayLayer.bounds = self.contentBounds;
		_grayLayer.position = _view.contentCenter;
	}
	
	_majorLabel.normalizedFrame = self.majorLabelFrame;
	_minorLabel.normalizedFrame = self.minorLabelBounds;
	_cancelButton.normalizedFrame = self.cancelButtonFrame;
	_auxButton.normalizedFrame = self.auxButtonFrame;
	_spinner.normalizedFrame = self.spinnerFrame;	
	_progressIndicator.normalizedFrame = self.progressIndicatorFrame;
	if (animateTransition) [UIView commitAnimations];
}

- (void) setupMajorLabel {
	if (_majorLabel == nil) {			
		_majorLabel = [[UILabel alloc] initWithFrame: self.majorLabelFrame];
		_majorLabel.textAlignment = NSTextAlignmentCenter;
		_majorLabel.font = [self majorFont];
		_majorLabel.backgroundColor = kLabelBackgroundColor;
	}
	[self.view addSubview: _majorLabel];
	
	_majorLabel.text = _majorText;
	_majorLabel.normalizedFrame = self.majorLabelFrame;
	if (_majorLabelPositionedWithSpinner) [self setupSpinner];
	_majorLabel.textColor = [UIColor whiteColor];
}

- (void) setupMinorLabel {	
	if (_minorLabel == nil) {			
		_minorLabel = [[UILabel alloc] initWithFrame: self.minorLabelBounds];
		_minorLabel.textAlignment = NSTextAlignmentCenter;
		_minorLabel.font = [self minorFont];
		_minorLabel.backgroundColor = kLabelBackgroundColor;
		_minorLabel.lineBreakMode = NSLineBreakByWordWrapping;
		_minorLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		_minorLabel.numberOfLines = 20;
	}
	[self.view addSubview: _minorLabel];
	
	_minorLabel.text = _minorText;
	_minorLabel.textColor = [UIColor whiteColor];
}

- (void) setupButtons {
	if (_cancelTitle) {
		if (_cancelButton == nil) {
			_cancelButton = [UIButton buttonWithType: UIButtonTypeCustom];
			_cancelButton.normalizedFrame = self.cancelButtonFrame;
			_cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize: 16];
			[_cancelButton addTarget: self action: @selector(cancel:) forControlEvents: UIControlEventTouchUpInside];
			[_cancelButton setBackgroundImage: [[UIImage imageNamed: g_cancelButtonImageName] stretchableImageWithLeftCapWidth: 13 topCapHeight: 23] forState: UIControlStateNormal];
			[_cancelButton setBackgroundImage: [[UIImage imageNamed: g_cancelButtonImagePressedName] stretchableImageWithLeftCapWidth: 13 topCapHeight: 23] forState: UIControlStateHighlighted];
		}
		[self.view addSubview: _cancelButton];
		
		_cancelButton.hidden = NO;
		[_cancelButton setTitle: _cancelTitle forState: UIControlStateNormal];
	} else
		_cancelButton.hidden = YES;

	if (_auxTitle) {
		if (_auxButton == nil) {
			_auxButton = [UIButton buttonWithType: UIButtonTypeCustom];
			_auxButton.normalizedFrame = self.auxButtonFrame;
			_auxButton.titleLabel.font = [UIFont boldSystemFontOfSize: 16];
			[_auxButton addTarget: self action: @selector(auxAction:) forControlEvents: UIControlEventTouchUpInside];
			[_auxButton setBackgroundImage: [[UIImage imageNamed: g_auxButtonImageName] stretchableImageWithLeftCapWidth: 13 topCapHeight: 23] forState: UIControlStateNormal];
			[_auxButton setBackgroundImage: [[UIImage imageNamed: g_auxButtonImagePressedName] stretchableImageWithLeftCapWidth: 13 topCapHeight: 23] forState: UIControlStateHighlighted];
		}
		[self.view addSubview: _auxButton];
		_auxButton.hidden = NO;
		[_auxButton setTitle: _auxTitle forState: UIControlStateNormal];
	} else
		_auxButton.hidden = YES;
}

- (void) setupSpinner {
	if (!_spinnerHidden) {
		if (_spinner == nil) {
			_spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
			_spinner.hidesWhenStopped = YES;
		}
		[self.view addSubview: _spinner];
		_spinner.normalizedFrame = self.spinnerFrame;	
		[_spinner startAnimating];
	} else {
		[_spinner stopAnimating];
	}
	
}

- (void) setupProgressIndicator {
	if (!_progressBarHidden) {
		if (_progressIndicator == nil) {
			_progressIndicator = [[UIProgressView alloc] initWithProgressViewStyle: UIProgressViewStyleDefault];
			_progressIndicator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		}
		
		_progressIndicator.normalizedFrame = self.progressIndicatorFrame;
		if (_progressIndicator.superview == nil) [self.view addSubview: _progressIndicator];
		_progressIndicator.hidden = NO;
		_progressIndicator.progress = 0;
	} else
		_progressIndicator.hidden = YES;
}
//=============================================================================================================================
#pragma mark Fonts

//=============================================================================================================================
#pragma mark Actions
- (void) cancel: (id) sender {
	if (self.cancelBlock)
		self.cancelBlock();
	else if ([_delegate respondsToSelector: @selector(pleaseWaitCancelPressed)])
		[_delegate pleaseWaitCancelPressed];
}

- (void) auxAction: (id) sender {
	if ([_delegate respondsToSelector: @selector(pleaseWaitAuxPressed)]) [_delegate pleaseWaitAuxPressed];
}
//=============================================================================================================================
#pragma mark Callbacks
- (void) animationDidStop: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context {
	[_view removeFromSuperview];
}


@end
