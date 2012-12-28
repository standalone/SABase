//
//  RunTimeAppDelegate.h
//  SABase
//
//  Created by Ben Gottlieb on 9/14/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RunTimeAppDelegate : NSObject {
	
}

@property (nonatomic, readwrite, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, readwrite, retain) IBOutlet UIWindow *window;


@end
