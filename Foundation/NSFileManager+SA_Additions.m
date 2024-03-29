//
//  NSFileManager+Additions.m
//
//  Created by Ben Gottlieb on 4/1/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "NSFileManager+SA_Additions.h"
#import "NSBundle+SA_Additions.h"
#import "NSUserDefaults+SA_Additions.h"

#if TARGET_OS_IPHONE

#endif

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <fcntl.h>
#include <sys/xattr.h>

static NSMutableArray				*s_watchedDirectoryInfoDictionaries = nil, *s_currentInProgressDirectories = nil;

@implementation NSFileManager (NSFileManager_SA_Additions)
@dynamic applicationSupportFolder, documentsFolder;

- (NSDate *) modificationDateOfFileAtPath: (NSString *) path {
	NSError						*error = nil;
	NSDictionary				*fileAttrs = [self attributesOfItemAtPath: path error: &error];
	
	if (error) NSLog(@"Error while seeking file attributes for %@", path);
	
	return [fileAttrs objectForKey: NSFileModificationDate];	
}

- (NSArray *) databaseRelatedURLsFromURL: (NSURL *) url {
	NSArray		*suffixes = @[ @".tmp-shm", @".tmp-wal", @"-shm", @"-wal", ];
	NSError		*error;
	NSArray		*parentDirectoryContents = [self contentsOfDirectoryAtURL: url.URLByDeletingLastPathComponent includingPropertiesForKeys: nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles error: &error];
	
	if (parentDirectoryContents == nil) return @[];
	
	NSMutableArray		*related = @[ url ].mutableCopy;
	
	for (NSURL *siblingURL in parentDirectoryContents) {
		NSString				*filename = siblingURL.path.lastPathComponent;
		for (NSString *suffix in suffixes) {
			if ([filename hasSuffix: suffix]) {
				[related addObject: siblingURL];
				break;
			}
		}
	}
	
	return related;
}

- (BOOL) moveDatabaseAtURL: (NSURL *) src toURL: (NSURL *) dest error: (NSError **) error {
	return [self move: YES databaseAtURL: src toURL: dest error: error];
}

- (BOOL) move: (BOOL) move databaseAtURL: (NSURL *) src toURL: (NSURL *) dest error: (NSError **) error {
	NSURL				*destParent = dest.URLByDeletingLastPathComponent;
	NSString			*baseFileName = dest.lastPathComponent.stringByDeletingPathExtension;
	NSArray				*urlsToMove = [self databaseRelatedURLsFromURL: src];
	NSMutableArray		*newURLs = [NSMutableArray array];
	
	for (NSURL *siblingURL in urlsToMove) {
		NSString			*newFilename = [baseFileName stringByAppendingPathExtension: siblingURL.pathExtension];
		NSURL				*newURL = [destParent URLByAppendingPathComponent: newFilename];
		
		[self removeItemAtURL: newURL error: error];
		[newURLs addObject: newURL];
	}
	
	for (NSUInteger i = 0; i < newURLs.count; i++) {
		NSURL				*srcURL = urlsToMove[i];
		NSURL				*newURL = newURLs[i];
		
		if (move) {
			if (![self moveItemAtURL: srcURL toURL: newURL error: error]) return NO;
		} else {
			if (![self copyItemAtURL: srcURL toURL: newURL error: error]) return NO;
		}
	}
	return YES;
}

- (BOOL) copyDatabaseAtURL: (NSURL *) src toURL: (NSURL *) dest error: (NSError **) error {
	return [self move: NO databaseAtURL: src toURL: dest error: error];
}

- (BOOL) removeDatabaseAtURL: (NSURL *) url error: (NSError **) error {
	NSArray				*urlsToDelete = [self databaseRelatedURLsFromURL: url];

	for (NSURL *url in urlsToDelete) {
		[self removeItemAtURL: url error: error];
	}
	return YES;
}

