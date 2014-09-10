//
//  UIWindow+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 5/26/14.
//
//

#import "UIWindow+SA_Additions.h"
#import "SA_Utilities.h"

@implementation UIWindow (SA_Additions)

+ (CGAffineTransform) sa_transformForUserInterfaceOrientation: (UIInterfaceOrientation) orientation {
    switch (orientation) {
        case UIInterfaceOrientationLandscapeLeft: return CGAffineTransformMakeRotation(-(90 * M_PI / 180));
        case UIInterfaceOrientationLandscapeRight: return CGAffineTransformMakeRotation((90 * M_PI / 180));
        case UIInterfaceOrientationPortraitUpsideDown: return CGAffineTransformMakeRotation((180 * M_PI / 180));
        case UIInterfaceOrientationPortrait: return CGAffineTransformIdentity;
        default: return CGAffineTransformIdentity;
    }
}

+ (CGAffineTransform) sa_transformForCurrentUserInterfaceOrientation {
	return [self sa_transformForUserInterfaceOrientation: [UIApplication sharedApplication].statusBarOrientation];
}

+ (UIWindow *) sa_fullScreenWindowWithBaseView: (UIView *) baseView {
	CGRect					frame = [UIScreen mainScreen].bounds;
	UIWindow				*window = [[UIWindow alloc] initWithFrame: frame];
	UIViewController		*windowController = [UIViewController new];
	
	baseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	windowController.view = baseView;
	window.rootViewController = windowController;
	return window;
}

+ (CGAffineTransform) sa_baseTransformForOrientation: (UIInterfaceOrientation) orientation {
	if (RUNNING_ON_80) return CGAffineTransformIdentity;
	
	if (orientation == UIInterfaceOrientationUnknown) return UIWindow.sa_transformForCurrentUserInterfaceOrientation;
	return [UIWindow sa_transformForUserInterfaceOrientation: orientation];
}



@end
