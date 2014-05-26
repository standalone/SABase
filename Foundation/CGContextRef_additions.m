//
//  CGContextRef_additions.c
//  SABase
//
//  Created by Ben Gottlieb on 5/26/14.
//
//

#import "CGContextRef_additions.h"

void	CGContextDrawRadialGradientInRect(CGContextRef ctx, CGRect rect, UIColor *innerColor, UIColor *outerColor) {
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSArray* colors = @[ (id) innerColor.CGColor, (id) outerColor.CGColor ];
	CGFloat locations[] = {.25, .75};
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, locations);
	CGPoint center = (CGPoint){rect.size.width / 2, rect.size.height  / 2};
	CGContextDrawRadialGradient(ctx, gradient, center, 0, center, MAX(rect.size.width, rect.size.height), kCGGradientDrawsAfterEndLocation);
	
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
}