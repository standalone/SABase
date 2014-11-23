//
//  UIWindow+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 5/26/14.
//
//

#import "UIWindow+SA_Additions.h"
#import "SA_Utilities.h"
#import "UIView+SA_Additions.h"

@interface SA_FullScreenBlockingWindow : UIWindow

@end

@interface SA_FullScreenBlockingViewController : UIViewController

@end

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
	//CGFloat					maxDim = MAX(frame.size.width, frame.size.height), minDim = MIN(frame.size.width, frame.size.height);
	UIWindow				*window = [[SA_FullScreenBlockingWindow alloc] initWithFrame: frame];
	UIViewController		*windowController = [SA_FullScreenBlockingViewController new];
	
	baseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[windowController.view addSubview: baseView];
	baseView.frame = window.bounds;
	baseView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	baseView.center = windowController.view.contentCenter;
	
	window.rootViewController = windowController;
	return window;
}

+ (CGAffineTransform) sa_baseTransformForOrientation: (UIInterfaceOrientation) orientation {
	if (RUNNING_ON_80)
		return CGAffineTransformIdentity;
	
	if (orientation == UIInterfaceOrientationUnknown) return UIWindow.sa_transformForCurrentUserInterfaceOrientation;
	return [UIWindow sa_transformForUserInterfaceOrientation: orientation];
}

+ (UIWindow *) sa_rootWindow {
	UIWindow			*biggest = nil;
	
	for (UIWindow *window in [UIApplication sharedApplication].windows) {
		if (window.rootViewController) return window;
		
		if (window.bounds.size.width > biggest.bounds.size.width && window.bounds.size.height > biggest.bounds.size.height) biggest = window;
	}
	return biggest;
}

@end

@implementation SA_FullScreenBlockingViewController

@end

@implementation SA_FullScreenBlockingWindow

@end