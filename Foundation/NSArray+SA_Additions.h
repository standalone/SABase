//
//  NSArray+SA_Additions.h
//
//  Created by Ben Gottlieb on 3/8/07.
//  Copyright 2007 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+SA_Additions.h"

@class NSPredicate;

@interface NSArray (NSArray_SA_Additions)
@property (nonatomic, readonly) NSUInteger md5Hash;

- (NSArray *) subarrayWithObjectsSatisfyingPredicate: (NSPredicate *) pred;
- (NSUInteger) indexOfFirstObjectMatchingPredicate: (NSPredicate *) pred;
- (id) firstObjectMatchingPredicate: (NSPredicate *) pred;

- (NSArray *) arrayWithIndexesFromSet: (NSIndexSet *) indexeSet;
- (NSMutableArray *) deepMutableCopy;
- (NSArray *) randomizedCopy;
- (NSArray *) arrayWithCollectedResultsOfMethod: (SEL) method;
- (NSArray *) arrayWithCollectedResultsOfBlock: (idArgumentBlockReturningID) block;
- (NSUInteger) countObjectsOfClass: (Class) classToCount;
- (NSArray *) arrayWithReversedObjects;
- (id) anyRandomObject;
- (id) previousObjectRelativeTo: (id) object;
- (id) nextObjectRelativeTo: (id) object;
- (id) firstObject;
- (NSArray *) arrayByRemovingObject: (id) object;
@end
