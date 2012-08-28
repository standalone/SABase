//
//  NSManagedObjectContext+Additions.m
//
//  Created by Ben Gottlieb on 12/23/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "NSManagedObjectContext+Additions.h"
#import "NSString+Additions.h"
#import "NSObject+Additions.h"
#import "NSNotificationCenter+Additions.h"

#if TARGET_OS_IPHONE
	#import "SA_AlertView.h"
#endif

@interface NSObject (DummyCategory)
- (id) initWithConcurrencyType: (int) type;
@end

NSString *kNotification_PersistentStoreResetDueToSchemaChange = @"kNotification_PersistentStoreResetDueToSchemaChange";
NSString *UPDATE_BLOCKS_KEY = @"SA_UpdateBlocksArray";
NSString *TABLE_FOR_FETCHED_RESULTS_CONTROLLER_KEY = @"SA_TABLE_FOR_FETCHED_RESULTS_CONTROLLER_KEY";

#if TARGET_OS_IPHONE
	#import "SA_AlertView.h"
#endif

@implementation NSManagedObjectContext (ConvenienceAdditions)
+ (id) contextAtPath: (NSString *) path inPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator {
	return [self contextAtPath: path inPersistentStoreCoordinator: coordinator model: nil concurrencyType: 0 /*NSConfinementConcurrencyType */];
}

+ (id) contextAtPath: (NSString *) path inPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator concurrencyType: (int) type {
	return [self contextAtPath: path inPersistentStoreCoordinator: coordinator model: nil concurrencyType: type];
}

+ (id) contextAtPath: (NSString *) path inPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator modelPath: (NSString *) modelPath concurrencyType: (int) type {
	NSManagedObjectModel					*model = [[[NSManagedObjectModel alloc] initWithContentsOfURL: [NSURL fileURLWithPath: modelPath]] autorelease];
	
	SA_Assert(modelPath.length == 0 || model != nil, @"Trying to instantiate an invalid model. Check the path and current version.");
	return [self contextAtPath: path inPersistentStoreCoordinator: coordinator model: model concurrencyType: type];
}

+ (id) contextAtPath: (NSString *) path inPersistentStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator model: (NSManagedObjectModel *) model concurrencyType: (int) type {
	NSDictionary						*options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool: YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool: YES], NSInferMappingModelAutomaticallyOption, nil];
	NSError								*error = nil;
	
	if (![[NSFileManager defaultManager] createDirectoryAtPath: [path stringByDeletingLastPathComponent] withIntermediateDirectories: YES attributes: nil error: &error]) {
		LOG(@"Failed to creat directory at %@: %@", path, error);
		return nil;
	}
		
	if (model == nil) model = [NSManagedObjectModel mergedModelFromBundles: nil];

	if (coordinator == nil) {
		coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
		[coordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: [NSURL fileURLWithPath: path] options: options error: &error];
		
		if (coordinator.persistentStores.count == 0) {
			NSString						*message = [NSString stringWithFormat: @"The database format has changed. The existing database (%@) has been removed.", [path lastPathComponent]];
			
			LOG(@"%@", message);
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kNotification_PersistentStoreResetDueToSchemaChange object: nil];
			
			#if TARGET_OS_IPHONE
				[self performSelector: @selector(displayFailedDatabaseCreationMessage:) withObject: message afterDelay: 0.1];
			#endif
			[[NSFileManager defaultManager] removeItemAtPath: path error: &error];
			[coordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: [NSURL fileURLWithPath: path] options: options error: &error];
		}
		
		if (error) LOG(@"Error while adding persistant store: %@ (%@)", error, error.userInfo);
	} else if (error) 
		LOG(@"Error while creating persistant store: %@", [error localizedDescription]);
	
	NSManagedObjectContext			*objectContext = nil;
	#if TARGET_OS_IPHONE
		if (RUNNING_ON_50)
			objectContext = [(id) [self alloc] initWithConcurrencyType: type];
		else
	#endif
		objectContext = [[self alloc] init];
	
	[objectContext setPersistentStoreCoordinator: coordinator];
	
	return objectContext;
}

+ (void) displayFailedDatabaseCreationMessage: (NSString *) message {
	#if DEBUG && TARGET_OS_IPHONE
		[SA_AlertView showAlertWithTitle: message message: @"A new database will be created."];
	#else
		NSLog(@"*******************\n%@\nA new database will be created.\n********************************", message);
	#endif
}

