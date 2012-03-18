//
//  SA_PleaseWaitDisplay.m
//
//  Created by Ben Gottlieb on 4/3/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "SA_PleaseWaitDisplay.h"
#import "UIView+Additions.h"
#import "UIDevice+Additions.h"

#import <QuartzCore/QuartzCore.h>

#define		kLabelBackgroundColor				[UIColor clearColor]

static SA_PleaseWaitDisplay *g_display = nil;
static NSString *g_cancelButtonImageName = @"custombuttonblacknormal.png";
static NSString *g_cancelButtonImagePressedName = @"custombuttonblackpressed.png";
static NSString *g_auxButtonImageName = @"custombuttonblacknormal.png";
static NSString *g_auxButtonImagePressedName = @"custombuttonblackpressed.png";

@implementation SA_PleaseWaitDisplay
@synthesize cancelTitle = _cancelTitle, auxTitle = _auxTitle, minorText = _minorText, majorText = _majorText, delegate = _delegate, view = _view, spinnerHidden = _spinnerHidden, progressBarHidden = _progressBarHidden, majorFont = _majorFont, minorFont = _minorFont;
@synthesize currentOrientation = _currentOrientation;
+ (id) showPleaseWaitDisplayWithMajorText: (NSString *) major minorText: (NSString *) minor cancelLabel: (NSString *) cancel showProgressBar: (BOOL) showProgressBar delegate: (id <SA_PleaseWaitDisplayDelegate>) delegate {
	if (g_display == nil) {
		g_display = [[self alloc] init];
		g_display.currentOrientation = [UIDevice currentDevice].userInterfaceOrientation;
		[[NSNotificationCenter defaultCenter] addObserver: g_display selector: @selector(deviceOrientationDidChange:) name: UIDeviceOrientationDidChangeNotification object: nil];
		g_display->_hidden = YES;
	}
	
	g_display.view.layer.zPosition = 100;
	g_display.majorText = major;
	g_display.minorText = minor;
	g_display.cancelTitle = cancel;
	g_display.delegate = delegate;
	g_display->_progressBarHidden = !showProgressBar;
	g_display.spinnerHidden = showProgressBar;					//if there's a progress max, we hide the spinner
	g_display->_majorLabelPositionedWithSpinner = !g_display.spinnerHidden;
	g_display.minorFont = [UIFont systemFontOfSize: 15];
	g_display.majorFont = [UIFont boldSystemFontOfSize: 17];
	
//	[g_display display];
	[g_display performSelector: @selector(display) withObject: nil afterDelay: 0.0];
	return g_display;
}

+ (void) hidePleaseWaitDisplay {
	[g_display performSelectorOnMainThread: @selector(hide) withObject: nil waitUntilDone: YES];
}

+ (SA_PleaseWaitDisplay *) pleaseWaitDisplay {
	return g_display;
}

+ (void) setCancelButtonImageName: (NSString *) name withPressedImageName: (NSString *) pressed {
	[g_cancelButtonImageName autorelease]; g_cancelButtonImageName = [name retain]; 
	[g_cancelButtonImagePressedName autorelease]; g_cancelButtonImagePressedName = [pressed retain]; 
}

+ (void) setAuxButtonImageName: (NSString *) name withPressedImageName: (NSString *) pressed {
	[g_auxButtonImageName autorelease]; g_auxButtonImageName = [name retain]; 
	[g_auxButtonImagePressedName autorelease]; g_auxButtonImagePressedName = [pressed retain]; 
}

//=============================================================================================================================
#pragma mark Properties
- (void) hide {
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(display) object: nil];
	if (self.hidden) return;
	
	_hidden = YES;
	
	[UIView beginAnimations: nil context: nil];
	[UIView setAnimationCurve: UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration: 0.1];
	[UIView setAnimationDelegate: self];
	[UIView setAnimationDidStopSelector: @selector(animationDidStop:finished:context:)];
	self.view.alpha = 0.0;
	[UIView commitAnimations];
	
	g_display = nil; 	
}
- (BOOL) hidden {return (_hidden);}
- (void) setProgressValueAsNumber: (NSNumber *) number {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread: @selector(setProgressValueAsNumber:) withObject: number waitUntilDone: NO];
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
		[self performSelectorOnMainThread: @selector(setProgressBarHidden:) withObject: hidden ? (id) kCFBooleanTrue : nil waitUntilDone: YES];
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
		[self performSelectorOnMainThread: @selector(setAuxTitle:) withObject: title waitUntilDone: YES];
		return;
	}
	[_auxTitle autorelease]; _auxTitle = [title retain];
	if (!self.hidden) [self setupButtons];
}

- (void) setCancelTitle: (NSString *) title {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread: @selector(setCancelTitle:) withObject: title waitUntilDone: YES];
		return;
	}

	[_cancelTitle autorelease]; _cancelTitle = [title retain];
	if (!self.hidden) [self setupButtons];
}

