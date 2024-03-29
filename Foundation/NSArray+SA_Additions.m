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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		id				newObject = [object respondsToSelector: method] ? [object performSelector: method] : nil;
#pragma clang diagnostic pop
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

//- (NSMutableArray *) deepMutableCopy {
//	NSInteger			i, count = [self count];
//	NSMutableArray		*result = [[NSMutableArray alloc] initWithCapacity: [self count]];
//	
//	@autoreleasepool {
//		for (i = 0; i < count; i++) {
//			id					obj, copy = nil;
//			obj = [self objectAtIndex: i];
//			
//			if ([obj isKindOfClass: [NSNumber class]] || ![obj respondsToSelector: @selector(retain)]) {
//				copy = obj;
//			} else if ([obj respondsToSelector: @selector(deepMutableCopy)])
//				copy = [[obj deepMutableCopy] ;
//			else if ([obj respondsToSelector: @selector(mutableCopy)])
//				copy = [[obj mutableCopy] ;
//			else if ([obj respondsToSelector: @selector(copy)] && ![obj isMemberOfClass: [NSString class]])
//				copy = [[obj copy] ;
//			else
//				copy = obj;
//				
//			[result addObject: copy];
//		}
//	}
//	
//	return result;
//}

- (NSArray *) SA_randomizedCopy {
	NSMutableArray					*copy = [self mutableCopy];
	NSUInteger						count = self.count;
	
	for (NSUInteger i = 0; i < count; ++i) {		// Select a random element between i and end of array to swap with.
		NSUInteger nElements = count - i;
		NSUInteger n = (arc4random() % nElements) + i;
		[copy exchangeObjectAtIndex: i withObjectAtIndex: n];
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

- (id) SA_anyRandomObject {
	if (self.count == 0) return nil;
	
	return [self objectAtIndex: rand() % self.count];
}

- (id) SA_previousObjectRelativeTo: (id) object {
	NSUInteger				index = [self indexOfObject: object];
	
	if (index == NSNotFound || index == 0) return nil;
	return [self objectAtIndex: index - 1];
}

- (id) SA_nextObjectRelativeTo: (id) object {
	NSUInteger				index = [self indexOfObject: object];
	
	if (index == NSNotFound || index == (self.count - 1)) return nil;
	return [self objectAtIndex: index + 1];
}

- (id) SA_firstObject {
	if (self.count) return [self objectAtIndex: 0];
	return nil;
}

- (NSArray *) SA_arrayByRemovingObject: (id) object {
	if (![self containsObject: object]) return self;
	
	NSMutableArray				*copy = [self mutableCopy];
	[copy removeObject: object];
	return copy;
}

- (NSUInteger) SA_md5Hash {
	NSUInteger			value = 0, index = 1059;
	
	for (id object in self.copy) {
		index *= 2;
		NSUInteger				valueHash = [object respondsToSelector: @selector(SA_md5Hash)] ? [object SA_md5Hash] : [object hash];
		
		value += index * valueHash;
	}
	return value;
}

- (NSString *) SA_checksumString {
	NSMutableString				*string = [NSMutableString string];
	
	for (id value in self.copy) {
		if ([value isKindOfClass: [NSDictionary class]] || [value isKindOfClass: [NSArray class]]) {
			[string appendFormat: @"%@-", [value SA_checksumString]];
		} else if ([value isKindOfClass: [NSString class]] || [value isKindOfClass: [NSNumber class]]) {
			[string appendFormat: @"%@-", value];
		} else if ([value isKindOfClass: [NSDate class]]) {
			
		} else if ([value isKindOfClass: [NSData class]]) {
			[string appendFormat: @"%@-", [value SA_base64Encoded]];
		}
	}
	return string;
}

- (void) map: (idArgumentBlock) block {
	for (id object in self) {
		block(object);
	}
}

- (NSArray *) collectMappedResults: (idArgumentBlockReturningID) block {
	NSMutableArray	*results = [NSMutableArray array];
	for (id object in self) {
		[results addObject: block(object)];
	}
	return results;
}
@end