- (Class) classFromEntityName: (NSString *) entityName {
	NSDictionary					*entities = [self.persistentStoreCoordinator.managedObjectModel entitiesByName];
	
	return NSClassFromString([[entities objectForKey: entityName] managedObjectClassName]);
}

- (id) insertNewEntityWithName: (NSString *) name {
	return [NSEntityDescription insertNewObjectForEntityForName: name inManagedObjectContext: self];
}

- (id) objectWithIDString: (NSString *) string {
	if (string.length == 0) return nil;
	
	NSURL							*url = [NSURL URLWithString: string];
	NSManagedObjectID				*managedID = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation: url];
	NSError							*error = nil;
	
	if (managedID == nil) return nil;
	id								object = [self existingObjectWithID: managedID error: &error];
	
	if (error) LOG(@"Error while fetching object with ID %@: %@, (%@)", string, [error localizedDescription], [error userInfo]);
	return object;
}

- (id) anyObjectOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate {
	NSFetchRequest					*request = [self fetchRequestWithEntityName: entityName predicate: predicate sortBy: nil fetchLimit: 1];
	if (request == nil) return nil;
	NSError							*error = nil;
	NSArray							*results = nil;
	
	@try {
		results = [[[self executeFetchRequest: request error: &error] retain] autorelease];
	} @catch (NSException *e) {
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_SA_ErrorWhileGeneratingFetchRequest object: e userInfo: [NSDictionary dictionaryWithObjectsAndKeys: entityName, @"entity", predicate, @"predicate", nil]];
	}

	if (error) LOG(@"Error while attempting to fetch %@ matching (%@): %@", entityName, predicate, error);
	
	if (results.count) return [results objectAtIndex: 0];
	return nil;
}

- (id) firstObjectOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors {
	NSFetchRequest					*request = [self fetchRequestWithEntityName: entityName predicate: predicate sortBy: sortDescriptors fetchLimit: 1];
	if (request == nil) return nil;
	NSError							*error = nil;

	NSArray							*results = nil;
	
	@try {
		results = [[[self executeFetchRequest: request error: &error] retain] autorelease];
	} @catch (NSException *e) {
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_SA_ErrorWhileGeneratingFetchRequest object: e userInfo: [NSDictionary dictionaryWithObjectsAndKeys: entityName, @"entity", predicate, @"predicate", sortDescriptors, @"sortBy", nil]];
	}

	if (error) LOG(@"Error while attempting to fetch %@ matching (%@): %@", entityName, predicate, error);
	
	if (results.count) return [results objectAtIndex: 0];
	return nil;
}

- (NSArray *) allObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors fetchLimit: (int) fetchLimit {
	NSFetchRequest					*request = [self fetchRequestWithEntityName: entityName predicate: predicate sortBy: sortDescriptors fetchLimit: fetchLimit];
	if (request == nil) return nil;
	NSError							*error = nil;

	NSArray							*results = nil;
	
	@try {
		results = [[[self executeFetchRequest: request error: &error] retain] autorelease];
	} @catch (NSException *e) {
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_SA_ErrorWhileGeneratingFetchRequest object: e userInfo: [NSDictionary dictionaryWithObjectsAndKeys: entityName, @"entity", predicate, @"predicate", sortDescriptors, @"sortBy", nil]];
	}

	if (error) LOG(@"Error while attempting to fetch %@ matching (%@): %@", entityName, predicate, error);
	
	return results;
}

- (NSFetchRequest *) fetchRequestWithEntityName: (NSString *) entityName predicate: (NSPredicate *) predicate sortBy: (NSArray *) sortBy fetchLimit: (int) fetchLimit {
	NSEntityDescription				*entityDescription = [NSEntityDescription entityForName: entityName inManagedObjectContext: self];
	
	if (entityDescription == nil) {
		NSLog(@"Trying to fetch an unknown entity: %@", entityName);
		return nil;
	}
	
	NSFetchRequest					*request = nil;
	
	@try {
		request = [[NSFetchRequest alloc] init];
		[request setEntity: entityDescription];
		if (predicate) [request setPredicate: predicate];
		if (sortBy) [request setSortDescriptors: sortBy];
		if (fetchLimit) [request setFetchLimit: fetchLimit];
	} @catch (NSException *e) {
		[[NSNotificationCenter defaultCenter] postNotificationName: kNotification_SA_ErrorWhileGeneratingFetchRequest object: e userInfo: [NSDictionary dictionaryWithObjectsAndKeys: entityName, @"entity", predicate, @"predicate", sortBy, @"sortBy", nil]];
	}
	
	return [request autorelease];
}

