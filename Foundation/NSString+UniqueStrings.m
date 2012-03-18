//
//  NSString+UniqueStrings.m
//  Cuirl
//
//  Created by Ben Gottlieb on 12/18/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import "NSString+UniqueStrings.h"


@implementation NSString (NSString_UniqueStrings)

+ (NSString *) uuid {
	CFUUIDRef					uuid = CFUUIDCreate(NULL);
	NSString					*uuidString = (NSString *) CFUUIDCreateString(NULL, uuid);
	CFRelease(uuid);
	
	return uuidString;
}

+ (NSString *) guid { return [self uuid]; }

+ (NSString *) tempFilename {
	return [NSString tempFilenameWithExtension: nil];
}

+ (NSString *) tempFilenameWithExtension: (NSString *) extension {
	NSString					*path = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString uuid]];
	
	if ([extension length]) path = [path stringByAppendingPathExtension: extension];
	return path;
}


@end
