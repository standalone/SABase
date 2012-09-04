//
//  NSDictionary+Additions.m
//  WebTools
//
//  Created by Ben Gottlieb on 9/6/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import "NSDictionary+SA_Additions.h"
#import "NSString+UniqueStrings.h"

@implementation NSDictionary (NSDictionary_SA_Additions)

- (NSMutableDictionary *) deepMutableCopy {
	NSArray				*keys = [self allKeys];
	NSUInteger			i, count = [keys count];
	id					obj, key;
	NSMutableDictionary	*result = [[NSMutableDictionary alloc] initWithCapacity: [self count]];
	
	for (i = 0; i < count; i++) {
		key = [keys objectAtIndex: i];
		obj = [self objectForKey: key];
		
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
			
		key = [key copy];
		[result setObject: obj forKey: key];
		[key release];
		[obj release];
	}
	
	return result;
}

+ (NSDictionary *) dictionaryWithData: (NSData *) data {
	NSString				*path = [NSString tempFilename];
	if (![data writeToFile: path atomically: YES]) return nil;
	
	NSDictionary			*result = [NSDictionary dictionaryWithContentsOfFile: path];
	NSError					*error = nil;
	
	if (![[NSFileManager defaultManager] removeItemAtPath: path error: &error]) {
		LOG(@"An error occurred while deleting the temp file (%@): %@", path, error);
	}
	return result;
}

- (NSUInteger) hash {
	NSUInteger			value = 0;
	
	for (id key in self) {
		value += [key hash] * [[self valueForKey: key] hash];
	}
	return value;
}
@end
