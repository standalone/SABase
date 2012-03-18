//
//  NSDictionary+Additions.h
//  WebTools
//
//  Created by Ben Gottlieb on 9/6/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (NSDictionary_Additions)

- (NSMutableDictionary *) deepMutableCopy;
+ (NSDictionary *) dictionaryWithData: (NSData *) date;

@end
