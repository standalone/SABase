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

- (instancetype) init {
	if (self = [super init]) {
		self.backingArray = [NSMutableArray new];
	}
	return self;
}

+ (SA_ThreadsafeMutableArray *) array { return [self new]; }

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id __unsafe_unretained []) buffer count: (NSUInteger) len {
	@synchronized (self) { return [self.backingArray countByEnumeratingWithState: state objects: buffer count: len]; }
}

- (id) objectAtIndexedSubscript: (NSUInteger) idx {
	@synchronized (self) { return self.backingArray[idx]; }
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


@end


@interface SA_ThreadsafeMutableSet ()
@property (nonatomic, strong) NSMutableSet *backingSet;
@end

@implementation SA_ThreadsafeMutableSet

- (instancetype) init {
	if (self = [super init]) {
		self.backingSet = [NSMutableSet new];
	}
	return self;
}

+ (SA_ThreadsafeMutableSet *) set { return [self new]; }

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

@end


@interface SA_ThreadsafeMutableDictionary ()
@property (nonatomic, strong) NSMutableDictionary *backingDictionary;
@end

@implementation SA_ThreadsafeMutableDictionary

- (instancetype) init {
	if (self = [super init]) {
		self.backingDictionary = [NSMutableDictionary new];
	}
	return self;
}

+ (SA_ThreadsafeMutableDictionary *) dictionary { return [self new]; }

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


@end


