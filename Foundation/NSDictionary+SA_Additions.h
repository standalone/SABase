//
//  NSDictionary+SA_Additions.h
//  WebTools
//
//  Created by Ben Gottlieb on 9/6/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (NSDictionary_SA_Additions)
@property (nonatomic, readonly) NSUInteger md5Hash;
@property (nonatomic, readonly) NSString *checksumString;

//- (NSMutableDictionary *) deepMutableCopy;
+ (NSDictionary *) dictionaryWithData: (NSData *) data;
@end
