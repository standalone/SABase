//
//  UIButton+SA_Helpers.m
//  Crosswords iOS
//
//  Created by Ben Gottlieb on 6/17/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "UIButton+SA_Helpers.h"

@implementation UIButton (SA_Helpers)

- (void) setupBackgroundImageWithPrefix: (NSString *) prefix {
	
	[self setBackgroundImage: [[UIImage imageNamed: $S(@"%@-button.png", prefix)] stretchableImageWithLeftCapWidth: 15.0 topCapHeight: 22.0] forState: UIControlStateNormal];
	[self setBackgroundImage: [[UIImage imageNamed: $S(@"%@-button-highlight.png", prefix)] stretchableImageWithLeftCapWidth: 15.0 topCapHeight: 22.0] forState: UIControlStateHighlighted];
	[self setBackgroundImage: [[UIImage imageNamed: $S(@"%@-button-highlight.png", prefix)] stretchableImageWithLeftCapWidth: 15.0 topCapHeight: 22.0] forState: UIControlStateSelected];
}

@end
