//
//  SA_FullScreenBlockingView.h
//  Crosswords7
//
//  Created by Ben Gottlieb on 3/22/15.
//  Copyright (c) 2015 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(UInt8, SA_FullScreenBlockingViewMode) {
	SA_FullScreenBlockingViewModeDismissAndEatEvent,
	SA_FullScreenBlockingViewModeDismissAndPassThroughEvent,
};

@interface SA_FullScreenBlockingView : UIView
+ (instancetype) blockerForViews: (NSArray *) targets;

- (void) dismiss;

@property (nonatomic, copy) simpleBlock didDismissBlock;
@property (nonatomic) SA_FullScreenBlockingViewMode mode;

@end
