//
//  NSString+MD5.h
//  Stickie Reader
//
//  Created by Ben Gottlieb on 3/25/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (MD5)

- (NSUInteger) MD5Integer;
- (NSString *) MD5;
@end
