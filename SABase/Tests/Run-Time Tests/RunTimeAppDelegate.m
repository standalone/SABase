//
//  RunTimeAppDelegate.m
//  SABase
//
//  Created by Ben Gottlieb on 9/14/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "RunTimeAppDelegate.h"
#import "TestController.h"


@implementation RunTimeAppDelegate
@synthesize window, navigationController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	self.navigationController = [[[UINavigationController alloc] initWithRootViewController: [[[TestController alloc] init] autorelease]] autorelease];
	[self.window addSubview: self.navigationController.view];
	[self.window makeKeyAndVisible];
}
@end
