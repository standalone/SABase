//
//  NSString+MD5.m
//  Stickie Reader
//
//  Created by Ben Gottlieb on 3/25/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSString+MD5.h"

@implementation NSString (MD5)

#if TARGET_OS_IPHONE
#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access


- (NSUInteger) md5HashInteger {
    const char *cStr = [self UTF8String];
    NSUInteger result[4];
    CC_MD5( cStr, strlen(cStr), (unsigned char *) result ); // This is the md5 call
	
	return result[0];
}
- (NSString *) md5Hash
{
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
    return [NSString stringWithFormat:
			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];  
}

//@implementation NSData (MyExtensions)
//- (NSString*)md5
//{
//    unsigned char result[16];
//    CC_MD5( self.bytes, self.length, result ); // This is the md5 call
//    return [NSString stringWithFormat:
//			@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
//			result[0], result[1], result[2], result[3], 
//			result[4], result[5], result[6], result[7],
//			result[8], result[9], result[10], result[11],
//			result[12], result[13], result[14], result[15]
//			];  
//}
//@end

#else
#import "NSTask+Synchronicity.h"
#import "NSString+Additions.h"

- (NSString *) md5Hash {
	NSString					*path = [NSString tempFileNameWithSeed: @"md5" ofType: @"txt"];
	NSError						*error;
	
	if (![self writeToFile: path atomically: YES encoding: NSUTF8StringEncoding error: &error]) {
		NSLog(@"Error while hashing string: %@", error);
		return nil;
	}
	NSString					*md5 = [NSTask runTaskWithLaunchPath: @"/sbin/md5" arguments: [NSArray arrayWithObjects: @"-r", path, nil]];
	
	@try {
		md5 = [[md5 componentsSeparatedByString: @" "] objectAtIndex: 0];
	} @catch (NSException * e) {}
	
	return md5;	
}

- (NSUInteger) md5HashInteger {
	return self.md5Hash.hash;		//FIX THIS
}
#endif
@end
