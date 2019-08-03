//
//  UIPopoverController+Additions.m
//
//  Created by Ben Gottlieb on 8/26/11.
//  Copyright (c) 2011 Stand Alone, Inc.. All rights reserved.
//

#import "UIPopoverController+SA_Additions.h"

#import "UIViewController+SA_Additions.h"
#import "NSObject+SA_Additions.h"
#import "UIView+SA_Additions.h"

#define SA_POPOVER_DISMISS_BLOCK_KEY			@"com.standalone.SA_POPOVER_DISMISS_BLOCK_KEY"

@interface UIViewController (Compatibility_70)
- (CGSize) preferredContentSize;
@end

static NSMutableArray					*s_activePopovers = nil;

@implementation SA_PopoverController
+ (BOOL) isPopoverVisibleWithViewControllerClass: (Class) class {
	for (UIPopoverPresentationController *popover in s_activePopovers) {
		UIViewController			*root = popover.presentedView.viewController;
		
		if ([root isKindOfClass: class]) { return true; }
		if ([root isKindOfClass: [UINavigationController class]]) {
			root = [[(id) root viewControllers] firstObject];
			if ([root isKindOfClass: class]) { return true; }
		}
	}
	
	return false;
}

+ (void) dismissAllVisiblePopoversAnimated: (BOOL) animated {
	for (UIPopoverPresentationController *popover in s_activePopovers) {
		UIViewController			*root = popover.presentedView.viewController;
		
		[root dismissViewControllerAnimated: animated completion: nil];
	}
}

@end

@implementation UIViewController (SA_PopoverViewController)
- (void) presentAsPopoverIn: (UIViewController *) parent from: (UIView *) view rect: (CGRect) rect {
	self.modalPresentationStyle = UIModalPresentationPopover;
	self.popoverPresentationController.sourceRect = rect;
	self.popoverPresentationController.sourceView = view;
	
	[parent presentViewController: self animated: true completion: nil];
}


- (void) presentAsPopoverIn: (UIViewController *) parent from: (UIBarButtonItem *) item {
	self.modalPresentationStyle = UIModalPresentationPopover;
	self.popoverPresentationController.barButtonItem = item;
	
	[parent presentViewController: self animated: true completion: nil];
}


@end

@implementation UIView (SA_PopoverViewController)
- (void) presentAsPopoverIn: (UIViewController *) parent from: (UIView *) view rect: (CGRect) rect {
	UIViewController			*controller = [UIViewController new];
	
	controller.view = self;
	
	controller.modalPresentationStyle = UIModalPresentationPopover;
	controller.popoverPresentationController.sourceRect = rect;
	controller.popoverPresentationController.sourceView = view;
	
	[parent presentViewController: controller animated: true completion: nil];
}


- (void) presentAsPopoverIn: (UIViewController *) parent from: (UIBarButtonItem *) item {
	UIViewController			*controller = [UIViewController new];
	
	controller.view = self;
	
	controller.modalPresentationStyle = UIModalPresentationPopover;
	controller.popoverPresentationController.barButtonItem = item;
	
	[parent presentViewController: controller animated: true completion: nil];
}


@end

