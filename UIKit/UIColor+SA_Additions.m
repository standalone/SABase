//
//  UIColor+Additions.m
//
//  Created by Ben Gottlieb on 4/23/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "UIColor+SA_Additions.h"
#import "SA_Utilities.h"

@implementation UIColor (UIColor_SA_Additions)

+ (UIColor *)  colorWithSA_String: (NSString *) string {
	if (string.length == 0) return nil;
	if ([string hasPrefix: @"rgb("] || [string hasPrefix: @"rgba("]) {
		NSArray				*components = [string componentsSeparatedByString: @","];
		float				values[3] = {0.0, 0.0, 0.0};
		CGFloat				alpha = 1.0;
		
		if (components.count == 3 || components.count == 4) {
			values[0] = [[[components[0] componentsSeparatedByString: @"("] lastObject] floatValue] / 255.0;
			values[1] = [components[1] floatValue] / 255.0;
			values[2] = [[components[2] componentsSeparatedByString: @")"][0] floatValue] / 255.0;
			if (components.count == 4) alpha = [[components[3] componentsSeparatedByString: @")"][0] floatValue];
			
			if (values[0] == 0 && values[1] == 0 && values[2] == 0 && alpha == 1.0) return [UIColor blackColor];
			if (values[0] == 1.0 && values[1] == 1.0 && values[2] == 1.0 && alpha == 1.0) return [UIColor whiteColor];

			return [[self alloc] initWithRed: values[0] green: values[1] blue: values[2] alpha: alpha];
		}
	}
	
	SEL						sel = NSSelectorFromString(string);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
	UIColor					*color = ([self respondsToSelector: sel]) ? [self performSelector: sel] : nil;
#pragma clang diagnostic pop
	if (color) return color;
	return [[UIColor alloc] initWithSA_HexString: string];
}

+ (UIColor *)  colorWithSA_HexString: (NSString *) string {
	return [[UIColor alloc] initWithSA_HexString: string];
}

