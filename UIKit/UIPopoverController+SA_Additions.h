//
//  UIPopoverController+SA_Additions.h
//
//  Created by Ben Gottlieb on 8/26/11.
//  Copyright (c) 2011 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kNotification_PopoverWasDismissed				@"kNotification_PopoverWasDismissed"

@interface SA_PopoverController: NSObject
+ (BOOL) isPopoverVisibleWithViewControllerClass: (Class) class;
+ (void) dismissAllVisiblePopoversAnimated: (BOOL) animated;
@end

@interface UIViewController (SA_PopoverViewController)
- (void) presentAsPopoverIn: (UIViewController *) parent from: (UIView *) view rect: (CGRect) rect;
- (void) presentAsPopoverIn: (UIViewController *) parent from: (UIBarButtonItem *) item;
@end

@interface UIView (SA_PopoverViewController)
- (void) presentAsPopoverIn: (UIViewController *) parent from: (UIView *) view rect: (CGRect) rect;
- (void) presentAsPopoverIn: (UIViewController *) parent from: (UIBarButtonItem *) item;
@end
