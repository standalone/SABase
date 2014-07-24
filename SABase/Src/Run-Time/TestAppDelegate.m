//
//  TestAppDelegate.m
//  SABase
//
//  Created by Ben Gottlieb on 7/24/14.
//
//

#import "TestAppDelegate.h"
#import <objc/runtime.h>
#import "UIDevice+SA_Additions.h"
#import "TestController.h"


@interface TestAppDelegate () <UIApplicationDelegate>

@end

void		RunTestsWithClassNamed(NSString *className);

void		RunTestsWithClassNamed(NSString *className) {
	Class				class = NSClassFromString(className);
	id					object = [[class alloc] init];
	uint				i, numMethods;
	Method				*methods = class_copyMethodList(class, &numMethods);
	
	
	for (i = 0; i < numMethods; i++) {
		SEL			method = method_getName(methods[i]);
		NSString	*methodName = NSStringFromSelector(method);
		
		if (![methodName hasPrefix: @"test"]) continue;
		SUPPRESS_LEAK_WARNING([object performSelector: method]);
	}
	
	LOG(@"%@ passed %d tests", className, numMethods);
}

@implementation TestAppDelegate

- (id) init {
	if (self = [super init]) {
		[UIApplication sharedApplication].delegate = self;
	}
	return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	RunTestsWithClassNamed(@"NSDate_Tests");
	RunTestsWithClassNamed(@"NSURL_Tests");
	
	[[UIScreen mainScreen] currentFrameConsideringInterfaceOrientation];

	self.navigationController = [[UINavigationController alloc] initWithRootViewController: [[TestController alloc] init]];
	[self.window addSubview: self.navigationController.view];
	[self.window makeKeyAndVisible];
	
	return YES;
}

@end
