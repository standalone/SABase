//
//  UIViewController+Additions.m
//
//  Created by Ben Gottlieb on 8/8/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "UIViewController+SA_Additions.h"
#import "UIView+SA_Additions.h"

@implementation UINavigationController (UINavigationController__SA_Additions)
- (UIViewController *) rootViewController { return self.viewControllers.count ? self.viewControllers[0] : nil; }
@end


@implementation UIViewController (UIViewController_SA_Additions)

- (NSSet *) childControllers {
	if (![self isKindOfClass: [UINavigationController class]] && ![self isKindOfClass: [UITabBarController class]]) {
		if ([self respondsToSelector: @selector(childViewControllers)]) return [NSSet setWithArray: [(id) self childViewControllers]];
	}
	NSMutableSet				*kids = [self respondsToSelector: @selector(viewControllers)] ? [NSMutableSet setWithArray: [(id) self viewControllers]] : [NSMutableSet set];
	
	if (self.modalViewController) [kids addObject: self.modalViewController];
	
	for (UIViewController *controller in [[kids copy] autorelease]) {
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
	if (RUNNING_ON_50) [(id) self addChildViewController: controller];
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
		if (RUNNING_ON_50) [(id) controller removeFromParentViewController];
		[controller.view removeFromSuperview];
	}];
}

- (void) removeAllChildViewControllers {
	if ([self isKindOfClass: [UINavigationController class]]) {
		[(id) self popToRootViewControllerAnimated: NO];
	} else if (RUNNING_ON_50) {
		for (UIViewController *child in [[(id) self childViewControllers] copy]) {
			[child.view removeFromSuperview];
			[(id) child removeFromParentViewController];
		}
	}
}

- (UIViewController *) farthestAncestorController {
	UIViewController			*parent = self.parentViewController;
	
	while (parent.parentViewController) {
		parent = parent.parentViewController;
	}
	
	return parent;
}


@end