//=============================================================================================================================
#pragma mark File changes
//- (void) kqueueFired {
//    int					kq;
//    struct kevent		event;
//    struct timespec		timeout = { 0, 0 };
//    int					eventCount;
//	
//    kq = CFFileDescriptorGetNativeDescriptor(self->_kqRef);
//    assert(kq >= 0);
//	
//    eventCount = kevent(kq, NULL, 0, &event, 1, &timeout);
//    assert( (eventCount >= 0) && (eventCount < 2) );
//	
//    if (eventCount == 1) {
//        NSLog(@"dir changed");
//    }
//	
//    CFFileDescriptorEnableCallBacks(self->_kqRef, kCFFileDescriptorReadCallBack);
//}
//
static void NSFileManagerKQueueCallback(CFFileDescriptorRef kqRef, CFOptionFlags callBackTypes, NSDictionary *info)
{
	id				target = [info objectForKey: @"target"];
	NSString		*actionString = [info objectForKey: @"action"];
	SEL				action = NSSelectorFromString(actionString);
	NSString		*path = [info objectForKey: @"path"];
	
	if ([s_currentInProgressDirectories containsObject: path]) return;
	
	if (s_currentInProgressDirectories == nil) s_currentInProgressDirectories = [NSMutableArray array];
	[s_currentInProgressDirectories addObject: path];
	if ([target respondsToSelector: action]) [target performSelector: action withObject: path afterDelay: 1.0];
	[s_currentInProgressDirectories removeObject: path];
    assert(callBackTypes == kCFFileDescriptorReadCallBack);

	//re-setup the watch
	[NSFileManager stopWatchingChangesAtPath: path];
	[NSFileManager watchForChangesAtPath: path withTarget: target action: action];
}

+ (void) watchForChangesAtPath: (NSString *) path withTarget: (id) target action: (SEL) action {
    int							dirFD;
    int							kq;
    int							retVal;
    struct kevent				eventToAdd;
	NSMutableDictionary			*infoDictionary = [[NSMutableDictionary alloc] initWithObjectsAndKeys: target, @"target", NSStringFromSelector(action), @"action", path, @"path", nil];
    CFFileDescriptorContext		context = { 0, NULL, NULL, NULL, NULL };
    CFRunLoopSourceRef			rls;
	CFFileDescriptorRef			ref;
	
	context.info = (__bridge void *) (infoDictionary);
    dirFD = open([path fileSystemRepresentation], O_EVTONLY);
    assert(dirFD >= 0);
	
    kq = kqueue();
    assert(kq >= 0);
	
    eventToAdd.ident  = dirFD;
    eventToAdd.filter = EVFILT_VNODE;
    eventToAdd.flags  = EV_ADD | EV_CLEAR;
    eventToAdd.fflags = NOTE_WRITE;
    eventToAdd.data   = 0;
    eventToAdd.udata  = NULL;
	
    retVal = kevent(kq, &eventToAdd, 1, NULL, 0, NULL);
    assert(retVal == 0);
		
    ref = CFFileDescriptorCreate(NULL, kq, true, (CFFileDescriptorCallBack) NSFileManagerKQueueCallback, &context);
    assert(ref != NULL);
	
    rls = CFFileDescriptorCreateRunLoopSource(NULL, ref, 0);
    SA_Assert(rls != NULL, @"changes at path descriptor is null");
	
    CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);

	[infoDictionary setObject: [NSValue valueWithPointer: ref] forKey: @"ref"];
	[infoDictionary setObject: [NSValue valueWithPointer: rls] forKey: @"rls"];
	
    CFRelease(rls);
	
    CFFileDescriptorEnableCallBacks(ref, kCFFileDescriptorReadCallBack);
	
	if (s_watchedDirectoryInfoDictionaries == nil) s_watchedDirectoryInfoDictionaries = [[NSMutableArray alloc] init];
	[s_watchedDirectoryInfoDictionaries addObject: infoDictionary];
}

