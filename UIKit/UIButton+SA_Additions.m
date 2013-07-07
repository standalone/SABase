//
//  UIButton+Additions.m
//  ScreeningRoom
//
//  Created by Ben Gottlieb on 8/13/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "UIButton+SA_Additions.h"


@implementation UIButton (UIButton_SA_Additions)

+ (id) buttonWithImageNamed: (NSString *) imageName {
	UIButton			*button = [self buttonWithType: UIButtonTypeCustom];
	NSString			*rawName = [imageName stringByDeletingPathExtension];
	UIImage				*normalImage = [UIImage imageNamed: imageName];
	UIImage				*highlighted = [UIImage imageNamed: $S(@"%@_highlighted.png", rawName)];
	UIImage				*selected = [UIImage imageNamed: $S(@"%@_selected.png", rawName)];
	UIImage				*highlightedSelected = [UIImage imageNamed: $S(@"%@_highlighted_selected.png", rawName)];
	UIImage				*disabled = [UIImage imageNamed: $S(@"%@_disabled.png", rawName)];
	
	[button setImage: normalImage forState: UIControlStateNormal];
	if (highlighted) [button setImage: highlighted forState: UIControlStateHighlighted];
	if (disabled) [button setImage: disabled forState: UIControlStateDisabled];
	if (selected) [button setImage: selected forState: UIControlStateSelected];
	if (highlightedSelected) [button setImage: highlightedSelected forState: UIControlStateHighlighted | UIControlStateSelected];
	
	button.bounds = CGRectFromSize(normalImage.size);
	button.center = CGRectMidpoint(button.bounds);
	
	return button;
}
@end
