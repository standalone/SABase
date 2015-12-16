//
//  UIPopoverController+SA_Additions.h
//
//  Created by Ben Gottlieb on 8/26/11.
//  Copyright (c) 2011 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kNotification_PopoverWasDismissed				@"kNotification_PopoverWasDismissed"

@interface UIPopoverController (SA_PopoverAdditions)
+ (instancetype) presentSA_PopoverForViewController: (UIViewController *) controller fromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
+ (instancetype) presentSA_PopoverForViewController: (UIViewController *) controller fromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;

+ (instancetype) presentSA_PopoverForView: (UIView *) subject fromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
+ (instancetype) presentSA_PopoverForView: (UIView *) subject fromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;

+ (void) dismissAllVisibleSA_PopoversAnimated: (BOOL) animated;
- (void) dismissSA_PopoverAnimated: (BOOL) animated;

+ (BOOL) isSA_PopoverVisibleWithViewControllerClass: (Class) cls;
+ (instancetype) existingSA_PopoverWithViewControllerClass: (Class) cls;
+ (instancetype) existingSA_PopoverWithView: (UIView *) view;

@property (nonatomic, copy) idArgumentBlock SA_didDismissBlock;
@end

@interface UIViewController (SA_PopoverAdditions)
@property (nonatomic, readonly) BOOL onlyAllowOneInstanceInAnSA_Popover;								//if set, trying to present a controller that's already presented will simply dismiss the existing one
- (void) willAppearInSA_Popover: (id) controller animated: (BOOL) animated;			//these two methods will only be called when using the popover methods in these categories
- (void) didAppearInSA_Popover: (id) controller animated: (BOOL) animated;
- (id) SA_PopoverController;

- (void) presentSA_PopoverFromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
- (void) presentSA_PopoverFromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
- (void) presentInSA_NavigationPopoverFromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
- (void) presentInSA_NavigationPopoverFromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
@end

@interface UIView (SA_PopoverAdditions)
- (id) SA_PopoverController;
@end