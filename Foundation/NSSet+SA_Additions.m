//
//  NSSet+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 9/28/12.
//
//

#import "NSSet+SA_Additions.h"

@implementation NSSet (SA_Additions)

- (NSUInteger) SA_md5Hash {
	NSUInteger			value = 0;
	
	for (id object in self) {
		NSUInteger				valueHash = [object respondsToSelector: @selector(SA_md5Hash)] ? [object SA_md5Hash] : [object hash];
		
		value += valueHash;
	}
	return value;
}

- (NSSet *) sa_setByRemovingObject: (id) object {
	if (![self containsObject: object]) return self;
	
	NSMutableSet				*copy = [self mutableCopy];
	[copy removeObject: object];
	return copy;
}

@end
