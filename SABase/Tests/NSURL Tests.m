//
//  NSURL Tests.m
//  SABase
//
//  Created by Ben Gottlieb on 6/19/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSURL Tests.h"
#import "NSURL+Additions.h"

@implementation NSURL_Tests

- (void) testNSURLAdditions {
	NSString				*domain = @"test", *name = @"bill", *color = @"blue";
	NSURL					*url = [NSURL URLWithFormat: @"http://%@.com/q?name=%@&color=%@", domain, name, color];
	NSString				*checkString = @"http://test.com/q?name=bill&color=blue";

	[checkString length];
    STAssertTrue([url.absoluteString isEqualToString: checkString], @"-URLWithFormat failed (%@ != %@)", url.absoluteString, checkString);
	
	NSDictionary			*params = [url keyValuedParameters];
	LOG(@"URL Test Params: %@", params);
	
	STAssertTrue([[params objectForKey: @"name"] isEqualToString: @"bill"], @"-keyValuedParameters failed");
	STAssertTrue([[params objectForKey: @"color"] isEqualToString: @"blue"], @"-keyValuedParameters failed");
}


@end
