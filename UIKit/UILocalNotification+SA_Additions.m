//
//  UILocalNotification+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 10/27/13.
//
//

#import "UILocalNotification+SA_Additions.h"

@implementation UILocalNotification (SA_Additions)

+ (void) presentNotificationText: (NSString *) text withAction: (NSString *) action sound: (NSString *) soundName atDate: (NSDate *) date {
	UILocalNotification				*note = [[UILocalNotification alloc] init];
	
	note.fireDate = date ?: [NSDate dateWithTimeIntervalSinceNow: 1.0];
	note.alertBody = text;
	note.hasAction = action.length > 0;
	note.alertAction = action;
	note.soundName = soundName;
	[[UIApplication sharedApplication] scheduleLocalNotification: note];
}

@end
