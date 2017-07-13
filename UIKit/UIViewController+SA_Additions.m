//
//  UIViewController+Additions.m
//
//  Created by Ben Gottlieb on 8/8/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "UIViewController+SA_Additions.h"


__weak UIViewController *s_frontmostFocusedViewController = nil;


//================================================================================================================
#pragma mark SA_ViewController
@implementation SA_ViewController : UIViewController
+ (UIViewController *) frontmostFocusedViewController {
	return [(id) s_frontmostFocusedViewController focusedViewControllerAncestor];
}

- (BOOL) canBeFrontmostFocusedViewController {
	return self.splitViewController == nil && self.tabBarController == nil;
}

- (void) viewWillAppear: (BOOL) animated {
	s_frontmostFocusedViewController = self;
	[super viewWillAppear: animated];
}

@end

//================================================================================================================
#pragma mark SA_TableViewController
@implementation SA_TableViewController : UITableViewController
- (void) viewWillAppear: (BOOL) animated {
	s_frontmostFocusedViewController = self;
	[super viewWillAppear: animated];
}

- (BOOL) canBeFrontmostFocusedViewController { return YES; }
@end


@implementation UINavigationController (UINavigationController__SA_Additions)
@dynamic rootViewController;
- (UIViewController *) rootViewController { return self.viewControllers.count ? self.viewControllers[0] : nil; }
@end


@implementation UIViewController (UIViewController_SA_Additions)

+ (id) controller {
	NSString			*nibName = self.nibName;
	NSBundle			*bundle = [NSBundle bundleForClass: self];
	
	if ([bundle pathForResource: nibName ofType: @"nib"] != nil) {
		return [[self alloc] initWithNibName: nibName bundle: bundle];
	}
	
	return [[self alloc] init];
}

+ (NSString *) nibName { return NSStringFromClass(self); }

- (UIViewController *) focusedViewControllerAncestor {
	if (self.parentViewController && [self.parentViewController respondsToSelector: @selector(focusedViewControllerAncestor)]) return [(id) self.parentViewController focusedViewControllerAncestor];
	if (self.tabBarController) return self.tabBarController;
	if (self.navigationController) return self.navigationController;
	return self;
}

- (void) addFullSizeChildViewController: (UIViewController *) controller {
	[self addChildViewController: controller withViewInFrame: CGRectZero];
}

- (void) addChildViewController: (UIViewController *) controller withViewInFrame: (CGRect) frame {
	if (CGRectEqualToRect(frame, CGRectZero)) {
		controller.view.frame = self.view.bounds;
		controller.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	} else
		controller.view.frame = frame;
		
	[self.view addSubview: controller.view];
	[self addChildViewController: controller];
}

- (UIPageViewController *) sa_pageViewController {
	UIViewController			*controller = self;
	Class						class = [UIPageViewController class];
	
	while (controller && ![controller isKindOfClass: class]) {
		controller = controller.parentViewController;
	}
	
	return (id) controller;
}

- (void) removeFromParentViewControllerAndView {
	[self.view removeFromSuperview];
	[self removeFromParentViewController];
}

- (NSSet *) childControllers {
	if (![self isKindOfClass: [UINavigationController class]] && ![self isKindOfClass: [UITabBarController class]]) {
		if ([self respondsToSelector: @selector(childViewControllers)]) return [NSSet setWithArray: [(id) self childViewControllers]];
	}
	NSMutableSet				*kids = [self respondsToSelector: @selector(viewControllers)] ? [NSMutableSet setWithArray: [(id) self viewControllers]] : [NSMutableSet set];
	
	#pragma clang diagnostic push
	#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		if (self.presentedViewController) [kids addObject: self.presentedViewController];
	#pragma clang diagnostic pop
	
	for (UIViewController *controller in kids.copy) {
		[kids unionSet: [controller childControllers]];
	}
	[kids addObject: self];
	return kids;
}

