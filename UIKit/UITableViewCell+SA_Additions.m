//
//  UITableViewCell+Additions.m
//
//  Created by Ben Gottlieb on 2/5/10.
//  Copyright 2010 Stand Alone, Inc.. All rights reserved.
//

#import "UITableViewCell+SA_Additions.h"


@implementation UITableViewCell (UITableViewCell_SA_Additions)
@dynamic tableView, indexPath, dividerImage, dividerView, backgroundViewColor, dividerViewColor;

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
	
	UIEdgeInsets			insets = UIEdgeInsetsMake(0, 0, 0, 0);
	if ([self respondsToSelector: @selector(separatorInset)]) insets = self.separatorInset;
	
	divider = [[UIImageView alloc] initWithFrame: CGRectMake(insets.left, self.bounds.size.height - image.size.height, self.bounds.size.width - (insets.left + insets.right), image.size.height)];
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
	UIEdgeInsets			insets = UIEdgeInsetsMake(0, 0, 0, 0);
	if ([self respondsToSelector: @selector(separatorInset)]) insets = self.separatorInset;
	
	if (divider) return divider;
	
	divider = [[UIView alloc] initWithFrame: CGRectMake(insets.left, self.bounds.size.height - 0.5, self.bounds.size.width - (insets.left + insets.right), 0.5)];
	divider.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	divider.tag = kDividerViewTag;
	[self addSubview: divider];
	return divider;
}

- (void) setDividerViewColor: (UIColor *) color { self.dividerView.backgroundColor = color; }
- (UIColor *) dividerViewColor { return self.dividerView.backgroundColor; }

- (void) setBackgroundViewColor: (UIColor *) color {
	if (self.backgroundView == nil) {
		self.backgroundView = [[UIView alloc] initWithFrame: self.bounds];
		self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	}
	self.backgroundView.backgroundColor = color;
}

- (UIColor *) backgroundViewColor { return self.backgroundView.backgroundColor; }

@end

@implementation UICollectionViewCell (UICollectionViewCell_SA_Additions)
- (UICollectionView *) collectionView {
	UICollectionView		*view = (id) self.superview;
	
	while (![view isKindOfClass: [UICollectionView class]]) {
		view = (id) view.superview;
		if (view == nil) break;
	}
	return view;
}
@end