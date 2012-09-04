//
//  UIActionSheet+SA_Additions.h
//
//  Created by Ben Gottlieb on 11/25/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UIActionSheet (SA_AdditionsForButtons)

- (void) addButtonWithTitle: (NSString *) title andTag: (int) tag;
- (int) tagForButtonAtIndex: (NSUInteger) index;
- (void) clearButtonTags;
#if NS_BLOCKS_AVAILABLE
	- (void) showFromView: (UIView *) view withButtonSelectedBlock: (intArgumentBlock) block;
	- (void) showFromBarButtonItem: (UIBarButtonItem *) item withButtonSelectedBlock: (intArgumentBlock) block;
#endif

- (void) showFromView: (UIView *) view;
@end
