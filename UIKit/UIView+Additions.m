//
//  UIView+Additions.m
//
//  Created by Ben Gottlieb on 11/10/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import "UIView+Additions.h"
#import <QuartzCore/QuartzCore.h>
#import "NSObject+Additions.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSString (NSString_LocalizedAdditions)

- (NSString *)localizedString {
	NSString				*nothingFound = @"X_X_X_X_X_X_X_X";
	NSString				*newText = [[NSBundle mainBundle] localizedStringForKey: self value: nothingFound table: nil];
	
	if (![newText isEqualToString: nothingFound]) 
		return newText;
	else
		LOG(@"Missing translation for %@", self);
	
	return self;
}

@end



@implementation UIView (UIView_Additions)

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
	if ([self isKindOfClass: [UIScrollView class]] || [self isKindOfClass: [UIWebView class]]) return self;
	
	for (UIView *view in self.subviews) {
		UIView				*results = [view firstScrollviewChild];
		
		if (results) return results;
	}
	return nil;
}

- (void) resignFirstResponderForAllChildren {
	if ([self canResignFirstResponder]) [self resignFirstResponder];
	
	for (UIView *subview in self.subviews) {
		[subview resignFirstResponderForAllChildren];
	}
}

- (CGRect) normalizedFrame {
	CGRect					bounds = self.bounds;
	
	bounds.origin.x = self.center.x - bounds.size.width / 2;
	bounds.origin.y = self.center.y - bounds.size.height / 2;
	
	return bounds;
}

- (void) setNormalizedFrame: (CGRect) bounds {
	CGRect						newBounds = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
	CGPoint						newCenter = CGPointMake(bounds.origin.x + bounds.size.width / 2, bounds.origin.y + bounds.size.height / 2);
	
	if (!CGSizeEqualToSize(self.bounds.size, newBounds.size)) 
		self.bounds = newBounds;
	if (!CGPointEqualToPoint(self.center, newCenter)) 
		self.center = newCenter;
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
		LOG(@"%@", [self hierarchyToStringWithLevel: 0]);
}

- (NSString *) hierarchyToStringWithLevel: (int) level {
	NSMutableString				*results = [NSMutableString stringWithString: @"\n"];
	
	for (int i = 0; i < level; i++) {
		[results appendFormat: @"\t"];
	}
	
	NSString				*text = @"";
	
	if ([self respondsToSelector: @selector(title)]) text = [(id) self title];
	else if ([self respondsToSelector: @selector(text)]) text = [(id) self text];
	[results appendFormat: @"[%@, 0x%X], %@ [%@]", [self class], self, NSStringFromCGRect(self.frame), text];
	for (UIView *child in self.subviews) {
		[results appendFormat: @"%@", [child hierarchyToStringWithLevel: level + 1]];
	}
	return results;
}

- (void) logFrame {
	LOG(@"%@: %@", self, NSStringFromCGRect(self.frame));
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

- (UIImage *) toImage {
	UIGraphicsBeginImageContext(self.bounds.size);
	
	CGContextRef						context = UIGraphicsGetCurrentContext();
	
	if ([self respondsToSelector: @selector(contentOffset)]) {
		CGPoint					contentOffset = [(id) self contentOffset];
		
		CGContextTranslateCTM(context, -contentOffset.x, -contentOffset.y);
	}
	
	[self.layer renderInContext: context];
	
	UIImage					*viewImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	return viewImage;
}

- (NSArray *) allSubviews {
	NSMutableArray				*subviews = [self.subviews mutableCopy];
	
	for (UIView *view in self.subviews) {
		[subviews addObjectsFromArray: [view allSubviews]];
	}
	return [subviews autorelease];
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
//		[[self retain] autorelease];
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
	for (UIView *subview in [[self.subviews copy] autorelease]) {
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
	NSString			*key = @"timer";
	NSTimer				*pulseTimer = [self associatedValueForKey: key];

	[pulseTimer invalidate];
	[pulseTimer release];

	if (frequency == 0) {			//end pulsing
		[self associateValue: nil forKey: key];
	} else {
		pulseTimer = [[NSTimer scheduledTimerWithTimeInterval: frequency target: self selector: @selector(animatePulse) userInfo: nil repeats: YES] retain];
		[self associateValue: pulseTimer forKey: key];
		[self performSelector: @selector(animatePulse) withObject: nil afterDelay: 0];
	}
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
@end


