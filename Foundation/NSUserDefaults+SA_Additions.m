//
//  NSUserDefaults+Additions.m
//
//  Created by Ben Gottlieb on 11/24/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//


static NSUserDefaults *s_groupedUserDefaults = nil;
static NSString *s_currentDefaultsGroup = nil;



@implementation NSUserDefaults (SA_Additions)

+ (void) setCurrentDefaultsGroup: (NSString *) group {
	if (group != nil && [s_currentDefaultsGroup isEqual: group]) return;
	if (group == nil && s_currentDefaultsGroup == nil) return;
	
	s_currentDefaultsGroup = group;
	s_groupedUserDefaults = [[NSUserDefaults alloc] initWithSuiteName: group];
}

+ (NSUserDefaults *) standardGroupDefaults { return s_groupedUserDefaults; }
+ (NSString *) currentDefaultsGroup { return s_currentDefaultsGroup; }

- (BOOL) isSetting: (NSString *) settingKey upToVersion: (int) properVersion updatingIfNeeded: (BOOL) update {
	NSUInteger				currentVersion = [self integerForKey: settingKey];
	
	if (currentVersion >= properVersion) return YES;
	
	if (update) {
		[self setInteger: properVersion forKey: settingKey];
		[self synchronize];
	}
	return NO;
}

+ (NSUserDefaults *) currentDefaults {
	return s_groupedUserDefaults ?: [NSUserDefaults standardUserDefaults];
}

+ (id) objectForKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	return [def objectForKey: key];
}

+ (id) stringForKey: (NSString *) key {
	NSString		*string = [self objectForKey: key];
	
	if ([string isKindOfClass: [NSString class]]) {
		return string;
	}
	return nil;
}


+ (BOOL) boolForKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	return [def boolForKey: key];
}

+ (float) floatForKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	return [def floatForKey: key];
}

+ (double) doubleForKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	return [def doubleForKey: key];
}

+ (NSInteger) integerForKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	return [def integerForKey: key];
}


+ (void) syncBool: (BOOL) b forKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	[def setBool: b forKey: key];
	[def synchronize];
}

+ (void) syncInteger: (NSInteger) i forKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	[def setInteger: i forKey: key];
	[def synchronize];
}

+ (void) syncFloat: (float) f forKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	[def setFloat: f forKey: key];
	[def synchronize];
}

+ (void) syncDouble: (double) d forKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	[def setDouble: d forKey: key];
	[def synchronize];
}

+ (void) syncObject: (id) object forKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	if (object)
		[def setObject: object forKey: key];
	else
		[def removeObjectForKey: key];
	[def synchronize];
	
}

+ (void) removeObjectForKey: (NSString *) key {
	NSUserDefaults		*def = [self currentDefaults];
	
	return [def removeObjectForKey: key];
}

- (id) objectForKeyedSubscript: (id) key {
	return [self objectForKey: key];
}
- (void) setObject: (id) obj forKeyedSubscript: (id) key {
	[self setObject: obj forKey: key];
}



@end