//+ (BOOL) didCloseExistingSA_PopoverWithClass: (Class) class {
//	if ([class isEqual: [UIViewController class]]) return NO;
//
//	for (UIPopoverController *pc in s_activePopovers) {
//		UINavigationController			*root = (id) pc.contentViewController;
//
//		if ([root isKindOfClass: [UINavigationController class]] && root.viewControllers.count > 0) root = [root.viewControllers objectAtIndex: 0];
//
//		if ([root isKindOfClass: class]) {
//			[pc dismissSA_PopoverAnimated: YES];
//			return YES;
//		}
//	}
//	return NO;
//}
//
//+ (instancetype) presentSA_PopoverForViewController: (UIViewController *) controller fromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
//	Class							class = [controller class];
//
//	if (view.window == nil) return nil;		//no window to pop from
//	if ([class isEqual: [UINavigationController class]]) class = [[(id) controller rootViewController] class];
//	if (controller.onlyAllowOneInstanceInAnSA_Popover && [self didCloseExistingSA_PopoverWithClass: class]) return nil;
//
//
//
//
//
//	if ([controller respondsToSelector: @selector(willAppearInSA_Popover:animated::)]) [controller willAppearInSA_Popover: pc animated: animated];
//	[pc presentPopoverFromRect: rect inView: view permittedArrowDirections: arrowDirections animated:animated];
//	if ([controller respondsToSelector: @selector(didAppearInSA_Popover:animated:)]) [controller didAppearInSA_Popover: pc animated: animated];
//	return pc;
//}
//
//+ (instancetype) presentSA_PopoverForViewController: (UIViewController *) controller fromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
//	UIViewController			*root = controller;
//
//	if ([controller isKindOfClass: [UINavigationController class]]) {
//		NSArray				*childControllers = [(id) controller viewControllers];
//
//		if (childControllers.count) root = childControllers[0];
//	}
//
//	if (root.onlyAllowOneInstanceInAnSA_Popover && [self didCloseExistingSA_PopoverWithClass: [root class]]) return nil;
//
//	UIPopoverController			*pc = (UIPopoverController *) [self SA_PopoverControllerWithContentController: controller];
//
//	if ([controller respondsToSelector: @selector(willAppearInSA_Popover:animated::)]) [controller willAppearInSA_Popover: pc animated: animated];
//	@try {
//		[pc presentPopoverFromBarButtonItem: item permittedArrowDirections: arrowDirections animated: animated];
//	} @catch (id e) {
//		[s_activePopovers removeObject: pc];
//		return nil;
//	}
//	if ([controller respondsToSelector: @selector(didAppearInSA_Popover:animated:)]) [controller didAppearInSA_Popover: pc animated: animated];
//	return pc;
//}
//
//+ (BOOL) popoverControllerShouldDismissSA_Popover: (id) controller {
//	if (![controller isKindOfClass: [UIPopoverController class]]) return false;
//
//	UIPopoverController		*popoverController = (UIPopoverController *) controller;
//	if ([popoverController.contentViewController respondsToSelector: @selector(popoverControllerShouldDismissSA_Popover:)])
//		return [(id) popoverController.contentViewController popoverControllerShouldDismissSA_Popover: popoverController];
//
//	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_PopoverWasDismissed object: popoverController];
//
//	idArgumentBlock				block = popoverController.SA_didDismissBlock;
//
//	if (block) block(popoverController);
//	return YES;
//}
//
//
//+ (void) popoverControllerDidDismissPopover: (id) controller {
//	if (![controller isKindOfClass: [UIPopoverController class]]) return;
//
//	UIPopoverController		*popoverController = (UIPopoverController *) controller;
//
//	if ([popoverController.contentViewController respondsToSelector: @selector(popoverControllerDidDismissPopover:)])
//		[(id) popoverController.contentViewController popoverControllerDidDismissPopover: popoverController];
//	[s_activePopovers removeObject: popoverController];
//}
//
//- (void) dismissSA_PopoverAnimated: (BOOL) animated {
//	[self dismissPopoverAnimated: animated];
//	[s_activePopovers removeObject: self];
//}
//
//+ (void) dismissAllVisibleSA_PopoversAnimated: (BOOL) animated {
//	[self dismissAllVisibleSA_PopoversAnimated: animated except: nil];
//}
//
//+ (void) dismissAllVisibleSA_PopoversAnimated: (BOOL) animated except: (UIPopoverController *) exception {
//	for (UIPopoverController *controller in s_activePopovers.copy) {
//		if (exception != controller) { [controller dismissSA_PopoverAnimated: animated]; }
//	}
//}
//
//+ (BOOL) isSA_PopoverVisibleWithViewControllerClass: (Class) class {
//	if (class == nil) return s_activePopovers.count > 0;
//	UIPopoverController			*controller = [self existingSA_PopoverWithViewControllerClass: class];
//	return [controller isPopoverVisible];
//}
//
//+ (id) existingSA_PopoverWithViewControllerClass: (Class) class {
//	if (class == nil) return nil;
//
//	for (UIPopoverController *pop in s_activePopovers) {
//		UINavigationController		*nav = (id) pop.contentViewController;
//
//		if ([nav isKindOfClass: class]) return pop;
//		if ([nav isKindOfClass: [UINavigationController class]] && [nav.rootViewController isKindOfClass: class]) return pop;
//		if ([nav isKindOfClass: [UITabBarController class]]) {
//			for (UIViewController *tab in nav.viewControllers) {
//				if ([tab isKindOfClass: class]) return pop;
//			}
//		}
//	}
//	return nil;
//}
//
//+ (id) existingSA_PopoverWithView: (UIView *) view { return view.SA_PopoverController; }
//
//
//+ (id) presentSA_PopoverForView: (UIView *) subject fromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
//	UIViewController		*dummyController = [[UIViewController alloc] init];
//	UIView					*parent = [[UIView alloc] initWithFrame: subject.bounds];
//
//	subject.center = parent.contentCenter;
//	[parent addSubview: subject];
//
//	#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_6_0
//		if (RUNNING_ON_70)
//			dummyController.preferredContentSize = subject.bounds.size;
//		else
//	#endif
//		{
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//		dummyController.preferredContentSize = subject.bounds.size;
//#pragma clang diagnostic pop
//		}
//	dummyController.view = parent;
//	return [self presentSA_PopoverForViewController: dummyController fromRect: rect inView: view permittedArrowDirections: arrowDirections animated: animated];
//}
//
//+ (id) presentSA_PopoverForView: (UIView *) subject fromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
//	UIViewController		*dummyController = [[UIViewController alloc] init];
//	UIView					*parent = [[UIView alloc] initWithFrame: subject.bounds];
//
//	subject.center = parent.contentCenter;
//	[parent addSubview: subject];
//
//	#if __IPHONE_OS_VERSION_MIN_REQUIRED > __IPHONE_6_0
//		if (RUNNING_ON_70)
//			dummyController.preferredContentSize = subject.bounds.size;
//		else
//	#endif
//		{
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//			dummyController.preferredContentSize = subject.bounds.size;
//#pragma clang diagnostic pop
//		}
//	dummyController.view = parent;
//	return [self presentSA_PopoverForViewController: dummyController fromBarButtonItem: item permittedArrowDirections: arrowDirections animated: animated];
//}
//
//- (void) setSA_didDismissBlock: (idArgumentBlock) didDismissBlock {
//	[self associateValue: didDismissBlock forKey: SA_POPOVER_DISMISS_BLOCK_KEY];
//}
//
//- (idArgumentBlock) SA_didDismissBlock {
//	idArgumentBlock				block = [self associatedValueForKey: SA_POPOVER_DISMISS_BLOCK_KEY];
//
//	return block;
//}
//
//@end
//
//
//@implementation UIView (SA_PopoverAdditions)
//- (id) SA_PopoverController {
//	return self.viewController.SA_PopoverController;
//}
//@end
//
//@implementation UIViewController (SA_PopoverAdditions)
//- (id) SA_PopoverController {
//	for (UIPopoverController *controller in s_activePopovers) {
//		UINavigationController			*nav = (id) controller.contentViewController;
//
//		if (nav == self) return controller;
//
//		if ([nav respondsToSelector: @selector(viewControllers)] && nav.viewControllers.count > 0 && [nav.viewControllers objectAtIndex: 0] == self) return controller;
//	}
//
//	return self.parentViewController.SA_PopoverController;
//}
//
//- (void) dismissOtherSA_PopoversAnimated: (BOOL) animated {
//	[SA_PopoverController dismissAllVisiblePopoversAnimated: animated except: self.SA_PopoverController];
//}
//
//- (void) presentSA_PopoverFromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
//	[UIPopoverController presentSA_PopoverForViewController: self fromRect: rect inView: view permittedArrowDirections: arrowDirections animated: YES];
//}
//
//- (void) presentSA_PopoverFromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
//	[UIPopoverController presentSA_PopoverForViewController: self fromBarButtonItem: item permittedArrowDirections: arrowDirections animated: animated];
//}
//
//- (void) presentInSA_NavigationPopoverFromRect: (CGRect) rect inView: (UIView *) view permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
//	UINavigationController				*nav = [self isKindOfClass: [UINavigationController class]] ? (id) self : [[UINavigationController alloc] initWithRootViewController: self];
//	[UIPopoverController presentSA_PopoverForViewController: nav fromRect: rect inView: view permittedArrowDirections: arrowDirections animated: YES];
//}
//
//- (void) presentInSA_NavigationPopoverFromBarButtonItem: (UIBarButtonItem *) item permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections animated: (BOOL) animated {
//	UINavigationController				*nav = [[UINavigationController alloc] initWithRootViewController: self];
//	[UIPopoverController presentSA_PopoverForViewController: nav fromBarButtonItem: item permittedArrowDirections: arrowDirections animated: animated];
//}
//
//- (void) willAppearInSA_Popover: (id) controller animated: (BOOL) animated { }
//- (void) didAppearInSA_Popover: (id) controller animated: (BOOL) animated { }
//- (BOOL) onlyAllowOneInstanceInAnSA_Popover { return YES; }
//
//@end
//
//
