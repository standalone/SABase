//
//  UISegmentedControl+Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 2/4/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "UISegmentedControl+SA_Additions.h"
#import "NSObject+SA_Additions.h"

@implementation UISegmentedControl (SA_SA_Additions)
- (NSMutableDictionary *) tags {
	NSString					*key = @"sa_tags";
	NSMutableDictionary			*tags = [self associatedValueForKey: key];
	
	if (tags) return tags;
	tags = [NSMutableDictionary dictionary];
	[self associateValue: tags forKey: key];
	return tags;
}

- (void) insertSegmentWithImage: (UIImage *) image atIndex: (NSUInteger) segment animated: (BOOL) animated tag: (SInt16) tag {
	[self.tags setObject: @(tag) forKey: $S(@"%d", (SInt16) segment)];
	[self insertSegmentWithImage: image atIndex: segment animated: animated];
}

- (void) insertSegmentWithTitle: (NSString *) title atIndex: (NSUInteger) segment animated: (BOOL) animated tag: (SInt16) tag {
	[self.tags setObject: @(tag) forKey: $S(@"%d", (SInt16) segment)];
	[self insertSegmentWithTitle: title atIndex: segment animated: animated];
}

- (SInt16) tagForSegment: (NSUInteger) index {
	return [[self.tags objectForKey: $S(@"%d", (UInt16) index)] intValue];
}

- (SInt16) selectedSegmentTag {
	return [self tagForSegment: self.selectedSegmentIndex];
}

- (void) setSelectedSegmentTag: (SInt16) selectedSegmentTag {
	for (NSString *key in self.tags) {
		if ([[self.tags objectForKey: key] intValue] == selectedSegmentTag) {
			self.selectedSegmentIndex = [key intValue];
			return;
		}
	}
}

@end