- (void) slideViewController: (UIViewController *) controller inToView: (UIView *) view fromDirection: (UIViewControllerAnimationDirection) direction withBounce: (BOOL) bounce {
	if (view == nil) view = self.view;
	
	controller.view.bounds = view.bounds;
	
	CGPoint					newCenter = view.contentCenter;
	
	switch (direction) {
		case viewControllerAnimationDirection_left: newCenter = CGPointMake(-controller.view.bounds.size.width * 1.5, controller.view.bounds.size.height / 2); break;
		case viewControllerAnimationDirection_right: newCenter = CGPointMake(controller.view.bounds.size.width * 1.5, controller.view.bounds.size.height / 2); break;
		case viewControllerAnimationDirection_top: newCenter = CGPointMake(controller.view.bounds.size.width * 0.5, -controller.view.bounds.size.height * 1.5); break;
		case viewControllerAnimationDirection_bottom: newCenter = CGPointMake(controller.view.bounds.size.width * 0.5, controller.view.bounds.size.height * 1.5); break;
		case viewControllerAnimationDirection_fadeIn: controller.view.alpha = 0.0; break;
		case viewControllerAnimationDirection_dropDown:
			controller.view.alpha = 0.0; 
			controller.view.transform = CGAffineTransformMakeScale(10, 10);
			break;
		default: break;
	}
	
	controller.view.center = newCenter;
	[view addSubview: controller.view];
	[(id) self addChildViewController: controller];
	[UIView animateWithDuration: 0.2 animations: ^{
		if (direction == viewControllerAnimationDirection_dropDown) {
			controller.view.alpha = 1.0;
			controller.view.transform = CGAffineTransformIdentity;
			controller.view.center = view.contentCenter;
		} else if (direction == viewControllerAnimationDirection_fadeIn) {
			controller.view.alpha = 1.0;
			controller.view.center = view.contentCenter;
		} else if (bounce) {
			switch (direction) {
				case viewControllerAnimationDirection_left: controller.view.center = CGPointMake(view.contentCenter.x * 1.1, view.contentCenter.y); break;
				case viewControllerAnimationDirection_right: controller.view.center = CGPointMake(view.contentCenter.x * 0.9, view.contentCenter.y); break;
				case viewControllerAnimationDirection_top: controller.view.center = CGPointMake(view.contentCenter.x, view.contentCenter.y * 1.1); break;
				case viewControllerAnimationDirection_bottom: controller.view.center = CGPointMake(view.contentCenter.x, view.contentCenter.y * 0.9); break;
				default: break;
			}
		} else
			controller.view.center = view.contentCenter;
	} completion: ^(BOOL finished) {
		if (bounce) {
			[UIView animateWithDuration: 0.05 animations: ^{ controller.view.center = view.contentCenter; }];
		} else
			controller.view.center = view.contentCenter;
	}];

}

- (void) slideViewController: (UIViewController *) controller outTowardsDirection: (UIViewControllerAnimationDirection) direction {
	[UIView animateWithDuration: 0.2 animations: ^{
		switch (direction) {
			case viewControllerAnimationDirection_left: controller.view.center = CGPointMake(controller.view.bounds.size.width * 1.5, controller.view.bounds.size.height / 2); break;
			case viewControllerAnimationDirection_right: controller.view.center = CGPointMake(-controller.view.bounds.size.width * 1.5, controller.view.bounds.size.height / 2); break;
			case viewControllerAnimationDirection_top: controller.view.center = CGPointMake(controller.view.bounds.size.width * 0.5, - controller.view.bounds.size.height * 1.5); break;
			case viewControllerAnimationDirection_bottom: controller.view.center = CGPointMake(controller.view.bounds.size.width * 0.5, controller.view.bounds.size.height * 1.5); break;
			case viewControllerAnimationDirection_fadeIn: controller.view.alpha = 0.0; break;
			default:	
			case viewControllerAnimationDirection_dropDown: 
				controller.view.alpha = 0.0;
				controller.view.transform = CGAffineTransformMakeScale(10, 10);
				break;
		}
	} completion: ^(BOOL completed) {
		[(id) controller removeFromParentViewController];
		[controller.view removeFromSuperview];
	}];
}

- (void) removeAllChildViewControllers {
	if ([self isKindOfClass: [UINavigationController class]]) {
		[(id) self popToRootViewControllerAnimated: NO];
	} else {
		for (UIViewController *child in [[(id) self childViewControllers] copy]) {
			[child.view removeFromSuperview];
			[(id) child removeFromParentViewController];
		}
	}
}
@end
