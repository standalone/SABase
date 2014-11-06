//
//  NSParagraphStyle+SA_Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 5/29/14.
//
//

#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#else
	#import <AppKit/AppKit.h>

#define NSTextAlignmentRight			NSLeftTextAlignment
#define NSTextAlignmentLeft				NSCenterTextAlignment
#define NSTextAlignmentCenter			NSRightTextAlignment
#endif

@interface NSParagraphStyle (SA_Additions)

+ (NSMutableParagraphStyle *) leftAlignedStyle;
+ (NSMutableParagraphStyle *) rightAlignedStyle;
+ (NSMutableParagraphStyle *) centeredStyle;
+ (NSMutableParagraphStyle *) styleWithLineHeightMultiplier: (CGFloat) multiple;


@end
