//
//  CGContextRef_additions.c
//  SABase
//
//  Created by Ben Gottlieb on 5/26/14.
//
//

#import "CGContextRef_additions.h"

void	CGContextDrawRadialGradientInRect(CGContextRef ctx, CGRect rect, UIColor *innerColor, UIColor *outerColor) {
	CGFloat				locations[2] = {0.0f, 1.0f};
	size_t				locationsCount = DIM(locations);
	CGFloat				colors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f};
	
	CGColorSpaceRef		colorSpace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef		gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
	
	CGColorSpaceRelease(colorSpace);

	CGPoint				center = CGPointMake(rect.size.width/2, rect.size.height/2);
	float				radius = MIN(rect.size.width , rect.size.height) ;

	CGContextDrawRadialGradient (ctx, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(gradient);

	
//	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//	NSArray* colors = @[ (id) innerColor.CGColor, (id) outerColor.CGColor ];
//	CGFloat locations[] = {.25, .75};
//	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, locations);
//	CGPoint center = (CGPoint){rect.size.width / 2, rect.size.height  / 2};
//	CGContextDrawRadialGradient(ctx, gradient, center, 0, center, MAX(rect.size.width, rect.size.height), kCGGradientDrawsAfterEndLocation);
//	
//	CGGradientRelease(gradient);
//	CGColorSpaceRelease(colorSpace);
}