- (NSArray *) allObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate {
	return [self allObjectsOfType: entityName matchingPredicate: predicate sortedBy: nil];
}

- (NSArray *) allObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors {
	return [self allObjectsOfType: entityName matchingPredicate: predicate sortedBy: sortDescriptors fetchLimit: 0];
}

- (NSArray *) nObjects: (int) n ofType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors {
	return [self allObjectsOfType: entityName matchingPredicate: predicate sortedBy: sortDescriptors fetchLimit: n];
}


- (NSUInteger) numberOfObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate {
	NSFetchRequest					*request = [self fetchRequestWithEntityName: entityName predicate: predicate sortBy: nil fetchLimit: 0];
	
	if (request == nil) return 0;
	NSError							*error = nil;
	NSUInteger						result = [self countForFetchRequest: request error: &error];
	
	if (error) LOG(@"Error while attempting to count %@ matching (%@): %@", entityName, predicate, error);
	return result;
}

- (void) cancelQueuedSave {
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(save) object: nil];
}

- (void) queueSaveIn: (float) seconds {
	[self cancelQueuedSave];
	[self performSelector: @selector(save) withObject: nil afterDelay: seconds];
}

- (void) queueSave {
	[self queueSaveIn: 0.25];
}

- (id) copy {
	NSManagedObjectContext				*context = [[[self class] alloc] init];
	[context setPersistentStoreCoordinator: [self persistentStoreCoordinator]];
	return context;
}

- (void) saveIfNeccesary {
	if (self.insertedObjects.count || self.deletedObjects.count || self.updatedObjects.count) [self save];
}

- (void) save {
	NSError								*error = nil;
	static int							failCount = 0;
	int									maxFailsBeforeReset = 2;
	
	#if DEBUG
		maxFailsBeforeReset = 1;
	#endif

	[self cancelQueuedSave]; 
	@try {
		[self save: &error];
	} @catch (id e) {
		LOG(@"Problem while saving database: %@", e);
	}
	if (error) {
		NSDictionary				*info = error.userInfo;
		
		LOG(@"Error while saving context: %@", error);	
		
		if ([info objectForKey: @"NSDetailedErrors"]) {for (NSError *detailedError in [info objectForKey: @"NSDetailedErrors"]) {
			LOG(@"Detailedd Error: %@, %@", detailedError, [detailedError userInfo]);	
		}} else if ([info objectForKey: @"conflictList"]) {
			for (NSManagedObject *object in [info objectForKey: @"NSDetailedErrors"]) {
				LOG(@"Conflicted object: %@", object);
			}
			LOG(@"All Objects: %@", [info objectForKey: @"NSDetailedErrors"]);
		}

		failCount++;
		
		if (failCount >= maxFailsBeforeReset) {
			LOG(@"******************************* Too many fails, rolling database back to last safe version *******************************");
			#if DEBUG && TARGET_OS_IPHONE
				[SA_AlertView showAlertWithTitle: @"There was a problem saving the database. Recent changes will be discarded." message: [error fullDescription] tag: (int) objc_unretainedObject(self)];
			#endif
			[self performSelector: @selector(rollback) withObject: nil afterDelay: 0.0];
			failCount = 0;
		}
	}
}

//this is so that you can pass an NSManagedObject to an SA_ConnectionQueue as a persistant object delegate
- (id) delegateWithIdentifier: (NSString *) identifier {
	return (id) [self objectWithIDString: identifier];
}

#if TARGET_OS_IPHONE
- (NSFetchedResultsController *) fetchedResultsControllerForEntityNamed: (NSString *) entityName predicate: (NSPredicate *) predicate sortedBy: (NSArray *) sortDescriptors sectionNameKeyPath: (NSString *) sectionNameKeyPath cacheName: (NSString *) cacheName {
	NSFetchRequest						*fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription					*entity = [NSEntityDescription entityForName: entityName inManagedObjectContext: self];
	
	[fetchRequest setEntity: entity];
	[fetchRequest setFetchBatchSize: 20];
	[fetchRequest setSortDescriptors: sortDescriptors ? sortDescriptors : [NSArray array]];
	if (predicate) [fetchRequest setPredicate: predicate];
	
	NSFetchedResultsController			*fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: fetchRequest managedObjectContext: self sectionNameKeyPath: sectionNameKeyPath cacheName: cacheName];
	
	[fetchRequest release];
	
	return [fetchedResultsController autorelease];
}    
#endif

