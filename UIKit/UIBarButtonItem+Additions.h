//
//  UIBarButtonItem+Additions.h
//
//  Created by Ben Gottlieb on 3/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^barButtonItemArgumentBlock)(id arg);


@interface UIBarButtonItem (Additions)

+ (id) itemWithTitle: (NSString *) title target: (id) target action: (SEL) action;
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action;
+ (id) itemWithImage: (UIImage *) image target: (id) target action: (SEL) action;

+ (id) borderlessItemWithTitle: (NSString *) title target: (id) target action: (SEL) action;
+ (id) borderlessItemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action;
+ (id) borderlessItemWithImage: (UIImage *) image target: (id) target action: (SEL) action;

+ (id) itemWithTitle: (NSString *) title block: (barButtonItemArgumentBlock) block;
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item block: (barButtonItemArgumentBlock) block;
+ (id) itemWithImage: (UIImage *) image block: (barButtonItemArgumentBlock) block;

+ (id) doneItemWithTitle: (NSString *) title target: (id) target action: (SEL) action;
+ (id) doneItemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action;
+ (id) doneItemWithImage: (UIImage *) image target: (id) target action: (SEL) action;

+ (id) doneItemWithTitle: (NSString *) title block: (barButtonItemArgumentBlock) block;
+ (id) doneItemWithSystemItem: (UIBarButtonSystemItem) item block: (barButtonItemArgumentBlock) block;
+ (id) doneItemWithImage: (UIImage *) image block: (barButtonItemArgumentBlock) block;

+ (id) itemWithTitle: (NSString *) title target: (id) target action: (SEL) action block: (barButtonItemArgumentBlock) block style: (UIBarButtonItemStyle) style;
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action block: (barButtonItemArgumentBlock) block style: (UIBarButtonItemStyle) style;
+ (id) itemWithImage: (UIImage *) image target: (id) target action: (SEL) action block: (barButtonItemArgumentBlock) block style: (UIBarButtonItemStyle) style;

+ (id) flexibleSpacer;
+ (id) spacer;
+ (id) spacerOfWidth: (float) width;

+ (id) itemWithView: (UIView *) view;
+ (id) activityIndicatorItemWithStyle: (UIActivityIndicatorViewStyle) style forToolbar: (BOOL) forToolbar;
@end
