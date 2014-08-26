//
//  NSBundle+Additions.m
//
//  Created by Ben Gottlieb on 7/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//




@implementation NSBundle (SAAdditions)

+ (NSDictionary *) info {
	return [[self mainBundle] infoDictionary];
}

+ (id) infoDictionaryObjectForKey: (NSString *) key {
	return self.info[key];
}

+ (NSString *) version {
	NSString			*version = [self infoDictionaryObjectForKey: @"CFBundleShortVersionString"];
	NSString			*build = [self infoDictionaryObjectForKey: @"CFBundleVersion"];
	
	if ([version isEqual: build]) return version;
	if (version.length == 0) return build;
	if (build.length == 0) return version;
	
	return [NSString stringWithFormat: @"%@ (%@)", version, build];
}

+ (NSString *) identifier {
	return [self infoDictionaryObjectForKey: @"CFBundleIdentifier"];
}

+ (NSString *) visibleName {
	return [self infoDictionaryObjectForKey: @"CFBundleDisplayName"];
}

- (NSBundle *) bundleNamed: (NSString *) bundleName {
	NSString				*path = [self pathForResource: bundleName ofType: @"bundle"];
	
	if (path == nil) return nil;
	
	return [NSBundle bundleWithPath: path];
}


@end
