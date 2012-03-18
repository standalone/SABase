//
//  NSSortDescriptor+Additions.m
//
//  Created by Ben Gottlieb on 1/28/10.
//  Copyright 2010 Stand Alone, Inc.. All rights reserved.
//

#import "NSSortDescriptor+Additions.h"


@implementation NSSortDescriptor (ConvenienceAdditions)

+ (NSSortDescriptor *) descriptorWithKey: (NSString *) key ascending: (BOOL) ascending {
	return [[[NSSortDescriptor alloc] initWithKey: key ascending: ascending] autorelease];
}

+ (NSSortDescriptor *) descriptorWithKey: (NSString *) key ascending: (BOOL) ascending selector: (SEL) selector {
	return [[[NSSortDescriptor alloc] initWithKey: key ascending: ascending selector: selector] autorelease];
}

+ (NSArray *) arrayWithDescriptorWithKey: (NSString *) key ascending: (BOOL) ascending {
	return [NSArray arrayWithObject: [self descriptorWithKey: key ascending: ascending]];
}

@end
