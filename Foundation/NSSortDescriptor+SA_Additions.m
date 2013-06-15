//
//  NSSortDescriptor+Additions.m
//
//  Created by Ben Gottlieb on 1/28/10.
//  Copyright 2010 Stand Alone, Inc.. All rights reserved.
//

#import "NSSortDescriptor+SA_Additions.h"


@implementation NSSortDescriptor (ConvenienceAdditions)

+ (NSSortDescriptor *) SA_descWithKey: (NSString *) key ascending: (BOOL) ascending {
	return [[[NSSortDescriptor alloc] initWithKey: key ascending: ascending] autorelease];
}

+ (NSSortDescriptor *) SA_descWithKey: (NSString *) key ascending: (BOOL) ascending selector: (SEL) selector {
	return [[[NSSortDescriptor alloc] initWithKey: key ascending: ascending selector: selector] autorelease];
}

+ (NSArray *) SA_arrayWithDescWithKey: (NSString *) key ascending: (BOOL) ascending {
	return [NSArray arrayWithObject: [self SA_descWithKey: key ascending: ascending]];
}

@end
