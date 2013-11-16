//
//  UIFont+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 10/26/13.
//
//

#import "UIFont+SA_Additions.h"

@implementation UIFont (SA_Additions)
+ (UIFont *) safeFontWithName: (NSString *) name size: (CGFloat) size {
	UIFont				*font = [self fontWithName: name size: size];
	
	if (font) return font;
	
	UIFontDescriptorSymbolicTraits			traits = 0;

	if ([name isEqual: @"HelveticaNeue-Italic"]) {
		name = @"HelveticaNeue";
		traits = UIFontDescriptorTraitItalic;
	}
	else if ([name.lowercaseString hasSuffix: @"-italic"]) { name = [name substringToIndex: 7]; traits = UIFontDescriptorTraitItalic;}
	else if ([name.lowercaseString hasSuffix: @"-bold"]) { name = [name substringToIndex: 5]; traits = UIFontDescriptorTraitBold;}
	
	if (traits) {
		Class						descriptorClass = NSClassFromString(@"UIFontDescriptor");
		
		if (descriptorClass) {
			UIFontDescriptor			*descriptor = [[descriptorClass fontDescriptorWithName: name size: size] fontDescriptorWithSymbolicTraits: traits];
			
			if (descriptor) font = [UIFont fontWithDescriptor: descriptor size: size];
			if (font) return font;
		}
	}
	
	return [UIFont systemFontOfSize: size];
}
@end
