//
//  UIView+Additions.m
//
//  Created by Ben Gottlieb on 11/10/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import "NSObject+SA_Additions.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "CAAnimation+SA_Blocks.h"
#import "UIImageView+SA_Additions.h"
#import "dispatch_additions_SA.h"
#import "UIImage+SA_Additions.h"
#import "SA_Utilities.h"

#define kSA_OriginalCenterBeforeKeyboardShift			@"SA_OriginalCenterBeforeKeyboardShift"

@interface UIView (OS7_Compatibility)
- (BOOL) drawViewHierarchyInRect: (CGRect) rect afterScreenUpdates: (BOOL) afterUpdates;

@end

@interface SA_BlockerView : UIView <UIGestureRecognizerDelegate>
@property (nonatomic, copy) viewArgumentBlock viewTappedBlock;
@end

@implementation NSString (NSString_LocalizedAdditions)

- (NSString *) localizedString {
	NSString				*nothingFound = @"X_X_X_X_X_X_X_X";
	NSString				*newText = [[NSBundle mainBundle] localizedStringForKey: self value: nothingFound table: nil];
	
	if (![newText isEqualToString: nothingFound]) 
		return newText;
	else {
		if (SA_Base_DebugMode()) {
			if (self.length > 0 && ![self isEqual: @"-"] && ![self isEqual: @"--"])
				LOG(@"Missing translation for %@", self);
		}
	}
	return self;
}

@end



@implementation UIView (UIView_SA_Additions)
@dynamic normalizedFrame, firstScrollviewChild, contentCenter, viewController, tableViewCell;

+ (void) chainAnimations: (NSArray *) animations withDurations: (NSArray *) durations {
	SA_Assert(animations.count == durations.count, @"you must pass equal length arrays for both durations and animations");
	
	[UIView animateWithDuration: [[durations objectAtIndex: 0] floatValue] animations: [animations objectAtIndex: 0] completion: ^(BOOL completed) {
		if (animations.count == 1) return;
		
		NSRange							range = NSMakeRange(1, animations.count - 1);
		[UIView chainAnimations: [animations subarrayWithRange: range] withDurations: [durations subarrayWithRange: range]];
	}];
}

+ (UIView *) firstResponderView {
	return [[UIApplication sharedApplication].keyWindow firstResponderView];
}

- (UIView *) firstResponderView {
	if ([self isFirstResponder]) return self;
	for (UIView *view in self.subviews) {
		UIView			*responder = [view firstResponderView];
		
		if (responder) return responder;
	}
	return nil;
}

+ (void) resignFirstResponder {
	[[UIApplication sharedApplication].keyWindow resignFirstResponderForAllChildren];
}

- (UIView *) firstScrollviewChild {
	if ([self isKindOfClass: [UIScrollView class]]) return self;
	
	for (UIView *view in self.subviews) {
		UIView				*results = [view firstScrollviewChild];
		
		if (results) return results;
	}
	return nil;
}

- (BOOL) resignFirstResponderForAllChildren {
	if (![self canResignFirstResponder]) return NO;
	[self resignFirstResponder];
	
	for (UIView *subview in self.subviews) {
		if (![subview resignFirstResponderForAllChildren]) return NO;
	}
	return YES;
}

- (CGRect) normalizedFrame {
	CGRect					bounds = self.bounds;
	
	bounds.origin.x = self.center.x - bounds.size.width / 2;
	bounds.origin.y = self.center.y - bounds.size.height / 2;
	
	return bounds;
}

- (void) setNormalizedFrame: (CGRect) bounds {
	CGRect						normalized = CGRectNormalized(bounds, self.frame);
	CGRect						newBounds = CGRectMake(0, 0, normalized.size.width, normalized.size.height);
	CGPoint						newCenter = CGPointMake(normalized.origin.x + normalized.size.width / 2, normalized.origin.y + normalized.size.height / 2);
	
	if (CGRectEqualToRect(bounds, CGRectZero)) {
		self.bounds = bounds;
		return;
	}
	
	if (!CGSizeEqualToSize(self.bounds.size, newBounds.size)) {
		self.bounds = newBounds;
	}
	
	if (!CGPointEqualToPoint(self.center, newCenter)) {
		self.center = newCenter;
	}
}

