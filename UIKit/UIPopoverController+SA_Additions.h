//
//  UIPopoverController+SA_Additions.h
//
//  Created by Ben Gottlieb on 8/26/11.
//  Copyright (c) 2011 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kNotification_PopoverWasDismissed				@"kNotification_PopoverWasDismissed"

@interface UIPopoverController (SA_PopoverAdditions)
+ (UIPopoverController *) presentSAPopoverForViewController: (UIViewController *) controller fromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
+ (UIPopoverController *) presentSAPopoverForViewController: (UIViewController *) controller fromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;

+ (UIPopoverController *) presentSAPopoverForView: (UIView *) subject fromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
+ (UIPopoverController *) presentSAPopoverForView: (UIView *) subject fromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;


- (void) dismissSAPopoverAnimated: (BOOL) animated;

@property (nonatomic, copy) idArgumentBlock didDismissBlock;
@end

@interface UIViewController (SA_PopoverAdditions)
@property (nonatomic, readonly) BOOL onlyAllowOneInstanceInAPopover;								//if set, trying to present a controller that's already presented will simply dismiss the existing one
- (void) willAppearInPopover: (UIPopoverController *) controller animated: (BOOL) animated;			//these two methods will only be called when using the popover methods in these categories
- (void) didAppearInPopover: (UIPopoverController *) controller animated: (BOOL) animated;
- (UIPopoverController *) SAPopoverController;

- (void) presentSAPopoverFromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
- (void) presentSAPopoverFromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
- (void) presentInSANavigationPopoverFromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
- (void) presentInSANavigationPopoverFromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated;
@end

@interface UIView (SA_PopoverAdditions)
- (UIPopoverController *) SAPopoverController;
@end