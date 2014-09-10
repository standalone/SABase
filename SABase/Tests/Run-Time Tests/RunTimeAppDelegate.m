//
//  RunTimeAppDelegate.m
//  SABase
//
//  Created by Ben Gottlieb on 9/14/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "RunTimeAppDelegate.h"
#import "TestController.h"
#import "SA_CustomAlert.h"


@implementation TestingAppDelegate
@synthesize window, navigationController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [TestController new];

	[self.window makeKeyAndVisible];
	
//	[UIWindow alertWindow];
//	[SA_CustomAlert showAlertWithTitle: @"Test Alert" message: @"Alert Message"];
	
}
@end
