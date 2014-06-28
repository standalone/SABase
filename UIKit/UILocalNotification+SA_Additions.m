//
//  UILocalNotification+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 10/27/13.
//
//

#import "UILocalNotification+SA_Additions.h"

@implementation UILocalNotification (SA_Additions)

+ (void) presentNotificationText: (NSString *) text withAction: (NSString *) action sound: (NSString *) soundName atDate: (NSDate *) date andUserInfo: (NSDictionary *) userInfo {
	UILocalNotification				*note = [[UILocalNotification alloc] init];
	
	note.fireDate = date ?: [NSDate date];
	note.alertBody = text;
	note.hasAction = action.length > 0;
	note.alertAction = action;
	note.soundName = soundName;
	note.userInfo = userInfo;
	[[UIApplication sharedApplication] scheduleLocalNotification: note];
}

@end
