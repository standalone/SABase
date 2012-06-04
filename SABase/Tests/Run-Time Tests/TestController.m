    //
//  TestController.m
//  SABase
//
//  Created by Ben Gottlieb on 9/14/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "TestController.h"
#import "NSDate+Additions.h"
#import "SA_Base.h"

@implementation TestController

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

- (void) viewDidAppear: (BOOL) animated {
	NSDate			*date = [NSDate dateWithXMLString: @"2012-05-15"];
	LOG(@"Date: %@", date);
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		NSDate			*date2 = [NSDate dateWithXMLString: @"2012-05-15"];
		LOG(@"Date2: %@", date2);

	});
																			 
	[super viewDidAppear: animated];
	[SA_PleaseWaitDisplay showPleaseWaitDisplayWithMajorText: @"Please" 
												   minorText: @"Minor Text Label" cancelLabel: @"Cancel Button" showProgressBar: NO delegate: nil];

	[self performSelector: @selector(showPleaseWait1) withObject: nil afterDelay: 2.5];
//	[self performSelector: @selector(showPleaseWait2) withObject: nil afterDelay: 5];
	
	if (self.view.bounds.origin.x < -1000) dispatch_async(dispatch_get_main_queue(), ^{});
//	[[SA_ConnectionQueue sharedQueue] queueConnection: [SA_Connection connectionWithURL: [NSURL URLWithString: @"http://www.standalone.com"] tag: nil delegate: nil]];
}

- (void) showPleaseWait1 {
	[SA_PleaseWaitDisplay pleaseWaitDisplay].majorText = @"Please a little";
}

- (void) showPleaseWait2 {
	[SA_PleaseWaitDisplay pleaseWaitDisplay].progressValue = 0.5;
	[[SA_PleaseWaitDisplay pleaseWaitDisplay] performSelector: @selector(setProgressValueAsNumber:) withObject: [NSNumber numberWithFloat: 0.9] afterDelay: 0.5];
	//	[
}


@end