- (void) deleteObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate {
	[self deleteObjectsOfType: entityName matchingPredicate: predicate withFetchLimit: 0];
}

- (NSArray *) objectsWithIDs: (NSArray *) objectIDs {
	NSMutableArray			*objects = [NSMutableArray array];
	
	for (NSManagedObjectID *objectID in objectIDs) {
		NSManagedObject		*object = [self objectWithID: objectID];
		if (object) [objects addObject: object];
	}
	return objects;
}

- (void) deleteObjectsOfType: (NSString *) entityName matchingPredicate: (NSPredicate *) predicate withFetchLimit: (int) fetchLimit {
	NSFetchRequest						*allObjects = [[NSFetchRequest alloc] init];
	NSEntityDescription					*entity = [NSEntityDescription entityForName: entityName inManagedObjectContext: self];
	int									deleteCount = 0;
	
	if (fetchLimit) [allObjects setFetchLimit: fetchLimit];
	[allObjects setEntity: entity];
	if (predicate) [allObjects setPredicate: predicate];
	[allObjects setIncludesPropertyValues: NO]; //only fetch the managedObjectID
	
	while (true) {
		NSError								*error = nil;
		NSAutoreleasePool					*pool = [[NSAutoreleasePool alloc] init];
		NSArray								*objects;
		
		 @try {
			 objects = [self executeFetchRequest: allObjects error: &error];
		} @catch (NSException *e) {
			LOG(@"Exception: %@", e);
			[pool release];
			break;
		}
		if (objects.count == 0) {
			[pool release];
			break;
		}
		for (NSManagedObject *object in objects) {
			[self deleteObject: object];
		}
		deleteCount += [objects count];
		LOG(@"%d %@ objects deleted", deleteCount, entityName);
		[pool release];
	}
	
	[allObjects release];
}

- (void) setPrimaryStoreMetadata: (NSDictionary *) data {
	NSArray				*stores = self.persistentStoreCoordinator.persistentStores;
	NSPersistentStore	*store;
	
	if (stores.count == 0) return;
	store = [stores objectAtIndex: 0];
	
	[store setMetadata: data];
}

- (NSDictionary *) primaryStoreMetadata {
	NSArray				*stores = self.persistentStoreCoordinator.persistentStores;
	
	if (stores.count == 0) return nil;
	
	return [[stores objectAtIndex: 0] metadata];
}

- (void) setObjectInPrimaryStoreMetadata: (id) object forKey: (id) key {
	NSMutableDictionary			*metadata = [[self.primaryStoreMetadata mutableCopy] autorelease];
	
	if (metadata == nil && object == nil) return;
	
	if (metadata) {
		if (object)
			[metadata setObject: object forKey: key];	
		else
			[metadata removeObjectForKey: key];
	} else
		metadata = [NSDictionary dictionaryWithObject: object forKey: key];
		
	self.primaryStoreMetadata = metadata;
}

- (id) objectInPrimaryStoreMetadataForKey: (id) key {
	return [self.primaryStoreMetadata objectForKey: key];
}

- (NSURL *) primaryStoreURL {
	NSArray				*stores = self.persistentStoreCoordinator.persistentStores;
	
	if (stores.count == 0) return nil;
	
	return [[stores objectAtIndex: 0] URL];	
}


#if NS_BLOCKS_AVAILABLE
- (void) performBlock: (managedObjectBlock) block withObject: (NSManagedObject *) object onThread: (NSThread *) thread {
	NSManagedObjectID			*objectID = object.objectID;
	
	[NSObject performBlock: ^{
		NSManagedObject				*threadLocalObject = [self objectWithID: objectID];
		
		block(threadLocalObject);
	} onThread: thread waitUntilDone: NO];
}

