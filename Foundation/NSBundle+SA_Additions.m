//
//  NSBundle+Additions.m
//
//  Created by Ben Gottlieb on 7/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSBundle+SA_Additions.h"


@implementation NSBundle (SAAdditions)

+ (NSDictionary *) info {
	return [[self mainBundle] infoDictionary];
}

+ (id) infoDictionaryObjectForKey: (NSString *) key {
	return self.info[key];
}

+ (NSString *) version {
	return [self infoDictionaryObjectForKey: @"CFBundleVersion"];
}

+ (NSString *) identifier {
	return [self infoDictionaryObjectForKey: @"CFBundleIdentifier"];
}

+ (NSString *) visibleName {
	return [self infoDictionaryObjectForKey: @"CFBundleDisplayName"];
}


@end
