//
//  NSDate Tests.h
//  SABase
//
//  Created by Ben Gottlieb on 6/19/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

//  Application unit tests contain unit test code that must be injected into an application to run correctly.
//  Define USE_APPLICATION_UNIT_TEST to 0 if the unit test code is designed to be linked into an independent test executable.

#ifndef RUN_TIME_TESTS
	#import <SenTestingKit/SenTestingKit.h>
#endif

#import <UIKit/UIKit.h>
//#import "application_headers" as required


@interface NSDate_Tests : SenTestCase {

}
- (void) testDateParsing;

@end
