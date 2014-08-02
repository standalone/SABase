//
//  NSUserDefaults+Additions.m
//
//  Created by Ben Gottlieb on 11/24/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//


static NSUserDefaults *s_groupedUserDefaults = nil;



@implementation NSUserDefaults (SA_Additions)

+ (void) setCurrentDefaultsGroup: (NSString *) group { s_groupedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName: group]; }
+ (NSUserDefaults *) standardGroupDefaults { return s_groupedUserDefaults; }

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
	NSUserDefaults		*def = s_groupedUserDefaults ?: [NSUserDefaults standardUserDefaults];
	
	if (object)
		[def setObject: object forKey: key];
	else
		[def removeObjectForKey: key];
	[def synchronize];
	
}

- (id) objectForKeyedSubscript: (id) key {
	return [self objectForKey: key];
}
- (void) setObject: (id) obj forKeyedSubscript: (id) key {
	[self setObject: obj forKey: key];
}



@end
