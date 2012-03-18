//
//  NSUserDefaults+Additions.m
//
//  Created by Ben Gottlieb on 11/24/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSUserDefaults+Additions.h"


@implementation NSUserDefaults (Additions)

- (BOOL) isSetting: (NSString *) settingKey upToVersion: (int) properVersion updatingIfNeeded: (BOOL) update {
	int				currentVersion = [self integerForKey: settingKey];
	
	if (currentVersion >= properVersion) return YES;
	
	if (update) {
		[self setInteger: properVersion forKey: settingKey];
		[self synchronize];
	}
	return NO;
}
@end
