//
//  UIBarButtonItem+Additions.h
//
//  Created by Ben Gottlieb on 3/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIBarButtonItem (Additions)

+ (id) itemWithTitle: (NSString *) title target: (id) target action: (SEL) action;
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action;
+ (id) itemWithImage: (UIImage *) image target: (id) target action: (SEL) action;

+ (id) borderlessItemWithTitle: (NSString *) title target: (id) target action: (SEL) action;
+ (id) borderlessItemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action;
+ (id) borderlessItemWithImage: (UIImage *) image target: (id) target action: (SEL) action;

+ (id) itemWithTitle: (NSString *) title block: (idArgumentBlock) block;
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item block: (idArgumentBlock) block;
+ (id) itemWithImage: (UIImage *) image block: (idArgumentBlock) block;


+ (id) flexibleSpacer;
+ (id) spacer;
+ (id) spacerOfWidth: (float) width;

+ (id) itemWithView: (UIView *) view;
+ (id) activityIndicatorItemWithStyle: (UIActivityIndicatorViewStyle) style forToolbar: (BOOL) forToolbar;
@end
