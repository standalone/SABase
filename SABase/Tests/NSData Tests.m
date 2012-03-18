//
//  NSData Tests.m
//  SABase
//
//  Created by Ben Gottlieb on 6/19/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSData Tests.h"
#import "NSData+Additions.h"

@implementation NSData_Tests

- (void) testNSDataAdditions {
    NSString				*rawString = @"Here is a sample string";
	NSString				*encoded = @"SGVyZSBpcyBhIHNhbXBsZSBzdHJpbmc=";
	NSData					*rawData = [NSData dataWithString: rawString];
	NSString				*encodedString = [rawData base64Encoded];
	
	STAssertTrue([encoded isEqualToString: encodedString], @"Base64 Encoding failed");
    
}


@end
