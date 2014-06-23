//
//  SA_ThreadsafeMutableCollections.h
//
//  Created by Ben Gottlieb on 5/3/14.
//
//

#import <Foundation/Foundation.h>

@interface SA_ThreadsafeMutableArray : NSObject <NSFastEnumeration>
+ (SA_ThreadsafeMutableArray *) array;

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len;
- (id) objectAtIndexedSubscript: (NSUInteger) idx;
- (void) setObject: (id) object atIndexedSubscript: (NSUInteger) idx;
- (void) addObject: (id) object;
- (void) removeObject: (id) object;
- (void) removeAllObjects;
@end



@interface SA_ThreadsafeMutableSet : NSObject <NSFastEnumeration>
+ (SA_ThreadsafeMutableSet *) set;

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len;
- (void) addObject: (id) object;
- (void) removeObject: (id) object;
- (void) removeAllObjects;
@end



@interface SA_ThreadsafeMutableDictionary : NSObject <NSFastEnumeration>
+ (SA_ThreadsafeMutableDictionary *) dictionary;

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len;
- (id) objectForKeyedSubscript: (id) key;
- (id) objectForKey: (id) key;
- (void) setObject: (id) obj forKeyedSubscript: (id <NSCopying>) key;
- (void) setObject: (id) object forKey: (id <NSCopying>) key;
- (void) removeObjectForKey: (id) key;
- (void) removeObjectForKey: (id) key withCompletion: (simpleBlock) completion;
@end

