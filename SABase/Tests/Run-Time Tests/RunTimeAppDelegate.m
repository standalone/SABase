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
#import "SA_ConnectionQueue.h"
#import "SA_AlertView.h"

@interface TestingAppDelegate () <SA_ConnectionDelegate>
@property (nonatomic, strong) NSMutableArray *queues;
@end

@implementation TestingAppDelegate
@synthesize window, navigationController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [TestController new];

	[self.window makeKeyAndVisible];
	
//	[self stressTestConnections];
	
	
//	[UIWindow alertWindow];
//	[SA_CustomAlert showAlertWithTitle: @"Test Alert" message: @"Alert Message"];
	
}

- (void) stressTestConnections {
	self.queues = [NSMutableArray new];
	for (int i = 0; i < 30; i++) {
		NSOperationQueue				*queue = [NSOperationQueue new];
		
		queue.maxConcurrentOperationCount = 1;
		queue.name = $S(@"%d", i + 1);
		[self.queues addObject: queue];
		
		[queue addOperationWithBlock: ^{
			int			number = 1;
			
			for (int j = 0; j < 100; j++) {
				[[SA_ConnectionQueue sharedQueue] queueConnection: [SA_Connection connectionWithURL: $U(@"http://example.org/%d/%d", i, j) completionBlock: ^(SA_Connection *incoming, NSInteger resultCode, id error) {
					
					[[SA_ConnectionQueue sharedQueue] isExistingConnectionTaggedWith: @"df" delegate: self completion: ^(BOOL value) {
						
					}];
					LOG(@"Finished at #%d on %d", number, i);
				}]];
				number++;
			}
		}];
	}
}
@end