//- (CGSize) size {
//	return self.bounds.size;
//}
//
//- (void) setSize: (CGSize) size {
//	CGRect					bounds = self.bounds;
//	bounds.size = size;
//	self.bounds = bounds;
//}

- (CGPoint) contentCenter {
	return CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
}

- (void) positionInView: (UIView *) view withContentMode: (UIViewContentMode) mode {
	if (self.superview != view) [view addSubview: self];
	self.frame = CGRectPlacedInRectWithContentMode(self.bounds, view.bounds, mode);
}

- (void) logHierarchy {
		SA_BASE_LOG(@"%@", [self hierarchyToStringWithLevel: 0]);
}

- (NSString *) hierarchyToStringWithLevel: (int) level {
	NSMutableString				*results = [NSMutableString stringWithString: @"\n"];
	
	for (int i = 0; i < level; i++) {
		[results appendFormat: @"\t"];
	}
	
	NSString				*text = @"";
	
	if ([self respondsToSelector: @selector(title)]) text = [(id) self title];
	else if ([self respondsToSelector: @selector(text)]) text = [(id) self text];
	[results appendFormat: @"[%@, 0x%lX], %@ [%@]", [self class], (long) self, NSStringFromCGRect(self.frame), text];
	for (UIView *child in self.subviews) {
		[results appendFormat: @"%@", [child hierarchyToStringWithLevel: level + 1]];
	}
	return results;
}

- (void) logFrame {
	SA_BASE_LOG(@"%@: %@", self, NSStringFromCGRect(self.frame));
}


- (id) firstSubviewOfClass: (Class) class {
	return [self firstSubviewOfClass: class searchHierarchy: NO];
}

- (id) firstSubviewOfClass: (Class) class searchHierarchy: (BOOL) searchHierarchy {
	for (UIView *v in self.subviews) {
		if ([v isKindOfClass: class]) return v;
	}
	
	if (!searchHierarchy) return nil;
	
	for (UIView *v in self.subviews) {
		UIView				*result = [v firstSubviewOfClass: class searchHierarchy: searchHierarchy];
		if (result) return result;
	}
	
	return nil;
}

- (UIImageView *) imageViewCloneUsingLayer: (BOOL) useLayer {
	UIImage		*image = [self toImageUsingLayer: useLayer];
	UIImageView	*view = [[UIImageView alloc] initWithImage: image];
	
	view.backgroundColor = self.backgroundColor;
	return view;
}

- (UIImage *) toImage { return [self toImageUsingLayer: NO fromRect: self.bounds]; }

- (UIImage *) toImageUsingLayer: (BOOL) useLayer { return [self toImageUsingLayer: useLayer fromRect: self.bounds]; }
- (UIImage *) toImageUsingLayer: (BOOL) useLayer fromRect: (CGRect) rect {
	CGSize				size = rect.size;
	
	if (RUNNING_ON_70 && !useLayer) {
		return [UIImage imageOfSize: size fromBlock: ^(CGContextRef ctx) {
			CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(-rect.origin.x, -rect.origin.y));

			[self drawViewHierarchyInRect: CGRectMake(0, 0, size.width, size.height) afterScreenUpdates: YES];
		}];
	} else {
		return [UIImage imageOfSize: size fromBlock: ^(CGContextRef ctx) {
			if ([self respondsToSelector: @selector(contentOffset)]) {
				CGPoint					contentOffset = [(id) self contentOffset];
				
				CGContextTranslateCTM(ctx, -contentOffset.x, -contentOffset.y);
			}
			
			CGContextConcatCTM(ctx, CGAffineTransformMakeTranslation(-rect.origin.x, -rect.origin.y));
			[self.layer renderInContext: ctx];
		}];
	}
}

- (NSArray *) allSubviews {
	NSMutableArray				*subviews = [self.subviews mutableCopy];
	
	for (UIView *view in self.subviews) {
		[subviews addObjectsFromArray: [view allSubviews]];
	}
	return subviews;
}

- (void) offsetPositionByX: (float) x y: (float) y {
	CGPoint						position = self.center;
	
	position.x += x;
	position.y += y;
	self.center = position;
}

- (void) adjustSizeWidth: (float) width height: (float) height {
	CGRect					bounds = self.bounds;
	
	bounds.size.width += width;
	bounds.size.height += height;
	
	self.bounds = bounds;
	[self offsetPositionByX: width / 2 y: height / 2];
}
	
