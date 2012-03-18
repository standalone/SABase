//
//  UIPopoverController+Additions.m
//
//  Created by Ben Gottlieb on 8/26/11.
//  Copyright (c) 2011 Stand Alone, Inc.. All rights reserved.
//

#import "UIPopoverController+Additions.h"

static NSMutableArray					*s_activePopovers = nil;

@implementation UIPopoverController (SA_PopoverAdditions)
+ (UIPopoverController *) SAPopoverControllerWithContentController: (UIViewController *) content {
	UIPopoverController				*controller = [[[UIPopoverController alloc] initWithContentViewController: content] autorelease];
	UIViewController				*root = ([content isKindOfClass: [UINavigationController class]] && [[(id) content viewControllers] count]) ? [[(id) content viewControllers] objectAtIndex: 0] : content;
	
	
	if (s_activePopovers == nil) s_activePopovers = [[NSMutableArray alloc] init];
	[s_activePopovers addObject: controller];
	controller.delegate = (id <UIPopoverControllerDelegate>) self;
	controller.popoverContentSize = root.view.bounds.size;
	
	return controller;
}

+ (BOOL) didCloseExistingPopoverWithClass: (Class) class {
	for (UIPopoverController *pc in s_activePopovers) {
		UINavigationController			*root = (id) pc.contentViewController;
		
		if ([root isKindOfClass: [UINavigationController class]] && root.viewControllers.count > 0) root = [root.viewControllers objectAtIndex: 0];
		
		if ([pc.contentViewController isKindOfClass: class]) {
			[pc dismissSAPopoverAnimated: YES];
			return YES;
		}
	}
	return NO;
}

+ (void) presentSAPopoverForViewController: (UIViewController *) controller fromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	if (controller.onlyAllowOneInstanceInAPopover && [self didCloseExistingPopoverWithClass: [controller class]]) return;
	
	UIPopoverController			*pc = [self SAPopoverControllerWithContentController: controller];
	
	[controller willAppearInPopover: pc animated: animated];
	[pc presentPopoverFromRect: rect inView: view permittedArrowDirections: arrowDirections animated:animated];
	[controller didAppearInPopover: pc animated: animated];
}

+ (void) presentSAPopoverForViewController: (UIViewController *) controller fromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	if (controller.onlyAllowOneInstanceInAPopover && [self didCloseExistingPopoverWithClass: [controller class]]) return;

	UIPopoverController			*pc = [self SAPopoverControllerWithContentController: controller];
	
	[controller willAppearInPopover: pc animated: animated];
	[pc presentPopoverFromBarButtonItem: item permittedArrowDirections: arrowDirections animated: animated];
	[controller didAppearInPopover: pc animated: animated];
}

+ (BOOL) popoverControllerShouldDismissPopover: (UIPopoverController *) popoverController {
	if ([popoverController.contentViewController respondsToSelector: @selector(popoverControllerShouldDismissPopover:)])
		return [(id) popoverController.contentViewController popoverControllerShouldDismissPopover: popoverController];
	
	return YES;
}


+ (void) popoverControllerDidDismissPopover: (UIPopoverController *) popoverController {
	if ([popoverController.contentViewController respondsToSelector: @selector(popoverControllerDidDismissPopover:)])
		[(id) popoverController.contentViewController popoverControllerDidDismissPopover: popoverController];
	[s_activePopovers removeObject: popoverController];
}

- (void) dismissSAPopoverAnimated: (BOOL) animated {
	[self dismissPopoverAnimated: animated];
	[s_activePopovers removeObject: self];
}

@end


@implementation UIViewController (SA_PopoverAdditions)
- (UIPopoverController *) SAPopoverController {
	for (UIPopoverController *controller in s_activePopovers) {
		UINavigationController			*nav = (id) controller.contentViewController;
		
		if (nav == self) return controller;
		
		if ([nav respondsToSelector: @selector(viewControllers)] && nav.viewControllers.count > 0 && [nav.viewControllers objectAtIndex: 0] == self) return controller;
	}
	return nil;
}

- (void) presentSAPopoverFromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	[UIPopoverController presentSAPopoverForViewController: self fromRect: rect inView: view permittedArrowDirections: arrowDirections animated: YES];
}

- (void) presentSAPopoverFromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	[UIPopoverController presentSAPopoverForViewController: self fromBarButtonItem: item permittedArrowDirections: arrowDirections animated: animated];
}

- (void) presentInSANavigationPopoverFromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	UINavigationController				*nav = [self isKindOfClass: [UINavigationController class]] ? self : [[[UINavigationController alloc] initWithRootViewController: self] autorelease];
	[UIPopoverController presentSAPopoverForViewController: nav fromRect: rect inView: view permittedArrowDirections: arrowDirections animated: YES];
}

- (void) presentInSANavigationPopoverFromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	UINavigationController				*nav = [[[UINavigationController alloc] initWithRootViewController: self] autorelease];
	[UIPopoverController presentSAPopoverForViewController: nav fromBarButtonItem: item permittedArrowDirections: arrowDirections animated: animated];
}

- (void) willAppearInPopover: (UIPopoverController *) controller animated: (BOOL) animated { }
- (void) didAppearInPopover: (UIPopoverController *) controller animated: (BOOL) animated { }
- (BOOL) onlyAllowOneInstanceInAPopover { return YES; }

@end