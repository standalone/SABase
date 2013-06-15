//
//  UIColor+SA_Additions.h
//
//  Created by Ben Gottlieb on 4/23/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#define vendColor(r, g, b) static UIColor *ret; if (ret == nil) ret = [UIColor colorWithRed:(CGFloat)r/255.0 green:(CGFloat)g/255.0 blue:(CGFloat)b/255.0 alpha:1.0]; return ret

#define	GENERATE_UICOLOR(r, g, b)	[UIColor colorWithRed:(CGFloat)r/255.0 green:(CGFloat)g/255.0 blue:(CGFloat)b/255.0 alpha:1.0]

@interface UIColor (UIColor_SA_Additions)

@property(readonly) const CGFloat * rgbaComponents;
@property(readonly) const CGFloat * hsbaComponents;


+ (UIColor *)  colorWithHexString: (NSString *) string;
+ (UIColor *)  colorWithString: (NSString *) string;
- (UIColor *)  initWithHexString: (NSString *) string;
- (NSString *) hexString;
- (NSString *) hexStringWithAlpha;


@end
