//
//  UILabel+Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 2/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UILabel+SA_Additions.h"

@implementation UILabel  (SA_textAdditions)
- (CGSize) sizeOfCurrentTextInExistingWidth {
	CGSize				constraint = CGSizeMake(self.bounds.size.width, 500000);
	CGSize				size = [self.text sizeWithFont: self.font constrainedToSize: constraint lineBreakMode: self.lineBreakMode];
	
	return size;
}

- (void) autosizeForExistingWidth: (float) width {
	CGSize				constraint = CGSizeMake(width, 500000);
	CGSize				size = [self.text sizeWithFont: self.font constrainedToSize: constraint lineBreakMode: self.lineBreakMode];
	CGRect				frame = self.frame;
	
	switch (self.textAlignment) {
		default:
		case NSTextAlignmentLeft:
			self.frame = CGRectMake(frame.origin.x, frame.origin.y, size.width, size.height);
			break;
			
		case NSTextAlignmentRight:
			self.frame = CGRectMake(frame.origin.x + frame.size.width - size.width, frame.origin.y, size.width, size.height);
			break;
			
		case NSTextAlignmentCenter:
			self.frame = CGRectMake(frame.origin.x + (frame.size.width - size.width) / 2, frame.origin.y, size.width, size.height);
			break;
	}	
}

- (void) autosizeForExistingSize {
	CGSize				constraint = self.bounds.size;
	CGSize				size = [self.text sizeWithFont: self.font constrainedToSize: constraint lineBreakMode: self.lineBreakMode];
	CGRect				frame = self.frame;
	
	switch (self.textAlignment) {
		default:
		case NSTextAlignmentLeft:
			self.frame = CGRectMake(frame.origin.x, frame.origin.y, size.width, size.height);
			break;
			
		case NSTextAlignmentRight:
			self.frame = CGRectMake(frame.origin.x + frame.size.width - size.width, frame.origin.y, size.width, size.height);
			break;
			
		case NSTextAlignmentCenter:
			self.frame = CGRectMake(frame.origin.x + (frame.size.width - size.width) / 2, frame.origin.y, size.width, size.height);
			break;
	}
	
	
}
@end