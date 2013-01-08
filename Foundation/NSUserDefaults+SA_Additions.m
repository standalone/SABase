//
//  NSUserDefaults+Additions.m
//
//  Created by Ben Gottlieb on 11/24/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSUserDefaults+SA_Additions.h"


@implementation NSUserDefaults (SA_Additions)

- (BOOL) isSetting: (NSString *) settingKey upToVersion: (int) properVersion updatingIfNeeded: (BOOL) update {
	NSUInteger				currentVersion = [self integerForKey: settingKey];
	
	if (currentVersion >= properVersion) return YES;
	
	if (update) {
		[self setInteger: properVersion forKey: settingKey];
		[self synchronize];
	}
	return NO;
}

+ (void) syncObject: (id) object forKey: (NSString *) key {
	NSUserDefaults		*def = [NSUserDefaults standardUserDefaults];
	
	[def setObject: object forKey: key];
	[def synchronize];
	
}

- (id) objectForKeyedSubscript: (id) key {
	return [self objectForKey: key];
}
- (void) setObject: (id) obj forKeyedSubscript: (id) key {
	[self setObject: obj forKey: key];
}

@end
