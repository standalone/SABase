//
//  UITableViewCell+Additions.m
//
//  Created by Ben Gottlieb on 2/5/10.
//  Copyright 2010 Stand Alone, Inc.. All rights reserved.
//

#import "UITableViewCell+Additions.h"


@implementation UITableViewCell (UITableViewCell_Additions)

- (UITableView *) tableView {
	UIView				*superview = [self superview];
	
	while (superview && ![superview isKindOfClass: [UITableView class]]) {
		superview = [superview superview];
	}
	
	return (id) superview;
}

- (NSIndexPath *) indexPath {
	return [self.tableView indexPathForCell: self];
}

- (void) setDividerImage: (UIImage *) image {
	UIImageView					*divider = (id) [self viewWithTag: kDividerViewTag];
	
	if (divider) [divider removeFromSuperview];
	
	
	divider = [[[UIImageView alloc] initWithFrame: CGRectMake(0, self.bounds.size.height - image.size.height, self.bounds.size.width, image.size.height)] autorelease];
	divider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	divider.tag = kDividerViewTag;
	divider.image = image;
	[self addSubview: divider];
}
- (UIImage *) dividerImage {
	UIImageView					*divider = (id) [self viewWithTag: kDividerViewTag];
	
	if ([divider isKindOfClass: [UIImageView class]]) return divider.image;
	return nil;
}

- (UIView *) dividerView {
	UIView					*divider = [self viewWithTag: kDividerViewTag];
	
	if (divider) return divider;
	
	divider = [[[UIView alloc] initWithFrame: CGRectMake(0, self.bounds.size.height - 1, self.bounds.size.width, 1)] autorelease];
	divider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	divider.tag = kDividerViewTag;
	[self addSubview: divider];
	return divider;
}

- (void) setDividerViewColor: (UIColor *) color { self.dividerView.backgroundColor = color; }
- (UIColor *) dividerViewColor { return self.dividerView.backgroundColor; }

- (void) setBackgroundViewColor: (UIColor *) color {
	if (self.backgroundView == nil) {
		self.backgroundView = [[[UIView alloc] initWithFrame: self.bounds] autorelease];
		self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	self.backgroundView.backgroundColor = color;
}

- (UIColor *) backgroundViewColor { return self.backgroundView.backgroundColor; }

@end
