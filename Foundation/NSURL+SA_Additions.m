//
//  NSURL+Additions.m
//
//  Created by Ben Gottlieb on 12/26/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import "NSURL+SA_Additions.h"


@implementation NSURL (NSURL_SA_Additions)

- (NSDictionary *) keyValuedParameters {
	NSString					*parameterString = [self query];
	NSArray						*keyValuePairs = [parameterString componentsSeparatedByString: @"&"];
	NSMutableDictionary			*results = [NSMutableDictionary dictionary];
	
	for (NSString *keyValuePair in keyValuePairs) {
		NSArray				*pair = [keyValuePair componentsSeparatedByString: @"="];
		
		if (pair.count == 2) {
			[results setValue: [pair objectAtIndex: 1] forKey: [pair objectAtIndex: 0]];
		}
	}
	
	return results;
}

+ (NSURL *) URLWithFormat: (NSString *) format, ... {
	va_list					list;
	
	va_start(list, format);
	NSString				*fullString = [[NSString alloc] initWithFormat: format arguments: list];
	va_end(list);
	
	NSURL					*url = [self URLWithString: fullString];

	return url;
}
@end
