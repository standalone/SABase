//
//  NSSet+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 9/28/12.
//
//

#import "NSSet+SA_Additions.h"

@implementation NSSet (SA_Additions)
- (NSUInteger) hash {
	NSUInteger			value = 0;
	
	for (id object in self) {
		value += [object hash];
	}
	return value;
}


@end