- (void) setCenter: (CGPoint) center andSize: (CGSize) size {
	self.center = center;
	
	self.bounds = CGRectMake(0, 0, size.width, size.height);
}

- (void) expandWidth: (float) additionalWidth andHeight: (float) additionalHeight {
	CGRect					frame = self.normalizedFrame;
	
	frame.size.width += ABS(additionalWidth);
	if (additionalWidth < 0) frame.origin.x -= ABS(additionalWidth);

	frame.size.height += ABS(additionalHeight);
	if (additionalHeight < 0) frame.origin.y -= ABS(additionalHeight);

	self.normalizedFrame = frame;
}

- (void) compressWidth: (float) removedWidth andHeight: (float) removedHeight {
	CGRect					frame = self.normalizedFrame;
	
	frame.size.width -= ABS(removedWidth);
	if (removedWidth < 0) frame.origin.x += ABS(removedWidth);
	
	frame.size.height += ABS(removedHeight);
	if (removedHeight < 0) frame.origin.y += ABS(removedHeight);
	
	self.normalizedFrame = frame;
}
//
////=============================================================================================================================
//#pragma mark Sliding
//- (void) slideInFrom: (viewSlideDirection) direction inParent: (UIView *) parent delegate: (id) delegate {
//	if (parent == nil) parent = self.superview;
//	SA_Assert(parent != nil, @"-[UIView slideInFrom:inParent:] no parent passed to an orphan subview");
//
//	CGSize					size = self.bounds.size;
//	CGSize					parentSize = parent.bounds.size;
//	
//	switch (direction) {
//		case viewSlideDirectionTop:
//			self.frame = CGRectMake(0, -size.height, parentSize.width, size.height);
//			break;
//			
//		case viewSlideDirectionBottom:
//			self.frame = CGRectMake(0, parentSize.height, parentSize.width, size.height);
//			break;
//
//		case viewSlideDirectionLeft:
//			self.frame = CGRectMake(-size.width, 0, size.width, parentSize.height);
//			break;
//			
//		case viewSlideDirectionRight:
//			self.frame = CGRectMake(parentSize.width, 0, size.width, parentSize.height);
//			break;
//	}
//	
//	[parent addSubview: self];
//	
//	[UIView beginAnimations: @"in" context: delegate];
//	[UIView setAnimationDuration: 0.3];
//	[UIView setAnimationDelegate: self];
//	[UIView setAnimationDidStopSelector: @selector(slideAnimationEnded:complete:context:)];
//
//	switch (direction) {
//		case viewSlideDirectionTop:
//			self.frame = CGRectMake(0, 0, parentSize.width, size.height);
//			break;
//			
//		case viewSlideDirectionBottom:
//			self.frame = CGRectMake(0, parentSize.height - size.height, parentSize.width, size.height);
//			break;
//			
//		case viewSlideDirectionLeft:
//			self.frame = CGRectMake(0, 0, size.width, parentSize.height);
//			break;
//			
//		case viewSlideDirectionRight:
//			self.frame = CGRectMake(parentSize.width - size.width, 0, size.width, parentSize.height);
//			break;
//	}
//	
//	[UIView commitAnimations];
//}
//
//- (void) slideOutTo: (viewSlideDirection) direction removeWhenDone: (BOOL) remove delegate: (id) delegate {
//	CGSize					size = self.bounds.size;
//	CGSize					parentSize = self.superview.bounds.size;
//
//	[UIView beginAnimations: remove ? @"out.remove" : @"out" context: delegate];
//	[UIView setAnimationDuration: 0.3];
//	[UIView setAnimationDelegate: self];
//	[UIView setAnimationDidStopSelector: @selector(slideAnimationEnded:complete:context:)];
//	
//	switch (direction) {
//		case viewSlideDirectionTop:
//			self.frame = CGRectMake(0, -size.height, parentSize.width, size.height);
//			break;
//			
//		case viewSlideDirectionBottom:
//			self.frame = CGRectMake(0, parentSize.height, parentSize.width, size.height);
//			break;
//			
//		case viewSlideDirectionLeft:
//			self.frame = CGRectMake(-size.width, 0, size.width, parentSize.height);
//			break;
//			
//		case viewSlideDirectionRight:
//			self.frame = CGRectMake(parentSize.width, 0, size.width, parentSize.height);
//			break;
//	}
//	
//	[UIView commitAnimations];
//}
//
//- (void) slideAnimationEnded: (NSString *) anim complete: (BOOL) complete context: (id) delegate {
//	if ([anim rangeOfString: @"remove"].location != NSNotFound) {
//		[[self strong] autorelease];
//		[self removeFromSuperview];
//	}
//	if ([delegate respondsToSelector: @selector(slideDidFinishForView:)]) [delegate slideDidFinishForView: self];
//}