- (UIColor *)  initWithSA_HexString: (NSString *) string {
#define							CharToInteger(c)				(((c >= 'a' && c <= 'f') ? (10 + c - 'a') : ((c >= '0' && c <= '9') ? (c - '0') : 0)))
	NSArray							*chunks = [string componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if (chunks.count > 0) string = chunks[0];
	
	float							values[3] = {0.0, 0.0, 0.0};
	CGFloat							alpha = 1.0;
	char							*raw = (char *) [[string lowercaseString] UTF8String];
	
	
	if ([string length] == 0) return nil;
	if (raw[0] == '#') raw++;

	

	if (strlen(raw) == 3 || strlen(raw) == 4) {
		values[0] = CharToInteger(raw[0]) * 16 + CharToInteger(raw[0]);
		values[1] = CharToInteger(raw[1]) * 16 + CharToInteger(raw[1]);
		values[2] = CharToInteger(raw[2]) * 16 + CharToInteger(raw[2]);
		if (strlen(raw) == 4) alpha = CharToInteger(raw[3]) * 16 + CharToInteger(raw[3]);
	} else if (strlen(raw) == 6 || strlen(raw) == 8) {
		values[0] = CharToInteger(raw[0]) * 16 + CharToInteger(raw[1]);
		values[1] = CharToInteger(raw[2]) * 16 + CharToInteger(raw[3]);
		values[2] = CharToInteger(raw[4]) * 16 + CharToInteger(raw[5]);
		
		if (strlen(raw) == 8) alpha = CharToInteger(raw[5]) * 16 + CharToInteger(raw[6]);
	} 
	
	if (values[0] == 0 && values[1] == 0 && values[2] == 0) return [UIColor blackColor];
	if (values[0] == 255 && values[1] == 255 && values[2] == 255) return [UIColor whiteColor];

	return [self initWithRed: values[0] / 255.0 green: values[1] / 255.0 blue: values[2] / 255.0 alpha: alpha];
}

- (NSString *) SA_hexString {
	CGColorRef					color = self.CGColor;
	size_t						numComponents = CGColorGetNumberOfComponents(color);
	const CGFloat				*components = CGColorGetComponents(color);
	
	if (numComponents == 2) {
		return [NSString stringWithFormat: @"%02X%02X%02X", (UInt8) (components[0] * 255), (UInt8) (components[0] * 255), (UInt8) (components[0] * 255)];
	}
	if (numComponents == 4) {
		return [NSString stringWithFormat: @"%02X%02X%02X", (UInt8) (components[0] * 255), (UInt8) (components[1] * 255), (UInt8) (components[2] * 255)];
	}
	
	return @"";
}

- (NSString *) SA_hexStringWithAlpha {
	CGColorRef					color = self.CGColor;
	size_t						numComponents = CGColorGetNumberOfComponents(color);
	const CGFloat				*components = CGColorGetComponents(color);
	
	if (numComponents == 2) {
		return [NSString stringWithFormat: @"%02X%02X%02X%02X", (UInt8) (components[0] * 255), (UInt8) (components[0] * 255), (UInt8) (components[0] * 255), (UInt8) (components[1] * 255)];
	}
	if (numComponents == 4) {
		return [NSString stringWithFormat: @"%02X%02X%02X%02X", (UInt8) (components[0] * 255), (UInt8) (components[1] * 255), (UInt8) (components[2] * 255), (UInt8) (components[3] * 255)];
	}
	return @"";
}

- (const CGFloat *) SA_RGBAComponents {
	return CGColorGetComponents(self.CGColor);
}

- (const CGFloat *) SA_HSBAComponents {
	const CGFloat				*rgb = self.SA_RGBAComponents;
	float						r = rgb[0], g = rgb[1], b = rgb[2];
	static CGFloat				results[4];
	CGFloat						minValue = MIN(r, MIN(g, b));
	CGFloat						maxValue = MAX(r, MAX(g, b));
	CGFloat						delta = maxValue - minValue;
	
	results[0] = results[1] = 0.0;			//initialize to black
	results[2] = maxValue;
	results[3] = rgb[3];

	if (delta != 0) {
		results[1] = delta / maxValue;
		
		CGFloat				rDelta = (((maxValue - r) / 6.0) + (delta / 2.0)) / delta;
		CGFloat				gDelta = (((maxValue - g) / 6.0) + (delta / 2.0)) / delta;
		CGFloat				bDelta = (((maxValue - b) / 6.0) + (delta / 2.0)) / delta;
		
		if (r == maxValue) {
			results[0] = bDelta - gDelta;
		} else if (g == maxValue) {
			results[0] = (rDelta - bDelta) + 1.0 / 3.0;
		} else if (b == maxValue) {
			results[0] = (gDelta - rDelta) + 2.0 / 3.0;
		} 
		
		if (results[0] < 0) results[0] += 1.0;
		if (results[0] > 1.0) results[0] -= 1.0;
	}
	return results;
}

- (UIColor *) appropriateContrastingTextColor {
	CGFloat					h, s, b, a;
	
	if ([self getHue: &h saturation: &s brightness: &b alpha: &a]) return (b > 0.5) ? [UIColor blackColor] : [UIColor whiteColor];
	
	CGFloat					w;
	
	if ([self getWhite: &w alpha: &a]) {
		return (w > 0.5) ? [UIColor blackColor] : [UIColor whiteColor];
	}
	return [UIColor blackColor];
}

- (CGFloat) alpha {
	CGFloat					a;
	
	if ([self getHue: NULL saturation: NULL brightness: NULL alpha: &a]) return a;
	if ([self getWhite: NULL alpha: &a]) return a;
	return 1.0;
}

@end

NSString *				NSStringFromCGColor(CGColorRef color) {
	size_t					componentCount = CGColorGetNumberOfComponents(color);
	const CGFloat			*comp = CGColorGetComponents(color);
	
	if (componentCount == 2) return $S(@"White: %.0f, a: %.0f", comp[0], comp[1]);
	
	if (componentCount != 4) return $S(@"not an RGB color (%d comp)", (UInt16) componentCount);
	return $S(@"R: %.0f, G: %.0f, B: %.0f, a: %.0f", comp[0], comp[1], comp[2], comp[3]);
}


