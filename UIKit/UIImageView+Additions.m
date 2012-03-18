//
//  UIImageView+Additions.m
//
//  Created by Ben Gottlieb on 8/5/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "UIImageView+Additions.h"

@implementation UIImageView (UIImageView_SA_Additions)

- (CGRect) imageContentFrame {
	CGSize							size = self.image.size;
	CGSize							mySize = self.bounds.size;
	float							aspect, myAspect, newWidth, newHeight;
	
	if (size.width >= mySize.width && size.height >= mySize.height && self.contentMode != UIViewContentModeScaleAspectFit) return self.bounds;
	
	switch (self.contentMode) {
		case UIViewContentModeScaleAspectFit:
			aspect = size.width / size.height;
			myAspect = mySize.width / mySize.height;
			
			if (aspect < myAspect) {				//fill the area vertically. empty space on each side
				newWidth = (mySize.height / size.height) * size.width;
				return CGRectMake((mySize.width - newWidth) / 2, 0, newWidth, mySize.height);
			} else {
				newHeight = (mySize.width / size.width) * size.height;
				return CGRectMake(0, (mySize.height - newHeight) / 2, mySize.width, newHeight);
			}
			break;
		
		case UIViewContentModeScaleToFill:
		case UIViewContentModeScaleAspectFill:
		case UIViewContentModeRedraw: 
		default:
			return self.bounds;
		
		case UIViewContentModeCenter: return CGRectMake((mySize.width - size.width) / 2, (mySize.height - size.height) / 2, size.width, size.height);
			
		case UIViewContentModeTop: return CGRectMake((mySize.width - size.width) / 2, 0, size.width, size.height);
		case UIViewContentModeBottom: return CGRectMake(0, mySize.height - size.height, size.width, size.height);
		case UIViewContentModeLeft: return CGRectMake(0, (mySize.height - size.height) / 2, size.width, size.height);
		case UIViewContentModeRight: return CGRectMake(mySize.width - size.width, (mySize.height - size.height) / 2, size.width, size.height);

		case UIViewContentModeTopLeft: return CGRectMake(0, 0, size.width, size.height);
		case UIViewContentModeTopRight: return CGRectMake((mySize.width - size.width), 0, size.width, size.height);
		case UIViewContentModeBottomLeft: return CGRectMake(0, (mySize.height - size.height), size.width, size.height);
		case UIViewContentModeBottomRight: return CGRectMake(mySize.width - size.width, mySize.height - size.height, size.width, size.height);
			
	}
	return self.bounds;
}

@end