- (BOOL) hasAncestor: (UIView *) ancestor {
	UIView					*parent = self;
	
	while (true) {
		parent = parent.superview;
		if (parent == nil) return NO;
		if (parent == ancestor) return YES;
	}
	
	return NO;
}

- (void) removeAllSubviews {
	for (UIView *subview in [self.subviews copy]) {
		[subview removeFromSuperview];
	}
}

- (void) recursiveSetFont: (UIFont *) font {
	for (UIView *view in self.subviews) {
		[view recursiveSetFont: font];
	}
	if ([self respondsToSelector: @selector(setFont:)]) [self performSelector: @selector(setFont:) withObject: font];
}

- (void) localizeText {
    if ([self respondsToSelector: @selector(titleForState:)] && [self respondsToSelector: @selector(setTitle:forState:)] && [[(id) self titleForState:UIControlStateNormal] length]) {
        [(id)self setTitle:[[(id)self titleForState:UIControlStateNormal] localizedString] forState:UIControlStateNormal];
        [(id)self setTitle:[[(id)self titleForState:UIControlStateSelected] localizedString] forState:UIControlStateSelected];
        [(id)self setTitle:[[(id)self titleForState:UIControlStateDisabled] localizedString] forState:UIControlStateDisabled];
        [(id)self setTitle:[[(id)self titleForState:UIControlStateHighlighted] localizedString] forState:UIControlStateHighlighted];
    }
	else if ([self respondsToSelector: @selector(text)] && [self respondsToSelector: @selector(setText:)] && [[(id) self text] length]) {
		[(id) self setText: [[(id) self text] localizedString]];
	} else if ([self respondsToSelector: @selector(title)] && [self respondsToSelector: @selector(setTitle:)] && [[(id) self title] length]) {
		[(id) self setTitle: [[(id) self title] localizedString]];
	} else if ([self respondsToSelector: @selector(setTitle:forSegmentAtIndex:)]) {
		for (int i = 0; i < [(id) self numberOfSegments]; i++) {
			NSString			*title = [(id) self titleForSegmentAtIndex: i];
			
			if (title) [(id) self setTitle: [title localizedString] forSegmentAtIndex: i];
		}
	}

	for (UIView *view in self.subviews) [view localizeText];
}

- (void) pulseWithFrequency: (NSTimeInterval) frequency {
	NSString			*key = @"sa_view_pulse_timer";
	NSTimer				*pulseTimer = [self associatedValueForKey: key];
	NSTimeInterval		duration = 0.15;

	[pulseTimer invalidate];

	if (frequency == 0) {			//end pulsing
		[self associateValue: nil forKey: key];
		[UIView animateWithDuration: duration animations: ^{
			self.transform = CGAffineTransformIdentity;
		}];
	} else {
		pulseTimer = [NSTimer scheduledTimerWithTimeInterval: frequency target: self selector: @selector(animatePulse) userInfo: nil repeats: YES];
		[self associateValue: pulseTimer forKey: key];
		[self performSelector: @selector(animatePulse) withObject: nil afterDelay: 0];
	}
}

- (void) stopPulsing {
	[self pulseWithFrequency: 0];
}

- (void) animatePulse {
	NSTimeInterval					duration = 0.15;
	
	[UIView animateWithDuration: duration animations: ^{
		self.transform = CGAffineTransformMakeScale(1.1, 1.1);
	} completion: ^(BOOL completed) {
		[UIView animateWithDuration: duration animations: ^{
			self.transform = CGAffineTransformIdentity;
		} completion: ^(BOOL completed) {
			[UIView animateWithDuration: duration animations: ^{
				self.transform = CGAffineTransformMakeScale(1.1, 1.1);
			} completion: ^(BOOL completed) {
				[UIView animateWithDuration: duration animations: ^{
					self.transform = CGAffineTransformIdentity;
				}];
			}];
		}];
	}];
}

