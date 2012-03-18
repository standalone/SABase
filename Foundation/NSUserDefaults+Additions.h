//
//  NSUserDefaults+Additions.h
//
//  Created by Ben Gottlieb on 11/24/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSUserDefaults (Additions)

- (BOOL) isSetting: (NSString *) settingKey upToVersion: (int) properVersion updatingIfNeeded: (BOOL) update;

@end
