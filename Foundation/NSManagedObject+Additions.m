//
//  NSManagedObject+Additions.m
//
//  Created by Ben Gottlieb on 5/25/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "NSManagedObject+Additions.h"
#import "NSManagedObjectContext+Additions.h"
#import "NSObject+Additions.h"

@implementation NSManagedObject (NSManagedObject_Additions)


- (id) objectWithIDString: (NSString *) string {
	return [self.managedObjectContext objectWithIDString: string];
}

- (NSString *) objectIDString {
	return [[self.objectID URIRepresentation] absoluteString];
}

- (NSString *) persistantIdentifier {
	return self.objectIDString;
}

- (void) save {
	[self.context save];
}

- (NSManagedObjectContext *) context { return self.managedObjectContext; }
- (NSManagedObjectContext *) moc { return self.managedObjectContext; }

- (void) refreshFromContextMergingChanges: (BOOL) mergeChanges {
	[self.moc refreshObject: self mergeChanges: mergeChanges];
}


- (BOOL) isNew {
	NSDictionary				*vals = [self committedValuesForKeys: nil];
	return [vals count] == 0;
}

- (void) deleteFromContext {
	[self.managedObjectContext deleteObject: self];
}

- (void) replaceAllObjectsInRelationship: (NSString *) relKey withObjects: (NSSet *) newObjects deletingOld: (BOOL) deletingOld {
	[self willChangeValueForKey: relKey];
	
	NSMutableSet				*set = [self mutableSetValueForKey: relKey];
	NSMutableSet				*deleteThese = nil;
	
	if ((set.count > 0 || newObjects.count > 0) && ![set isEqualToSet: newObjects]) {
		if (deletingOld) {
			deleteThese = [NSMutableSet set];
			
			for (id object in set) {
				if (![newObjects containsObject: object]) [deleteThese addObject: object];
			}
		}
		
		[set removeAllObjects];
		if (newObjects) [set addObjectsFromArray: [newObjects allObjects]];
		
		for (NSManagedObject *object in deleteThese) {
			[object deleteFromContext];
		}
	}
	
	[self didChangeValueForKey: relKey];
}

- (BOOL) hasValueForKey: (NSString *) key {
	NSEntityDescription	*entity = [self entity];
	
	if ([[entity attributesByName] objectForKey: key]) return YES;
	if ([[entity relationshipsByName] objectForKey: key]) return YES;
	return [super hasValueForKey: key];
}

- (id) objectForContext: (NSManagedObjectContext *) context {
	[self.managedObjectContext performSelectorOnMainThread: @selector(saveIfNeccesary) withObject: nil waitUntilDone: YES];
	
	return [context objectWithID: self.objectID];
}

- (NSAttributeDescription *) descriptionForAttribute: (NSString *) attributeName {
	NSEntityDescription				*desc = [self entity];
	NSDictionary					*props = [desc propertiesByName];
	NSAttributeDescription			*attrDesc = [props objectForKey: attributeName];
	
	if ([attrDesc isKindOfClass: [NSAttributeDescription class]]) return attrDesc;
	return nil;
}

- (NSRelationshipDescription *) descriptionForRelationship: (NSString *) relationshipName {
	NSEntityDescription				*desc = [self entity];
	NSDictionary					*props = [desc propertiesByName];
	NSRelationshipDescription		*relDesc = [props objectForKey: relationshipName];
	
	if ([relDesc isKindOfClass: [NSRelationshipDescription class]]) return relDesc;
	return nil;
}

- (BOOL) hasAttribute: (NSString *) attr {
	return [self descriptionForAttribute: attr] || [self descriptionForRelationship: attr];
}
@end