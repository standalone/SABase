//
//  NSSet+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 9/28/12.
//
//

#import "NSSet+SA_Additions.h"

@implementation NSSet (SA_Additions)
- (NSUInteger) hash { return [self md5Hash]; }

- (NSUInteger) md5Hash {
	NSUInteger			value = 0;
	
	for (id object in self) {
		NSUInteger				valueHash = [object respondsToSelector: @selector(md5Hash)] ? [object md5Hash] : [object hash];
		
		value += valueHash;
	}
	return value;
}


@end
