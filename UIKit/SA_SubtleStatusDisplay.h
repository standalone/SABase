//
//  SA_SubtleStatusDisplay.h
//  ManualOverride
//
//  Created by Ben Gottlieb on 11/28/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
	subtleStatusSide_bottom,
	subtleStatusSide_top,
	subtleStatusSide_current
} subtleStatusSide;


@interface SA_SubtleStatusDisplay : UIView

@property (nonatomic) subtleStatusSide side;
@property (nonatomic, strong) NSString *text;					// this can be an attributed strings
@property (nonatomic) BOOL showActivityIndicator;
@property (nonatomic, copy) simpleBlock touchedBlock;

+ (SA_SubtleStatusDisplay *) display;
+ (BOOL) isVisible;
+ (SA_SubtleStatusDisplay *) showStatusText: (NSString *) text onSide: (subtleStatusSide) side withActivityIndicator: (BOOL) showActivityIndicator;
+ (void) hideStatus: (BOOL) animated;
+ (void) hideStatus;
+ (void) dismissAfter: (NSTimeInterval) seconds;
+ (void) setDisplayHeight: (NSUInteger) newHeight;										// defaults to 30, one line.
@end
