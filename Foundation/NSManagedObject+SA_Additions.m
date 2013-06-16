//
//  NSManagedObject+Additions.m
//
//  Created by Ben Gottlieb on 5/25/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "NSManagedObject+SA_Additions.h"
#import "NSManagedObjectContext+SA_Additions.h"
#import "NSObject+SA_Additions.h"

@implementation NSManagedObject (NSManagedObject_SA_Additions)
@dynamic objectIDString, moc;

- (BOOL) didValue: (id) value changeForKey: (NSString *) key {
	id				existing = [self valueForKey: key];
	
	if (existing && value && [existing isEqual: value]) return NO;
	if (!existing && !value) return NO;
	
	[self setValue: value forKey: key];
	return YES;
}

- (id) objectWithIDString: (NSString *) string {
	return [self.moc objectWithIDString: string];
}

- (NSString *) objectIDString {
	return [[self.objectID URIRepresentation] absoluteString];
}

- (NSString *) persistantIdentifier {
	return self.objectIDString;
}

- (void) save {
	[self.moc save];
}

- (NSManagedObjectContext *) moc { return self.managedObjectContext; }

- (void) refreshFromContextMergingChanges: (BOOL) mergeChanges {
	[self.moc refreshObject: self mergeChanges: mergeChanges];
}

- (void) deleteFromContext {
	[self.managedObjectContext deleteObject: self];
}

- (BOOL) hasValueForKey: (NSString *) key {
	NSEntityDescription	*entity = [self entity];
	
	if ([[entity attributesByName] objectForKey: key]) return YES;
	if ([[entity relationshipsByName] objectForKey: key]) return YES;
	return [super hasValueForKey: key];
}

- (id) objectInContext: (NSManagedObjectContext *) context {
	id		object = [context objectWithID: self.objectID];
	
	if (object || !self.moc.isSaveNecessary) return object;
	
	[self.managedObjectContext save];
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

- (id) objectForKeyedSubscript: (id) key {
	return [self valueForKey: key];
}
- (void) setObject: (id) obj forKeyedSubscript: (id) key {
	[self setValue: obj forKey: key];
}

@end