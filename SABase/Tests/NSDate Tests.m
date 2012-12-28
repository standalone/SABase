//
//  NSDate Tests.m
//  SABase
//
//  Created by Ben Gottlieb on 6/19/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSDate Tests.h"
#import "NSDate+SA_Additions.h"

@implementation NSDate_Tests

- (void) testDateParsing {
	NSString			*xmlDateString;
	NSDate				*date;
	
	xmlDateString = @"Fri Dec 28 13:37:42 +0000 2012";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 298682340 , @"-dateWithXMLString (TZ as GMT) failed");
	
	xmlDateString = @"2010-06-19T17:19:00CST";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 298682340 , @"-dateWithXMLString (TZ as GMT) failed");
	
	xmlDateString = @"2010-06-19T23:19:00+00:00";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 298682340.0 , @"-dateWithXMLString (TZ as GMT) failed");
	
	xmlDateString = @"2010-06-19T22:19:00-01:00";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 298682340.0 , @"-dateWithXMLString (no TZ) failed");

	xmlDateString = @"2010-06-19T23:19:00";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 298682340.0 , @"-dateWithXMLString (no TZ) failed");
	
	xmlDateString = @"2010-06-19T23:19:00Z";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 298682340.0 , @"-dateWithXMLString (TZ as Z) failed");

	xmlDateString = @"2010-06-19T23:19:00UTC";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 298682340.0 , @"-dateWithXMLString (TZ as UTC) failed");

	xmlDateString = @"2010-06-19T23:19:00GMT";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 298682340.0 , @"-dateWithXMLString (TZ as GMT) failed");
	
	xmlDateString = @"2010-10-22";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 309398400.0 , @"-dateWithXMLString (TZ as GMT) failed");
	
	xmlDateString = @"2010-06-19 23:19:00 GMT";
	date = [NSDate dateWithXMLString: xmlDateString];
	STAssertTrue([date timeIntervalSinceReferenceDate] == 298682340.0 , @"-dateWithXMLString (TZ as -space-GMT) failed");
	STAssertTrue([[date UTCString] isEqualToString: xmlDateString] , @"-UTCString failed");
}


@end
