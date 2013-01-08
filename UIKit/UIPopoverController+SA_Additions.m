//
//  UIPopoverController+Additions.m
//
//  Created by Ben Gottlieb on 8/26/11.
//  Copyright (c) 2011 Stand Alone, Inc.. All rights reserved.
//

#import "UIPopoverController+SA_Additions.h"
#import "UIView+SA_Additions.h"
#import "UIViewController+SA_Additions.h"
#import "NSObject+SA_Additions.h"

#define SA_POPOVER_DISMISS_BLOCK_KEY			@"com.standalone.SA_POPOVER_DISMISS_BLOCK_KEY"

static NSMutableArray					*s_activePopovers = nil;

@implementation UIPopoverController (SA_PopoverAdditions)
+ (UIPopoverController *) SAPopoverControllerWithContentController: (UIViewController *) content {
	UIPopoverController				*controller = [[[UIPopoverController alloc] initWithContentViewController: content] autorelease];
	UIViewController				*root = ([content isKindOfClass: [UINavigationController class]] && [[(id) content viewControllers] count]) ? [[(id) content viewControllers] objectAtIndex: 0] : content;
	
	
	if (s_activePopovers == nil) s_activePopovers = [[NSMutableArray alloc] init];
	[s_activePopovers addObject: controller];
	controller.delegate = (id <UIPopoverControllerDelegate>) self;
	CGSize				size = root.view.bounds.size;
	
	if (size.width && size.height)
		controller.popoverContentSize = size;
	
	return controller;
}

+ (BOOL) didCloseExistingPopoverWithClass: (Class) class {
	if ([class isEqual: [UIViewController class]]) return NO;
	
	for (UIPopoverController *pc in s_activePopovers) {
		UINavigationController			*root = (id) pc.contentViewController;
		
		if ([root isKindOfClass: [UINavigationController class]] && root.viewControllers.count > 0) root = [root.viewControllers objectAtIndex: 0];
		
		if ([root isKindOfClass: class]) {
			[pc dismissSAPopoverAnimated: YES];
			return YES;
		}
	}
	return NO;
}

+ (UIPopoverController *) presentSAPopoverForViewController: (UIViewController *) controller fromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	Class							class = [controller class];
	
	if (view.window == nil) return nil;		//no window to pop from
	if ([class isEqual: [UINavigationController class]]) class = [[(id) controller rootViewController] class];
	if (controller.onlyAllowOneInstanceInAPopover && [self didCloseExistingPopoverWithClass: class]) return nil;
	
	UIPopoverController			*pc = [self SAPopoverControllerWithContentController: controller];
	
	[controller willAppearInPopover: pc animated: animated];
	[pc presentPopoverFromRect: rect inView: view permittedArrowDirections: arrowDirections animated:animated];
	[controller didAppearInPopover: pc animated: animated];
	return pc;
}

+ (UIPopoverController *) presentSAPopoverForViewController: (UIViewController *) controller fromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	if (controller.onlyAllowOneInstanceInAPopover && [self didCloseExistingPopoverWithClass: [controller class]]) return nil;

	UIPopoverController			*pc = [self SAPopoverControllerWithContentController: controller];
	
	[controller willAppearInPopover: pc animated: animated];
	@try {
		[pc presentPopoverFromBarButtonItem: item permittedArrowDirections: arrowDirections animated: animated];
	} @catch (id e) {
		[s_activePopovers removeObject: pc];
		return nil;
	}
	[controller didAppearInPopover: pc animated: animated];
	return pc;
}

+ (BOOL) popoverControllerShouldDismissPopover: (UIPopoverController *) popoverController {
	if ([popoverController.contentViewController respondsToSelector: @selector(popoverControllerShouldDismissPopover:)])
		return [(id) popoverController.contentViewController popoverControllerShouldDismissPopover: popoverController];
	
	[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_PopoverWasDismissed object: popoverController];
	
	idArgumentBlock				block = popoverController.didDismissBlock;
	
	if (block) block(popoverController);
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

+ (void) dismissAllVisibleSAPopoversAnimated: (BOOL) animated {
	for (UIPopoverController *controller in [s_activePopovers.copy autorelease]) {
		[controller dismissSAPopoverAnimated: animated];
	}
}

+ (BOOL) isPopoverVisibleWithViewControllerClass: (Class) class {
	if (class == nil) return s_activePopovers.count > 0;
	return [self existingPopoverWithViewControllerClass: class] != nil;
}

+ (UIPopoverController *) existingPopoverWithViewControllerClass: (Class) class {
	if (class == nil) return nil;
	
	for (UIPopoverController *pop in s_activePopovers) {
		UINavigationController		*nav = (id) pop.contentViewController;
		
		if ([nav isKindOfClass: class]) return pop;
		if ([nav isKindOfClass: [UINavigationController class]] && [nav.rootViewController isKindOfClass: class]) return pop;
		if ([nav isKindOfClass: [UITabBarController class]]) {
			for (UIViewController *tab in nav.viewControllers) {
				if ([tab isKindOfClass: class]) return pop;
			}
		}
	}
	return nil;
}

+ (UIPopoverController *) existingPopoverWithView: (UIView *) view { return view.SAPopoverController; }


+ (UIPopoverController *) presentSAPopoverForView: (UIView *) subject fromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	UIViewController		*dummyController = [[[UIViewController alloc] init] autorelease];
	UIView					*parent = [[[UIView alloc] initWithFrame: subject.bounds] autorelease];
	
	subject.center = parent.contentCenter;
	[parent addSubview: subject];
	
	dummyController.contentSizeForViewInPopover = subject.bounds.size;
	dummyController.view = parent;
	return [self presentSAPopoverForViewController: dummyController fromRect: rect inView: view permittedArrowDirections: arrowDirections animated: animated];
}

+ (UIPopoverController *) presentSAPopoverForView: (UIView *) subject fromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
	UIViewController		*dummyController = [[[UIViewController alloc] init] autorelease];
	UIView					*parent = [[[UIView alloc] initWithFrame: subject.bounds] autorelease];
	
	subject.center = parent.contentCenter;
	[parent addSubview: subject];
	
	dummyController.contentSizeForViewInPopover = subject.bounds.size;
	dummyController.view = parent;
	return [self presentSAPopoverForViewController: dummyController fromBarButtonItem: item permittedArrowDirections: arrowDirections animated: animated];
}

- (void) setDidDismissBlock: (idArgumentBlock) didDismissBlock {
	SA_BlockWrapper			*block = [SA_BlockWrapper wrapperWithIDBlock: didDismissBlock];
	
	[self associateValue: block forKey: SA_POPOVER_DISMISS_BLOCK_KEY];
}

- (idArgumentBlock) didDismissBlock {
	return [[self associatedValueForKey: SA_POPOVER_DISMISS_BLOCK_KEY] idBlock];
}

@end


@implementation UIView (SA_PopoverAdditions)
- (UIPopoverController *) SAPopoverController {
	return self.viewController.SAPopoverController;
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
	UINavigationController				*nav = [self isKindOfClass: [UINavigationController class]] ? (id) self : [[[UINavigationController alloc] initWithRootViewController: self] autorelease];
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