- (UIViewController *) viewController {
	id nextResponder = [self nextResponder];
	
	while (nextResponder) {
		if ([nextResponder isKindOfClass:[UIViewController class]]) return nextResponder;
		nextResponder = [nextResponder nextResponder];
	}
	return nil;
}

- (UITableViewCell *) tableViewCell {
	UIView			*view = self.superview;
	
	while (view) {
		if ([view isKindOfClass: [UITableViewCell class]]) return (id) view;
		view = view.superview;
	}
	return nil;
}

- (void) addEdgeDividers: (UIEdgeInsets) dividerWidths ofColor: (UIColor *) color {
	UIView				*div;
	
	if (dividerWidths.left) {
		div = [[UIView alloc] initWithFrame: CGRectMake(0, 0, dividerWidths.left, self.bounds.size.height)];
		div.backgroundColor = color;
		div.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview: div];
	}
	
	if (dividerWidths.right) {
		div = [[UIView alloc] initWithFrame: CGRectMake(self.bounds.size.width - dividerWidths.right, 0, dividerWidths.right, self.bounds.size.height)];
		div.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
		div.backgroundColor = color;
		[self addSubview: div];
	}
	
	if (dividerWidths.top) {
		div = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.bounds.size.width, dividerWidths.top)];
		div.backgroundColor = color;
		div.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		[self addSubview: div];
	}
	
	if (dividerWidths.bottom) {
		div = [[UIView alloc] initWithFrame: CGRectMake(0, self.bounds.size.height - dividerWidths.bottom, self.bounds.size.width, dividerWidths.bottom)];
		div.backgroundColor = color;
		div.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		[self addSubview: div];
	}
}

- (void) animateAndBounceToPoint: (CGPoint) point {
	CGPoint						start = self.center;
	CGPoint						delta = CGPointOffsetFromPoint(point, start);
	CAKeyframeAnimation			*anim = [CAKeyframeAnimation animationWithKeyPath: @"position"];
	CGMutablePathRef			path = CGPathCreateMutable();
	NSString					*key = @"move+bounce";
	
	CGPathMoveToPoint(path, nil, start.x, start.y);
	CGPathAddLineToPoint(path, nil, point.x + delta.x * 0.1, point.y + delta.y * 0.1);
	CGPathAddLineToPoint(path, nil, point.x - delta.x * 0.1, point.y - delta.y * 0.1);
	CGPathAddLineToPoint(path, nil, point.x + delta.x * 0.05, point.y + delta.y * 0.05);
	CGPathAddLineToPoint(path, nil, point.x - delta.x * 0.025, point.y - delta.y * 0.025);
	CGPathAddLineToPoint(path, nil, point.x, point.y);
	
	anim.duration = 0.5;
	anim.path = path;
	anim.SA_animationDidStopBlock = ^(CAAnimation *anim, BOOL finished) {
		self.center = point;
		self.layer.position = point;
		
		[self.layer removeAnimationForKey: key];
	};
	[self.layer addAnimation: anim forKey: key];
	CGPathRelease(path);
}

- (UIView *) commonAncestorWith: (UIView *) other {
	UIView					*myParent = self.superview;
	
	while (myParent) {
		UIView					*theirParent = other.superview;
		
		while (theirParent) {
			if (theirParent == myParent) return myParent;
			
			theirParent = theirParent.superview;
		}
		
		myParent = myParent.superview;
	}
	
	return nil;
}

- (BOOL) isSubviewOf: (UIView *) view {
	for (UIView *child in view.subviews) {
		if (child == self) return YES;
		if ([self isSubviewOf: child]) return YES;
	}
	return NO;
}


#if BLUR_SUPPORTED
const NSString			*kBlurredViewKey = @"SA_kBlurredViewKey";

- (UIImageView *) preBlur {
	UIImageView				*view = [self associatedValueForKey: kBlurredViewKey];
	
	if (view == nil) view = [[UIImageView alloc] initWithFrame: self.frame];
	view.alpha = 0.0;
	view.frame = self.frame;
	view.alpha = 0.0;
	view.transform = self.transform;
	view.autoresizingMask = self.autoresizingMask;
	if (view.superview == self.superview) {
		if ([NSThread isMainThread])
			[self.superview insertSubview: view aboveSubview: self];
		else
			dispatch_sync(dispatch_get_main_queue(), ^{ [self.superview insertSubview: view aboveSubview: self];});
	} else {
		[self.superview insertSubview: view aboveSubview: self];
	}
	return view;
}

