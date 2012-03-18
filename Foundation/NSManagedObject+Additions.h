//
//  NSManagedObject+Additions.h
//
//  Created by Ben Gottlieb on 5/25/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSManagedObject (NSManagedObject_Additions)

@property (nonatomic, readonly) NSString *objectIDString;
@property (nonatomic, readonly) NSManagedObjectContext *context, *moc;

- (id) objectWithIDString: (NSString *) string;
- (BOOL) isNew;
- (BOOL) hasAttribute: (NSString *) attr;
- (void) deleteFromContext;
- (void) save;

- (void) refreshFromContextMergingChanges: (BOOL) mergeChanges;
- (id) objectForContext: (NSManagedObjectContext *) context;

- (NSAttributeDescription *) descriptionForAttribute: (NSString *) attributeName;
- (NSRelationshipDescription *) descriptionForRelationship: (NSString *) relationshipName;

- (void) replaceAllObjectsInRelationship: (NSString *) relKey withObjects: (NSSet *) newObjects deletingOld: (BOOL) deletingOld;
@end