+ (void) stopWatchingChangesAtPath: (NSString *) path {
	for (NSDictionary *info in s_watchedDirectoryInfoDictionaries.copy) {
		NSString			*watchedPath = [info objectForKey: @"path"];
		
		if ([path isEqualToString: watchedPath]) {
			CFFileDescriptorRef			ref = [[info objectForKey: @"ref"] pointerValue];
			CFRunLoopSourceRef			rls = [[info objectForKey: @"rls"] pointerValue];
			
			if (ref) CFFileDescriptorDisableCallBacks(ref, kCFFileDescriptorReadCallBack);
			if (rls) CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
			
			[s_watchedDirectoryInfoDictionaries removeObject: info];
			return;
		}
	}
}

- (BOOL) copyFileOfVersion: (NSUInteger) currentFileVersion from: (NSString *) srcPath to: (NSString *) dstPath error: (NSError	**) outError {
	NSString			*userDefaultsKey = $S(@"%s_file_version", [srcPath fileSystemRepresentation]);
	NSUInteger			existingVersion = [NSUserDefaults integerForKey: userDefaultsKey];
	NSError				*error;
	
	if (existingVersion	>= currentFileVersion) return YES;			//all set, ignore it
	
	if ([self fileExistsAtPath: dstPath]) {
        if (![self removeItemAtPath: dstPath error: &error]) {
         //   SA_BASE_LOG(@"Error while deleting %@: %@", [dstPath lastPathComponent], error);
        }
	}
	
	if (![self copyItemAtPath: srcPath toPath: dstPath error: &error]) {
		SA_BASE_LOG(@"Error while deleting %@: %@", [srcPath lastPathComponent], error);
		if (outError) *outError = error;
		return NO;
	}
	
	[NSUserDefaults syncInteger: currentFileVersion forKey: userDefaultsKey];
	return YES;
}

+ (NSURL *) documentsDirectory { return [[[NSFileManager defaultManager] URLsForDirectory: NSDocumentDirectory inDomains: NSUserDomainMask] lastObject]; }
+ (NSURL *) libraryDirectory { return [[[NSFileManager defaultManager] URLsForDirectory: NSLibraryDirectory inDomains: NSUserDomainMask] lastObject]; }
+ (NSURL *) cachesDirectory { return [[[NSFileManager defaultManager] URLsForDirectory: NSCachesDirectory inDomains: NSUserDomainMask] lastObject]; }
+ (NSURL *) applicationSupportDirectory { return [[[NSFileManager defaultManager] URLsForDirectory: NSApplicationSupportDirectory inDomains: NSUserDomainMask] lastObject]; }


//=============================================================================================================================
#pragma mark
- (NSString *) systemFolderPath: (NSSearchPathDirectory) type {
	NSArray			*dirs = NSSearchPathForDirectoriesInDomains(type, NSUserDomainMask, YES);
	NSString		*path = nil, *name = [NSBundle visibleName];
	NSError			*error = nil;
	
	path = (dirs.count) ? [[dirs objectAtIndex: 0] stringByAppendingPathComponent: name] : [$S(@"~/Library/Application Support/%@", name) stringByExpandingTildeInPath];
	
	[self createDirectoryAtPath: path withIntermediateDirectories: YES attributes: nil error: &error];
	if (error) SA_BASE_LOG(@"Error while creating %@: %@", path, error);
	return path;
}
- (NSString *) applicationSupportFolder { return [self systemFolderPath: NSApplicationSupportDirectory]; }
- (NSString *) documentsFolder { return [self systemFolderPath: NSDocumentDirectory]; }

#if TARGET_OS_IPHONE
+ (void) setFileAtURLNotBackedUp: (NSURL *) url {
    NSError		*error = nil;
	
	if ([UIDevice currentDevice].systemVersion.floatValue < 5.1 || NSURLIsExcludedFromBackupKey == nil) return;
    BOOL		success = [url setResourceValue: (id) kCFBooleanTrue forKey: NSURLIsExcludedFromBackupKey error: &error];
 
	if (!success){
        NSLog(@"Error excluding %@ from backup %@", [url lastPathComponent], error);
    }
//    return success;
//
//	u_int8_t		attr_value = 1;
//	const char		*attrName = "com.apple.MobileBackup";
//	
//    setxattr([[url path] fileSystemRepresentation], attrName, &attr_value, 1, 0, 0);
}
#endif
@end