- (BOOL) isBlurred {
	UIView				*blur = [self associatedValueForKey: kBlurredViewKey];
	
	return blur.alpha != 0.0;
}

- (UIImageView *) blur: (int) blurriness withDuration: (NSTimeInterval) duration {
	if (!RUNNING_ON_60 || self.isBlurred) return nil;


	NSTimeInterval		start = [NSDate timeIntervalSinceReferenceDate];
	
	UIImage *image = [UIImage imageOfSize: self.bounds.size fromBlock: ^(CGContextRef ctx) {
		CGContextTranslateCTM(UIGraphicsGetCurrentContext(), -self.frame.origin.x, -self.frame.origin.y);
		[self.superview.layer renderInContext: ctx];
	}];
	
	SA_BASE_LOG(@"Took %.5f to generate image", [NSDate timeIntervalSinceReferenceDate] - start);
	start = [NSDate timeIntervalSinceReferenceDate];
	CIImage				*ciImage = [CIImage imageWithCGImage: image.CGImage];
	CIContext			*context = [CIContext contextWithOptions: nil];
	CIFilter			*filter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues: kCIInputImageKey, ciImage, @"inputRadius", @(blurriness), nil];
	
	UIImageView				*view = [self preBlur];

	SA_BASE_LOG(@"Took %.5f to build view", [NSDate timeIntervalSinceReferenceDate] - start);
	start = [NSDate timeIntervalSinceReferenceDate];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		CIImage				*outputImage = [filter outputImage];
		UIImage				*result = [UIImage imageWithCIImage: outputImage];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			view.image = result;
			[UIView animateWithDuration: duration animations: ^{ view.alpha = 1.0; }];
			SA_BASE_LOG(@"Took %.5f to display the blur", [NSDate timeIntervalSinceReferenceDate] - start);
		});
	});
	
	[self associateValue: view forKey: kBlurredViewKey];
	return view;
}

- (void) unblur {
	UIView				*blur = [self associatedValueForKey: kBlurredViewKey];
	[blur removeFromSuperview];
	[self associateValue: nil forKey: kBlurredViewKey];
}

- (void) unblurWithDuration: (NSTimeInterval) duration {
	UIImageView				*blur = [self associatedValueForKey: kBlurredViewKey];
	
	if (duration) {
		[UIView animateWithDuration: duration animations: ^{ blur.alpha = 0.0; } completion:^(BOOL finished) {
			blur.image = nil;
		}];
	} else {
		blur.alpha = 0.0;
		blur.image = nil;
	}
	
//	[self associateValue: nil forKey: kBlurredViewKey];
}
#endif

- (UIScrollView *) scrollView {
	UIView			*parent = self.superview;
	
	while (parent) {
		if ([parent isKindOfClass: [UIScrollView class]] && ![parent.superview isKindOfClass: [UITableViewCell class]]) return (id) parent;
		parent = parent.superview;
	}
	return nil;
}

#define kBlockerViewTappedBlockKey			@"com.standalone.tapped.block"

- (UIView *) blockingViewWithTappedBlock: (viewArgumentBlock) block {
	SA_BlockerView				*blocker = [[SA_BlockerView alloc] initWithFrame: self.bounds];
	
	blocker.alpha = 0.1;
	blocker.backgroundColor = [UIColor clearColor];
	blocker.userInteractionEnabled = YES;
	blocker.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	if (block) {
		__block UIView *localBlocker = blocker;
		blocker.viewTappedBlock = block;
		
		UITapGestureRecognizer				*dismissRecog = [[UITapGestureRecognizer alloc] initWithSA_Block: ^(UIGestureRecognizer *recog) {
			if (recog.state != UIGestureRecognizerStateRecognized) return;
			UIView					*hit = [recog.view hitTest: [recog locationInView: recog.view] withEvent: nil];
			
			if (hit == blocker) blocker.viewTappedBlock(localBlocker);
		}];
		
		dismissRecog.delegate = blocker;
		[blocker addGestureRecognizer: dismissRecog];
	}
	
	[self addSubview: blocker];
	return blocker;
}


