//
//  NSBundle+Additions.m
//
//  Created by Ben Gottlieb on 7/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSBundle+SA_Additions.h"


@implementation NSBundle (SAAdditions)

+ (id) infoDictionaryObjectForKey: (NSString *) key {
	return [[[self mainBundle] infoDictionary] objectForKey: key];
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
