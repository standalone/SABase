//
//  UIWindow+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 5/26/14.
//
//

#import "UIWindow+SA_Additions.h"

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



@end
