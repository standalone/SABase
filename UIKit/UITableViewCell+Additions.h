//
//  UITableViewCell+Additions.h
//
//  Created by Ben Gottlieb on 2/5/10.
//  Copyright 2010 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kDividerViewTag				33058

@interface UITableViewCell (UITableViewCell_Additions) 
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) NSIndexPath *indexPath;

@property (nonatomic, readonly) UIView *dividerView;
@property (nonatomic, retain) UIColor *backgroundViewColor, *dividerViewColor;
@end