- (void) setMajorText: (NSString *) text {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread: @selector(setMajorText:) withObject: text waitUntilDone: YES];
		return;
	}

	[_majorText autorelease]; _majorText = [text retain];
	if (!self.hidden) [self setupMajorLabel];
}

- (void) setMinorText: (NSString *) text {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread: @selector(setMinorText:) withObject: text waitUntilDone: YES];
		return;
	}

	[_minorText autorelease]; _minorText = [text retain];
	if (!self.hidden) [self setupMinorLabel];
}

- (void) setMajorFont: (UIFont *) font {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread: @selector(setMajorFont:) withObject: font waitUntilDone: YES];
		return;
	}

	if (font == _majorFont) return;
	[_majorFont release];
	_majorFont = [font retain];
	
	_majorLabel.font = font;
}

- (void) setMinorFont: (UIFont *) font {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread: @selector(setMinorFont:) withObject: font waitUntilDone: YES];
		return;
	}

	if (font == _minorFont) return;
	[_minorFont release];
	_minorFont = [font retain];
	
	_minorLabel.font = font;
}

//=============================================================================================================================
#pragma mark Clean up
- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	[_minorFont release];
	[_majorFont release];
	[_view release];
	[_progressIndicator release];
	[_majorLabel release];
	[_minorLabel release];
	[_spinner release];
	[_cancelButton release];
	[_auxButton release];
	
	self.majorText = nil;
	self.minorText = nil;
	self.cancelTitle = nil;
	self.auxTitle = nil;
	self.delegate = nil;
	
	[super dealloc];
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

- (CGRect) majorLabelBounds {
	CGRect							contentFrame = self.contentFrame;
	float							labelTop = contentFrame.origin.y + (RUNNING_ON_IPAD ? contentFrame.size.height * 0.1 :  contentFrame.size.height * 0.3);
	CGRect							bounds = CGRectMake(contentFrame.origin.x + 10, labelTop, contentFrame.size.width - 20, 21);

	if (_majorLabelPositionedWithSpinner) {
		float						textWidth = [_majorText sizeWithFont: [self majorFont]].width;
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
	CGRect						spinnerFrame = _majorLabel.frame;
	CGSize						textSize = [_majorText sizeWithFont: _majorFont];
	
	spinnerFrame.origin.x = spinnerFrame.origin.x + (spinnerFrame.size.width / 2) + textSize.width / 2 + 20;
	spinnerFrame.size.width = 20;
	spinnerFrame.size.height = 20;
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
		[self performSelectorOnMainThread: @selector(display) withObject: nil waitUntilDone: NO];
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
	}
	
//	_view.center = CGPointMake(_view.bounds.size.width / 2, _view.bounds.size.height / 2);
	_view.center = _view.superview.contentCenter;
	//LOG(@"Tranform: %@ (theirs: %@)", NSStringFromCGAffineTransform(newTransform), NSStringFromCGAffineTransform(v.transform));
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
	
	_majorLabel.normalizedFrame = self.majorLabelBounds;
	_minorLabel.normalizedFrame = self.minorLabelBounds;
	_cancelButton.normalizedFrame = self.cancelButtonFrame;
	_auxButton.normalizedFrame = self.auxButtonFrame;
	_spinner.normalizedFrame = self.spinnerFrame;	
	_progressIndicator.normalizedFrame = self.progressIndicatorFrame;
	if (animateTransition) [UIView commitAnimations];
}

- (void) setupMajorLabel {
	if (_majorLabel == nil) {			
		_majorLabel = [[UILabel alloc] initWithFrame: self.majorLabelBounds];
		_majorLabel.textAlignment = UITextAlignmentCenter;
		_majorLabel.font = [self majorFont];
		_majorLabel.backgroundColor = kLabelBackgroundColor;
	}
	[self.view addSubview: _majorLabel];
	
	_majorLabel.text = _majorText;
	_majorLabel.normalizedFrame = self.majorLabelBounds;
	if (_majorLabelPositionedWithSpinner) [self setupSpinner];
	_majorLabel.textColor = [UIColor whiteColor];
}

- (void) setupMinorLabel {	
	if (_minorLabel == nil) {			
		_minorLabel = [[UILabel alloc] initWithFrame: self.minorLabelBounds];
		_minorLabel.textAlignment = UITextAlignmentCenter;
		_minorLabel.font = [self minorFont];
		_minorLabel.backgroundColor = kLabelBackgroundColor;
		_minorLabel.lineBreakMode = UILineBreakModeWordWrap;
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
			_cancelButton = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
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
			_auxButton = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
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
	if ([_delegate respondsToSelector: @selector(pleaseWaitCancelPressed)]) [_delegate pleaseWaitCancelPressed];
}

- (void) auxAction: (id) sender {
	if ([_delegate respondsToSelector: @selector(pleaseWaitAuxPressed)]) [_delegate pleaseWaitAuxPressed];
}
//=============================================================================================================================
#pragma mark Callbacks
- (void) animationDidStop: (NSString *) animationID finished: (NSNumber *) finished context: (void *) context {
	[_view removeFromSuperview];
	[self autorelease];
}


@end
