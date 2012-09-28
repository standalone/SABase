//
//  NSArray+Additions.m
//
//  Created by Ben Gottlieb on 3/8/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import "NSArray+SA_Additions.h"


@implementation NSArray (NSArray_SA_Additions)

- (NSArray *) subarrayWithObjectsSatisfyingPredicate: (NSPredicate *) pred {
	NSMutableArray			*subArray = [NSMutableArray arrayWithCapacity: self.count];
	
	for (id object in self) {
		if ([pred evaluateWithObject: object]) [subArray addObject: object];
	}
	return subArray;
}

- (NSUInteger) indexOfFirstObjectMatchingPredicate: (NSPredicate *) pred {
	NSUInteger					count = [self count], index;
	
	for (index = 0; index < count; index++) {
		if ([pred evaluateWithObject: [self objectAtIndex: index]]) return index;
	}
	
	return NSNotFound;
}

- (id) firstObjectMatchingPredicate: (NSPredicate *) pred {
	NSUInteger				index = [self indexOfFirstObjectMatchingPredicate: pred];
	
	return (index == NSNotFound) ? nil : [self objectAtIndex: index];
}

- (NSArray *) arrayWithIndexesFromSet: (NSIndexSet *) indexeSet {
	if ([indexeSet count] == 0) return [NSArray array];
	
	NSUInteger			first = [indexeSet firstIndex], last = [indexeSet lastIndex];
	NSMutableArray		*results = [NSMutableArray arrayWithObject: [self objectAtIndex: first]];
	
	if (first != last) {
		for (NSInteger index = first + 1; index <= last; index++) {
			if ([indexeSet containsIndex: index]) [results addObject: [self objectAtIndex: index]];
		}
	}
	
	return results;
}

- (NSArray *) arrayWithCollectedResultsOfMethod: (SEL) method {
	NSMutableArray				*result = [NSMutableArray arrayWithCapacity: self.count];
	
	for (id object in self) {
		id				newObject = [object respondsToSelector: method] ? [object performSelector: method] : nil;
		
		if (newObject) [result addObject: newObject];
	}
	
	return result;
}

- (NSArray *) arrayWithCollectedResultsOfBlock: (idArgumentBlockReturningID) block {
	NSMutableArray				*result = [NSMutableArray arrayWithCapacity: self.count];
	
	for (id object in self) {
		id				newObject = block(object);
		
		if (newObject) [result addObject: newObject];
	}
	
	return result;
}

- (NSMutableArray *) deepMutableCopy {
	NSInteger			i, count = [self count];
	id					obj;
	NSMutableArray		*result = [[NSMutableArray alloc] initWithCapacity: [self count]];
	
	for (i = 0; i < count; i++) {
		obj = [self objectAtIndex: i];
		
		if ([obj respondsToSelector: @selector(deepMutableCopy)])
			obj = [obj deepMutableCopy];
		else
		if ([obj respondsToSelector: @selector(mutableCopy)])
			obj = [obj mutableCopy];
		else
		if ([obj respondsToSelector: @selector(copy)] && ![obj isMemberOfClass: [NSString class]])
			obj = [obj copy];
		else
			obj = [obj retain];
			
		[result addObject: obj];
		[obj release];
	}
	
	return result;
}

- (NSArray *) randomizedCopy {
	NSMutableArray					*copy = [[NSMutableArray alloc] initWithCapacity: self.count], *holder = [[self mutableCopy] autorelease];
	
	while (holder.count) {
		id				temp = [holder objectAtIndex: rand() % holder.count];
		
		[copy addObject: temp];
		[holder removeObjectAtIndex: [holder indexOfObject: temp]];
	}
	
	return copy;
}

- (NSArray *) arrayWithReversedObjects {
	return [[self reverseObjectEnumerator] allObjects];
}

- (NSUInteger) countObjectsOfClass: (Class) class {
	int				count = 0;
	
	for (id object in self) {
		if ([object isKindOfClass: class]) count++;
	}
	
	return count;
}

- (id) anyRandomObject {
	if (self.count == 0) return nil;
	
	return [self objectAtIndex: rand() % self.count];
}

- (id) previousObjectRelativeTo: (id) object {
	NSUInteger				index = [self indexOfObject: object];
	
	if (index == NSNotFound || index == 0) return nil;
	return [self objectAtIndex: index - 1];
}

- (id) nextObjectRelativeTo: (id) object {
	NSUInteger				index = [self indexOfObject: object];
	
	if (index == NSNotFound || index == (self.count - 1)) return nil;
	return [self objectAtIndex: index + 1];
}

- (id) firstObject {
	if (self.count) return [self objectAtIndex: 0];
	return nil;
}

- (NSArray *) arrayByRemovingObject: (id) object {
	if (![self containsObject: object]) return self;
	
	NSMutableArray				*copy = [[self mutableCopy] autorelease];
	[copy removeObject: object];
	return copy;
}

- (NSUInteger) hash {
	NSUInteger			value = 0, index = 0;
	
	for (id object in self) {
		index++;
		value += index * [object hash];
	}
	return value;
}


@end
