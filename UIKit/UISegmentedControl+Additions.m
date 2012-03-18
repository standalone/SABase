//
//  UISegmentedControl+Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 2/4/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "UISegmentedControl+Additions.h"
#import "NSObject+Additions.h"

@implementation UISegmentedControl (Additions)
- (NSMutableDictionary *) tags {
	NSString					*key = @"sa_tags";
	NSMutableDictionary			*tags = [self associatedValueForKey: key];
	
	if (tags) return tags;
	tags = [NSMutableDictionary dictionary];
	[self associateValue: tags forKey: key];
	return tags;
}

- (void) insertSegmentWithImage: (UIImage *) image atIndex: (NSUInteger) segment animated: (BOOL) animated tag: (NSUInteger) tag {
	[self.tags setObject: $I(tag) forKey: $S(@"%d", segment)];
	[self insertSegmentWithImage: image atIndex: segment animated: animated];
}

- (void) insertSegmentWithTitle: (NSString *) title atIndex: (NSUInteger) segment animated: (BOOL) animated tag: (NSUInteger) tag {
	[self.tags setObject: $I(tag) forKey: $S(@"%d", segment)];
	[self insertSegmentWithTitle: title atIndex: segment animated: animated];
}

- (NSUInteger) tagForSegment: (int) index {
	return [[self.tags objectForKey: $S(@"%d", index)] intValue]; 
}

- (NSUInteger) selectedSegmentTag {
	return [self tagForSegment: self.selectedSegmentIndex];
}

- (void) setSelectedSegmentTag: (NSUInteger) selectedSegmentTag {
	for (NSString *key in self.tags) {
		if ([[self.tags objectForKey: key] intValue] == selectedSegmentTag) {
			self.selectedSegmentIndex = [key intValue];
			return;
		}
	}
}

@end
