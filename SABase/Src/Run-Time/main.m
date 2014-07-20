//
//  main.m
//  ZimmerDemo
//
//  Created by Ben Gottlieb on 8/6/10.
//  Copyright Stand Alone, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

void		RunTestsWithClassNamed(NSString *className);

int main(int argc, char *argv[]) {
    @autoreleasepool {
		RunTestsWithClassNamed(@"NSDate_Tests");
		RunTestsWithClassNamed(@"NSURL_Tests");
		
		[[UIScreen mainScreen] currentFrameConsideringInterfaceOrientation];
		
		UIApplicationMain(argc, argv, nil, nil);
	}
    return 0;
}



void		RunTestsWithClassNamed(NSString *className) {
	Class				class = NSClassFromString(className);
	id					object = [[class alloc] init];
	uint				i, numMethods;
	Method				*methods = class_copyMethodList(class, &numMethods);
	

	for (i = 0; i < numMethods; i++) {
		SEL			method = method_getName(methods[i]);
		NSString	*methodName = NSStringFromSelector(method);
		
		if (![methodName hasPrefix: @"test"]) continue;
		[object performSelector: method];
	}
	
	LOG(@"%@ passed %d tests", className, numMethods);
}