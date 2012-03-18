//
//  UIViewController+Additions.h
//
//  Created by Ben Gottlieb on 8/8/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
	viewControllerAnimationDirection_none,
	viewControllerAnimationDirection_left,
	viewControllerAnimationDirection_right,
	viewControllerAnimationDirection_top,
	viewControllerAnimationDirection_bottom,
	viewControllerAnimationDirection_dropDown,
	viewControllerAnimationDirection_fadeIn
} UIViewControllerAnimationDirection;

@interface UIViewController (UIViewController_Additions)
@property (nonatomic, readonly) UIViewController *farthestAncestorController;
- (NSSet *) childControllers;

- (void) slideViewController: (UIViewController *) controller inToView: (UIView *) view fromDirection: (UIViewControllerAnimationDirection) direction withBounce: (BOOL) bounce;
- (void) slideViewController: (UIViewController *) controller outTowardsDirection: (UIViewControllerAnimationDirection) direction;
- (void) removeAllChildViewControllers;
- (UIViewController *) farthestAncestorController;
@end
