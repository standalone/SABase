//
//  UIScrollView+Additions.m
//
//  Created by Ben Gottlieb on 10/5/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "UIScrollView+SA_Additions.h"
#import "UIView+SA_Additions.h"
#import "NSObject+SA_Additions.h"

#define			kCachedContentSizeKey						@"sa_cached_content_size"
#define			kScrollViewIsSetupForKeyboardTracking		@"sa_setup_for_keyboard"

@implementation UIScrollView (SA_SA_Additions)

- (BOOL) isAdjustedForKeyboard {
	return [self associatedValueForKey: kCachedContentSizeKey] != nil;
}

- (void) setupForKeyboardEditing {
	IF_SIM(
		   if ([self associatedValueForKey: kScrollViewIsSetupForKeyboardTracking]) {
				LOG(@"Re-setting up keyboard editing for %@", self);
				return;
		   }
		   [self associateValue: (id) kCFBooleanTrue forKey: kScrollViewIsSetupForKeyboardTracking];
	);
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardWillShow:) name: UIKeyboardWillShowNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object: nil];
}

- (void) showNewFirstResponder: (UIView *) newResponder {
	SA_AssertAndReturn(![newResponder isFirstResponder], @"call showNewFirstResponder before setting the new firstResponder");
	SA_AssertAndReturn([self associatedValueForKey: kCachedContentSizeKey], @"Keyboard not currently visible");
	
	UIView					*convertView = self;
	CGRect					responderFrame = [newResponder convertRect: newResponder.bounds toView: convertView];
//	CGRect					intersection = CGRectIntersection(self.bounds, responderFrame);
//	CGFloat					scrollAmount = (responderFrame.size.height - intersection.size.height);
	CGFloat					scrollAmount = (responderFrame.origin.y + responderFrame.size.height + 10) - (self.bounds.origin.y + self.bounds.size.height);
	
	if (scrollAmount > 0) {
		CGPoint					newContentOffset = self.contentOffset;
		
		newContentOffset.y += scrollAmount;
		[self setContentOffset: newContentOffset animated: YES];
	}
	
	[newResponder becomeFirstResponder];
}

- (void) keyboardWillShow: (NSNotification *) note {
	UIView					*firstResponder = [UIView firstResponderView];
	CGRect					keyboardFrame;
	
	if ([note.userInfo objectForKey: @"UIKeyboardFrameEndUserInfoKey"]) {
		keyboardFrame = [[note.userInfo objectForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];
	} else {
		keyboardFrame = [[note.userInfo objectForKey: @"UIKeyboardBoundsUserInfoKey"] CGRectValue];
		keyboardFrame.origin.y = [[note.userInfo objectForKey: @"UIKeyboardCenterEndUserInfoKey"] CGPointValue].y - keyboardFrame.size.height / 2;
	}
	
	keyboardFrame = [self convertRect: keyboardFrame fromView: [UIApplication sharedApplication].keyWindow];
	
	UIView					*convertView = [UIApplication sharedApplication].keyWindow.subviews.count ? [[UIApplication sharedApplication].keyWindow.subviews objectAtIndex: 0] : [UIApplication sharedApplication].keyWindow;//[[UIApplication sharedApplication].keyWindow.subviews objectAtIndex: 0];
	CGRect					responderFrame = [firstResponder convertRect: firstResponder.bounds toView: convertView];
	CGRect					intersection = CGRectIntersection(keyboardFrame, responderFrame);
	BOOL					scrollRequired = (intersection.size.height != 0);

	[self associateValue: [NSValue valueWithCGRect: self.frame] forKey: kCachedContentSizeKey];
	
	CGPoint					newContentOffset = self.contentOffset;
	CGRect					myFrame = self.bounds;;
	CGRect					newFrame = self.frame;
	float					scrollAmount = (responderFrame.origin.y + responderFrame.size.height + 10) - keyboardFrame.origin.y;
	float					heightDelta = (CGRectIntersection(keyboardFrame, myFrame).size.height);
	
	newContentOffset.y += scrollAmount;
	newFrame.size.height -= heightDelta;
	
	if (scrollRequired) {
		[UIView beginAnimations: nil context: [[NSValue valueWithCGRect: newFrame] retain]];
		[UIView setAnimationDuration:  [[note.userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
		[UIView setAnimationCurve: [[note.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] intValue]];
		[UIView setAnimationDelegate: self];
		[UIView setAnimationDidStopSelector: @selector(keyboardDidShow:completed:newFrame:)];
		
		
		[self setContentOffset: newContentOffset animated: NO];
		[UIView commitAnimations];
	} else {
		if (RUNNING_ON_40) {
			[NSObject performBlock: ^{ self.frame = newFrame; } afterDelay: [[note.userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
		}
	}
}

- (void) keyboardDidShow: (NSString *) animationKey completed: (BOOL) completred newFrame: (NSValue *) newFrame {
	CGPoint				contentOffset = self.contentOffset;
	self.frame = [newFrame CGRectValue];
	self.contentOffset = contentOffset;
	[newFrame release];
}

- (void) keyboardWillHide: (NSNotification *) note {
	NSValue				*cachedSize = [self associatedValueForKey: kCachedContentSizeKey];
	
	if (cachedSize) {
		[UIView beginAnimations: nil context: nil];
		[UIView setAnimationDuration: [[note.userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
		[UIView setAnimationCurve: [[note.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] intValue]];
		self.frame = cachedSize.CGRectValue;
		[UIView commitAnimations];
		[self associateValue: nil forKey: kCachedContentSizeKey];
	}
}

- (void) endKeyboardEditing {
	[self associateValue: nil forKey: kScrollViewIsSetupForKeyboardTracking];

	[[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillShowNotification object: nil];
	[[NSNotificationCenter defaultCenter] removeObserver: self name: UIKeyboardWillHideNotification object: nil];
}

- (CGRect) visibleContentFrame {
	CGRect					area = self.bounds;			//start here
	
	area.origin = self.contentOffset;
	//area.size = CGSizeScale(area.size, self.zoomScale, self.zoomScale);
	return area;
}
@end
