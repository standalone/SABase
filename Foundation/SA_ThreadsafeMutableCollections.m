//
//  SA_ThreadsafeMutableCollections.m
//
//  Created by Ben Gottlieb on 5/3/14.
//
//

#import "SA_ThreadsafeMutableCollections.h"

@interface SA_ThreadsafeMutableArray ()
@property (nonatomic, strong) NSMutableArray *backingArray;
@end

@implementation SA_ThreadsafeMutableArray

- (id) init {
	if (self = [super init]) {
		self.backingArray = [NSMutableArray new];
	}
	return self;
}

+ (instancetype) arrayWithObject: (id) object {
	SA_ThreadsafeMutableArray			*array = [self array];
	
	[array.backingArray addObject: object];
	return array;
}

+ (instancetype) array { return [self new]; }

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len {
	@synchronized (self) { return [self.backingArray countByEnumeratingWithState: state objects: buffer count: len]; }
}

- (id) objectAtIndexedSubscript: (NSUInteger) idx {
	@synchronized (self) { return self.backingArray[idx]; }
}

- (id) firstObject {
	@synchronized (self) { return self.backingArray.count ? self.backingArray[0] : nil; }
}

- (id) lastObject {
	@synchronized (self) { return self.backingArray.count ? self.backingArray[self.backingArray.count - 1] : nil; }
}



- (void) setObject: (id) object atIndexedSubscript: (NSUInteger) idx {
	@synchronized (self) { self.backingArray[idx] = object; }
}

- (void) addObject: (id) object {
	@synchronized (self) { [self.backingArray addObject: object]; }
}

- (void) removeObject: (id) object {
	@synchronized (self) { [self.backingArray removeObject: object]; }
}

- (BOOL) containsObject: (id) object {
	if (object == nil) return NO;
	@synchronized (self) { return [self.backingArray containsObject: object]; }
}

- (void) removeAllObjects {
	@synchronized (self) { [self.backingArray removeAllObjects]; }
}

- (void) safelyAccessInBlock: (simpleMutableArrayBlock) block {
	@synchronized (self) { block(self.backingArray); }
}

- (NSArray *) allObjects {
	@synchronized (self) { return [self.backingArray copy]; }
}

- (NSUInteger) count {
	@synchronized (self) { return self.backingArray.count; }
}

- (NSString *) description {
	@synchronized (self) { return self.backingArray.description; }
}
@end


@interface SA_ThreadsafeMutableSet ()
@property (nonatomic, strong) NSMutableSet *backingSet;
@end

@implementation SA_ThreadsafeMutableSet

- (id) init {
	if (self = [super init]) {
		self.backingSet = [NSMutableSet new];
	}
	return self;
}

+ (instancetype) set { return [self new]; }

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len {
	@synchronized (self) { return [self.backingSet countByEnumeratingWithState: state objects: buffer count: len]; }
}

- (id) anyObject {
	@synchronized (self) { return self.backingSet.anyObject; }
}

- (void) addObject: (id) object {
	@synchronized (self) { [self.backingSet addObject: object]; }
}


- (void) removeObject: (id) object {
	@synchronized (self) { [self.backingSet removeObject: object]; }
}

- (BOOL) containsObject: (id) object {
	if (object == nil) return NO;
	@synchronized (self) { return [self.backingSet containsObject: object]; }
}

- (void) removeAllObjects {
	@synchronized (self) { [self.backingSet removeAllObjects]; }
}

- (void) safelyAccessInBlock: (simpleMutableSetBlock) block {
	@synchronized (self) { block(self.backingSet); }
}

- (NSArray *) allObjects {
	@synchronized (self) { return [self.backingSet allObjects]; }
}

- (NSUInteger) count {
	@synchronized (self) { return self.backingSet.count; }
}

- (NSString *) description {
	@synchronized (self) { return self.backingSet.description; }
}
@end


@interface SA_ThreadsafeMutableDictionary ()
@property (nonatomic, strong) NSMutableDictionary *backingDictionary;
@end

@implementation SA_ThreadsafeMutableDictionary

- (id) init {
	if (self = [super init]) {
		self.backingDictionary = [NSMutableDictionary new];
	}
	return self;
}

+ (instancetype) dictionary { return [self new]; }

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len {
	@synchronized (self) { return [self.backingDictionary countByEnumeratingWithState: state objects: buffer count: len]; }
}

- (id) objectForKeyedSubscript: (id) key {
	@synchronized (self) { return [self.backingDictionary objectForKeyedSubscript: key]; }
}

- (id) objectForKey: (id) key {
	@synchronized (self) { return [self.backingDictionary objectForKey: key]; }
}

- (void) setObject: (id) object forKeyedSubscript: (id <NSCopying>) key {
	@synchronized (self) { [self.backingDictionary setObject: object forKeyedSubscript: key]; }
}

- (void) setObject: (id) object forKey: (id <NSCopying>) key {
	@synchronized (self) { [self.backingDictionary setObject: object forKey: key]; }
}

- (void) removeObjectForKey: (id) key {
	@synchronized (self) { [self.backingDictionary removeObjectForKey: key]; }
}

- (void) removeAllObjects {
	@synchronized (self) { [self.backingDictionary removeAllObjects]; }
}

- (void) safelyAccessInBlock: (simpleMutableDictionaryBlock) block {
	@synchronized (self) { block(self.backingDictionary); }
}

- (NSArray *) allObjects {
	@synchronized (self) { return [self.backingDictionary allValues]; }
}

- (NSUInteger) count {
	@synchronized (self) { return self.backingDictionary.count; }
}

- (NSString *) description {
	@synchronized (self) { return self.backingDictionary.description; }
}
@end


