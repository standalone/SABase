//
//  UIButton+SA_Helpers.m
//  Crosswords iOS
//
//  Created by Ben Gottlieb on 6/17/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "UIButton+SA_Helpers.h"

@implementation UIButton (SA_Helpers)

- (void) SA_setupBackgroundImageWithPrefix: (NSString *) prefix {
	UIImage				*buttonImage = [UIImage imageNamed: $S(@"%@-button", prefix)];
	
	if (buttonImage) {
		[self setBackgroundImage: [buttonImage stretchableImageWithLeftCapWidth: 15.0 topCapHeight: 22.0] forState: UIControlStateNormal];
		[self setBackgroundImage: [[UIImage imageNamed: $S(@"%@-button-highlight", prefix)] stretchableImageWithLeftCapWidth: 15.0 topCapHeight: 22.0] forState: UIControlStateHighlighted];
		[self setBackgroundImage: [[UIImage imageNamed: $S(@"%@-button-highlight", prefix)] stretchableImageWithLeftCapWidth: 15.0 topCapHeight: 22.0] forState: UIControlStateSelected];
	} else {
		[self setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
		
		self.layer.borderColor = [UIColor blackColor].CGColor;
		self.layer.borderWidth = 1.0;
		self.layer.cornerRadius = 4;
	}
}

@end
