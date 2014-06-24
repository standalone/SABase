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

//- (NSMutableDictionary *) deepMutableCopy {
//	NSArray				*keys = [self allKeys];
//	NSUInteger			i, count = [keys count];
//	id					obj, key;
//	NSMutableDictionary	*result = [[NSMutableDictionary alloc] initWithCapacity: [self count]];
//	
//	for (i = 0; i < count; i++) {
//		key = [keys objectAtIndex: i];
//		obj = [self objectForKey: key];
//		
//		if ([obj isKindOfClass: [NSNumber class]]) {
//			[result setObject: obj forKey: key];
//			continue;
//		} else if ([obj respondsToSelector: @selector(deepMutableCopy)])
//			obj = [obj deepMutableCopy];
//		else
//		if ([obj respondsToSelector: @selector(mutableCopy)])
//			obj = [obj mutableCopy];
//		else
//		if ([obj respondsToSelector: @selector(copy)] && ![obj isMemberOfClass: [NSString class]])
//			obj = [obj copy];
//		else
//			obj = [obj;
//			
//		key = [key copy];
//		[result setObject: obj forKey: key];
//		[key ;
//		[obj ;
//	}
//	
//	return result;
//}

+ (NSDictionary *) SA_dictionaryWithData: (NSData *) data {
	NSString				*path = [NSString tempFilename];
	if (![data writeToFile: path atomically: YES]) return nil;
	
	NSDictionary			*result = [NSDictionary dictionaryWithContentsOfFile: path];
	NSError					*error = nil;
	
	if (![[NSFileManager defaultManager] removeItemAtPath: path error: &error]) {
		SA_BASE_LOG(@"An error occurred while deleting the temp file (%@): %@", path, error);
	}
	return result;
}

- (NSUInteger) hash { return [self SA_md5Hash]; }

- (NSUInteger) SA_md5Hash {
	NSUInteger			value = 0;
	
	for (id key in self.allKeys.copy) {
		id						val = [self valueForKey: key];
		NSUInteger				valueHash = [val respondsToSelector: @selector(SA_md5Hash)] ? [val SA_md5Hash] : [val hash];
		
		value += [key hash] * valueHash;
	}
	return value;
}

- (NSString *) SA_checksumString {
	NSMutableString				*string = [NSMutableString string];
	
	for (NSString *key in [self.allKeys sortedArrayUsingSelector: @selector(compare:)]) {
		id				value = self[key];
		
		if ([value isKindOfClass: [NSDictionary class]] || [value isKindOfClass: [NSArray class]]) {
			[string appendFormat: @"%@-%@-", key, [value SA_checksumString]];
		} else if ([value isKindOfClass: [NSString class]] || [value isKindOfClass: [NSNumber class]]) {
			[string appendFormat: @"%@-%@-", key, value];
		} else if ([value isKindOfClass: [NSDate class]]) {
			
		} else if ([value isKindOfClass: [NSData class]]) {
			[string appendFormat: @"%@-%@-", key, [value SA_base64Encoded]];
		}
	}
	return string;
}

@end
