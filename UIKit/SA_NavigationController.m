//
//  SA_NavigationController.m
//
//  Created by Ben Gottlieb on 10/25/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "SA_NavigationController.h"

@interface UIViewController (SA_willPopViewControllerAnimated)
- (void) navigatioController: (UINavigationController *) nc willPopViewController: (UIViewController *) vc animated: (BOOL) animated;
@end


@implementation SA_NavigationController

- (UIViewController *) popViewControllerAnimated: (BOOL) animated {
	if ([self.delegate respondsToSelector: @selector(navigatioController:willPopViewController:animated:)]) [(id) self.delegate navigatioController: self willPopViewController: self.topViewController animated: animated];
	return [super popViewControllerAnimated: animated];
}

- (NSArray *) popToRootViewControllerAnimated: (BOOL) animated {
	if ([self.delegate respondsToSelector: @selector(navigatioController:willPopViewController:animated:)]) for (int i = 1; i < self.viewControllers.count; i++) {
		UIViewController				*controller = [self.viewControllers objectAtIndex: i];
		
		[(id) self.delegate navigatioController: self willPopViewController: controller animated: animated];
	}
	
	return [super popToRootViewControllerAnimated: animated];
}

@end
