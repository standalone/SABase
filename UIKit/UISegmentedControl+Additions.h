//
//  UISegmentedControl+Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 2/4/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UISegmentedControl (Additions)
- (void) insertSegmentWithImage: (UIImage *) image atIndex: (NSUInteger) segment animated: (BOOL) animated tag: (NSUInteger) tag;
- (void) insertSegmentWithTitle: (NSString *) title atIndex: (NSUInteger) segment animated: (BOOL) animated tag: (NSUInteger) tag;

- (NSUInteger) tagForSegment: (int) index;
@property (nonatomic) NSUInteger selectedSegmentTag;
@end