+ (void) maskedTransitionFromView: (UIView *) initialView toView: (UIView *) finalView duration: (NSTimeInterval) duration options: (UIViewAnimationOptions) options completion: (booleanArgumentBlock) completion {
	CGRect				originalFrame = initialView.frame;
	CGRect				flipFrame = originalFrame;
	
	if ([initialView isKindOfClass: [UIImageView class]]) {
		flipFrame = [(id) initialView SA_imageContentFrame];
		
		flipFrame.origin.x = originalFrame.origin.x + flipFrame.origin.x;
		flipFrame.origin.y = originalFrame.origin.y + flipFrame.origin.y;
	}
	
	UIView				*flipHost = [[UIView alloc] initWithFrame: flipFrame];
	
	[initialView.superview addSubview: flipHost];
	[initialView removeFromSuperview];
	initialView.center = flipHost.contentCenter;
	[flipHost addSubview: initialView];
	finalView.frame = flipHost.bounds;
	
	dispatch_after_main_queue(0.0001, ^{
		[UIView transitionFromView: initialView toView: finalView duration: duration options: options completion:^(BOOL finished) {
			initialView.frame = originalFrame;
			[flipHost.superview addSubview: finalView];
			[flipHost removeFromSuperview];
			finalView.frame = flipFrame;
			if (completion) completion(finished);
		}];
	});
}


//================================================================================================================
#pragma mark Accessibility
- (CGRect) convertRectToScreenCoordinates: (CGRect) incoming {
	return UIAccessibilityConvertFrameToScreenCoordinates(incoming, self);
	//	CGRect			frameInWindow = [self convertRect: incoming toView: self.window];
	//	CGRect			absFrame = [self.window convertRect: frameInWindow toWindow: nil];
	//
	//	return absFrame;
}


//================================================================================================================
#pragma mark Keyboard Observing

- (BOOL) observingKeyboard { return NO; }
- (void) setObservingKeyboard: (BOOL) observing {
	[[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillShowNotification object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillHideNotification object: nil];

	if (observing) {
		[self addAsObserverForName: UIKeyboardWillShowNotification selector: @selector(sa_keyboardWillShow:)];
		[self addAsObserverForName: UIKeyboardWillHideNotification selector: @selector(sa_keyboardWillHide:)];
	}
}

- (void) sa_keyboardWillShow: (NSNotification *) note {
	CGRect			fieldFrame = self.frame;
	CGRect			kbdFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	NSTimeInterval	duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
	CGPoint			center = self.center;
	
	[self associateValue: [NSValue valueWithCGPoint: self.center] forKey: kSA_OriginalCenterBeforeKeyboardShift];
	kbdFrame = [self.superview convertRect: kbdFrame fromView: nil];
	CGRect			intersect = CGRectIntersection(kbdFrame, fieldFrame);
	
	if (intersect.size.height >= fieldFrame.size.height) {
		center.y = kbdFrame.origin.y - fieldFrame.size.height * 1.1;
	} else {
		center.y -= intersect.size.height * 1.1;
	}
	
	[UIView animateWithDuration: duration animations: ^{ self.center = center; }];
}

- (void) sa_keyboardWillHide: (NSNotification *) note {
	NSTimeInterval	duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
	CGPoint			originalCenter = [[self associatedValueForKey: kSA_OriginalCenterBeforeKeyboardShift] CGPointValue];
	
	
	[UIView animateWithDuration: duration animations: ^{ self.center = originalCenter; }];
}

+ (BOOL) externalKeyboardPresent {
	Class				class = NSClassFromString(@"HVXrlobneqVzcy".rot13);		//UIKeyboardImpl
	SEL					sel = NSSelectorFromString(@"npgvirVafgnapr".rot13);			//activeInstance
	
	if (![class respondsToSelector: sel]) return NO;
	id					instance;
	SUPPRESS_LEAK_WARNING(instance = [class performSelector: sel]);
	
	sel = NSSelectorFromString(@"vfVaUneqjnerXrlobneqZbqr".rot13);			//isInHardwareKeyboardMode
	if (![instance respondsToSelector: sel]) return NO;
	SUPPRESS_LEAK_WARNING(return (BOOL) [instance performSelector: sel]);
}





@end

@implementation SA_BlockerView
- (BOOL) gestureRecognizer: (UIGestureRecognizer *) gestureRecognizer shouldReceiveTouch: (UITouch *) touch {
	if (touch.view != self) return NO;
	return YES;
}
@end