- (void) registerForContextUpdatesUsingBlock: (contextUpdatedBlock) block withTag: (NSString *) tag {
	NSMutableDictionary				*changeBlocks = [self associatedValueForKey: UPDATE_BLOCKS_KEY];
	
	if (changeBlocks == nil) {
		changeBlocks = [[NSMutableDictionary alloc] init];
		[self associateValue: changeBlocks forKey: UPDATE_BLOCKS_KEY];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(sa_mergeChangesFromContextDidSaveNotification:) name: NSManagedObjectContextDidSaveNotification object: self];
	}
	contextUpdatedBlock				copiedBlock = Block_copy(block);
	
	[changeBlocks setObject: copiedBlock forKey: tag];
}

- (void) sa_mergeChangesFromContextDidSaveNotification: (NSNotification *) note {
	NSManagedObjectContext				*context = note.object;
	NSDictionary						*changeBlocks = [self associatedValueForKey: UPDATE_BLOCKS_KEY];
	
	for (NSString *tag in changeBlocks) {
		contextUpdatedBlock			block = [changeBlocks objectForKey: tag];
		block(context, tag);
	}
}

- (void) unregisterForContextUpdates: (NSString *) tag {
	NSMutableDictionary				*changeBlocks = [self associatedValueForKey: UPDATE_BLOCKS_KEY];
	
	if (changeBlocks == nil) return;
	
	contextUpdatedBlock			block = [changeBlocks objectForKey: tag];
	
	if (block)  Block_release(block);

	[changeBlocks removeObjectForKey: tag];
	if (changeBlocks.count == 0) {
		[self associateValue: nil forKey: UPDATE_BLOCKS_KEY];
		[changeBlocks release];
		[[NSNotificationCenter defaultCenter] removeObserver: self name: NSManagedObjectContextDidSaveNotification object: self];
	}
}
#endif

#if TARGET_OS_IPHONE
//=============================================================================================================================
#pragma mark Fetched Results Controller methods
- (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request inTable: (UITableView *) table withSectionNameKeyPath: (NSString *) sectionKeyPath cacheName: (NSString *) cacheName {
	NSError							*error = nil;
	NSFetchedResultsController		*controller = [[NSFetchedResultsController alloc] initWithFetchRequest: request managedObjectContext: self sectionNameKeyPath: sectionKeyPath cacheName: cacheName];
	
	controller.delegate = (id) self;
	[controller performFetch: &error];
	[self associateValue: [table retain] forKey: TABLE_FOR_FETCHED_RESULTS_CONTROLLER_KEY];
	
	if (error) {
		[SA_AlertView showAlertWithTitle: $S(@"Problem Fetching %@", request.entity.name) error: error];
		LOG(@"Error while preparing fetchedResultsController with request: %@: %@", request, error);
	}
	return controller;
} 

- (void) clearFetchedResultsController: (NSFetchedResultsController *) controller {
	UITableView					*table = [self associatedValueForKey: TABLE_FOR_FETCHED_RESULTS_CONTROLLER_KEY];

	[table release];
	[controller release];
	[self associateValue: nil forKey: TABLE_FOR_FETCHED_RESULTS_CONTROLLER_KEY];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
	UITableView					*table = [self associatedValueForKey: TABLE_FOR_FETCHED_RESULTS_CONTROLLER_KEY];

    if (type == NSFetchedResultsChangeUpdate) {
		if (indexPath.section >= [table numberOfSections]) {
			return;
		} else if (indexPath.row >= [table numberOfRowsInSection: indexPath.section]) {
			return;
		}
    }
	
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [table insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [table deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
			
            [table reloadRowsAtIndexPaths: [NSArray arrayWithObject: indexPath] withRowAnimation: UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeMove:
            [table deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [table insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
	UITableView					*table = [self associatedValueForKey: TABLE_FOR_FETCHED_RESULTS_CONTROLLER_KEY];
    [table beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
	UITableView					*table = [self associatedValueForKey: TABLE_FOR_FETCHED_RESULTS_CONTROLLER_KEY];
	
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [table insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [table deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	UITableView					*table = [self associatedValueForKey: TABLE_FOR_FETCHED_RESULTS_CONTROLLER_KEY];
    [table endUpdates];
}
#endif

- (NSManagedObjectContext *) createChildContext {
	if (!RUNNING_ON_50) return nil;
	
	NSManagedObjectContext			*moc = [[[NSManagedObjectContext alloc] init] autorelease];
	
	moc.parentContext = self;
	return moc;
}
@end
