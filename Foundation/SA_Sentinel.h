//
//  SA_Sentinel.h
//  SABase
//
//  Created by Ben Gottlieb on 4/17/14.
//
//

#import <Foundation/Foundation.h>

@interface SA_Sentinel : NSObject

+ (instancetype) sentinelWithCompletionBlock: (simpleBlock) block;

- (void) increment;
- (void) decrement;


@end
