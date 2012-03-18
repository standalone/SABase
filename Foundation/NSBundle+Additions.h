//
//  NSBundle+Additions.h
//
//  Created by Ben Gottlieb on 7/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSBundle (SAAdditions)

+ (id) infoDictionaryObjectForKey: (NSString *) key;
+ (NSString *) version;
+ (NSString *) identifier;
+ (NSString *) visibleName;
@end
