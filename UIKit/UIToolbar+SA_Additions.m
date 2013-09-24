//
//  UIToolbar+Additions.m
//
//  Created by Ben Gottlieb on 5/22/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "UIToolbar+SA_Additions.h"


@implementation UIToolbar (SA_SA_Additions)

- (UIBarButtonItem *) replaceItem: (UIBarButtonItem *) item withNewItem: (UIBarButtonItem *) newItem {
	NSMutableArray				*items = [[self.items mutableCopy] autorelease];
	NSInteger					index = [items indexOfObject: item];
	
	SA_AssertAndReturnNil(index != NSNotFound, @"Tried to replace an item in a toolbar to which it did not below");
	
	[items replaceObjectAtIndex: index withObject: newItem];
	self.items = items;
	return newItem;
}
@end
