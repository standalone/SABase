//
//  SA_ConnectionQueue.m
//
//  Created by Ben Gottlieb on 3/29/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "SA_ConnectionQueue.h"
//#import "SA_ConnectionQueue+Persistance.h"
#import "NSString+SA_Additions.h"
#import "NSData+SA_Additions.h"
#import "NSNotificationCenter+SA_Additions.h"
#import "SA_Utilities.h"
#import "NSObject+SA_Additions.h"
#import "NSBundle+SA_Additions.h"
#import "NSError+SA_Additions.h"
#import "dispatch_additions_SA.h"
#import "NSError+SA_Additions.h"
#import "NSArray+SA_Additions.h"
#import "NSSet+SA_Additions.h"
#import "SA_ThreadsafeMutableCollections.h"


#define			LOG_CONNECTION(connection)				if (SA_Base_DebugMode()) {LOG_DATA(connection.uploadedDataStream, connection.tag);}
#define			LOG_UPLOAD(connection, name)			if (SA_Base_DebugMode()) [connection.uploadedDataStream writeToFile: [[NSString stringWithFormat: @"~/Library/Downloads/%@ up.txt", name] stringByExpandingTildeInPath] options: 0 error: nil]
#define			LOG_DOWNLOAD(connection, name)			if (SA_Base_DebugMode()) [connection.downloadedDataStream writeToFile: [[NSString stringWithFormat: @"~/Library/Downloads/%@ down.txt", name] stringByExpandingTildeInPath] options: 0 error: nil]

#if !TARGET_OS_IPHONE
	typedef NSUInteger 		UIBackgroundTaskIdentifier;
	#define					UIBackgroundTaskInvalid				0
#endif


#if VALIDATE_XML_UPLOADS
	#import "SA_XMLGenerator.h"
#endif

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#include <netdb.h>

#if TARGET_OS_IPHONE
	#import "SA_PleaseWaitDisplay.h"
	#import "SA_AlertView.h"
#endif

NSString *kConnectionNotification_NotConnectedToInternet = @"SA_Connection: Not connected to the internet";
NSString *kConnectionNotification_ConnectionFailedToStart = @"SA_Connection: could not start connection";
NSString *kConnectionNotification_AllConnectionsCompleted = @"SA_Connection: all connections completed";
NSString *kConnectionNotification_ConnectionReturnedBadStatus = @"SA_Connection: bad status";
NSString *kConnectionNotification_ConnectionStarted = @"SA_Connection: started";
NSString *kConnectionNotification_ConnectionFinished = @"SA_Connection: finished";
NSString *kConnectionNotification_Queued = @"SA_Connection: queued";
NSString *kConnectionNotification_Dequeued = @"SA_Connection: dequeued";
NSString *kConnectionNotification_ConnectionCancelled = @"SA_Connection: cancelled";
NSString *kConnectionNotification_ConnectionFailed = @"SA_Connection: failed";
NSString *kConnectionNotification_ConnectionStateChanged = @"SA_Connection: state changed";
NSString *kConnectionNotification_ConnectionReachabilityChanged = @"SA_Connection: reachability changed";

@interface SA_ConnectionQueue ()

@property (nonatomic, strong) SA_ThreadsafeMutableArray *pleaseWaitConnections;
@property (nonatomic, strong) SA_ThreadsafeMutableDictionary *headers;
@property (nonatomic, strong) NSArray *connectionSortDescriptors;
@property (nonatomic) float highwaterMark;
@property (nonatomic) BOOL offlineAlertShown, wifiAvailable, wlanAvailable;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskID;
@property (nonatomic, weak) SA_Connection *currentTopPleaseWaitConnection;
@property (nonatomic) SCNetworkReachabilityRef reachabilityRef;

@property (nonatomic, strong) NSOperationQueue *privateQueue;
@property (nonatomic, weak) NSTimer *queueProcessingTimer;
@property (nonatomic) long long bytesDownloaded;
@property (nonatomic) BOOL asyncConnectionHandling;

@property (nonatomic, strong) NSArray *pending;
@property (nonatomic, strong) NSSet *active;


- (void) fireReachabilityStatus;
- (void) reorderPendingConnectionsByPriority;
- (void) incrementBytesDownloaded: (long long) byteCount;

@end

@interface SA_Connection()
@property(nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *mutableData;
@property (nonatomic, strong) NSMutableDictionary *connectionHeaders, *extraKeyValues;
@property (nonatomic, readwrite, strong) NSURL *url;
@property (nonatomic, readwrite, strong) NSURLRequest *request;
@property (nonatomic, readwrite) NSString *filename;
@property (nonatomic, readwrite, strong) id <SA_ConnectionDelegate> delegate;
@property (nonatomic, strong) NSArray *receivedCookies;
@property (nonatomic, readwrite, strong) NSDate *requestStartedAt, *responseReceivedAt, *finishedLoadingAt;

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error;
@end



//=============================================================================================================================
//=============================================================================================================================
#pragma mark SA_ConnectionQueue
@implementation SA_ConnectionQueue
@synthesize offline = _offline, maxSimultaneousConnections = _maxSimultaneousConnections, activityIndicatorCount = _activityIndicatorCount;
SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(SA_ConnectionQueue, sharedQueue);

+ (NSString *) logDirectoryPath {
	static NSString				*path = nil;
	
	if (path == nil) {
		NSString					*docs = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex: 0];
		NSString					*appFolder = [docs stringByAppendingPathComponent: [NSBundle visibleName]];
		BOOL						isDirectory = NO;
		NSError						*error = nil;
		
		if (![[NSFileManager defaultManager] fileExistsAtPath: appFolder isDirectory: &isDirectory]) [[NSFileManager defaultManager] createDirectoryAtPath: appFolder withIntermediateDirectories: YES attributes: nil error: &error];
		
		path = [appFolder stringByAppendingPathComponent: @"LOGGED_CONNECTIONS"];
		if (![[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory]) [[NSFileManager defaultManager] createDirectoryAtPath: path withIntermediateDirectories: YES attributes: nil error: &error];

	}
	return path;
}

+ (NSString *) nextPrefixed: (NSString *) prefix pathForTag: (NSString *) tag {
	NSString					*root = [SA_ConnectionQueue logDirectoryPath];
	NSUInteger					index = 1;
	NSFileManager				*mgr = [NSFileManager defaultManager];
	
	while (index < 10000) {
		NSString					*path = [root stringByAppendingPathComponent: [NSString stringWithFormat: @"%@; %@_%lu.txt", prefix, tag, (unsigned long)index]];

		if (![mgr fileExistsAtPath: path]) return path;
		index++;
	}
	return @"";
}

- (id) init {
	if ((self = [super init])) {
		self.privateQueue = [[NSOperationQueue alloc] init];
		self.privateQueue.maxConcurrentOperationCount = 1;
		
		if (self.logAllConnections) {
			NSError							*error = nil;
			NSFileManager					*mgr = [NSFileManager defaultManager];
			
			[mgr removeItemAtPath: [SA_ConnectionQueue logDirectoryPath] error: &error];
			[mgr createDirectoryAtPath: [SA_ConnectionQueue logDirectoryPath] withIntermediateDirectories: YES attributes: nil error: &error];
				
			NSError							*dirError = nil;
			[[NSFileManager defaultManager] createDirectoryAtPath: [@"~/Library/Downloads/" stringByExpandingTildeInPath] withIntermediateDirectories: YES attributes: nil error: &dirError];
		}
		self.router = self;
		self.pending = @[];
		self.active = [NSSet set];
		self.pleaseWaitConnections = [SA_ThreadsafeMutableArray new];
		self.headers = [SA_ThreadsafeMutableDictionary new];
		_defaultPriorityLevel = 5;
		_minimumIndicatedPriorityLevel = 5;
		self.fileSwitchOverLimit = 1024 * 20;			//switch to a file after 20k has been downloaded
		self.managePleaseWaitDisplay = YES;
		
		_connectionSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey: @"priority" ascending: YES], [NSSortDescriptor sortDescriptorWithKey: @"order" ascending: YES]];
		[self performSelector: @selector(determineConnectionLevelAvailable) withObject: nil afterDelay: 0.0];			//defer this call so as not to slow down the startup procedure
		
		#if TARGET_OS_IPHONE
			self.backgroundTaskID = UIBackgroundTaskInvalid;
			[self addAsObserverForName: UIApplicationWillEnterForegroundNotification selector: @selector(applicationWillEnterForeground:)];
		#endif
		
		#if !TARGET_OS_IPHONE
			self.backgroundQueue = dispatch_queue_create("SA_ConnectionBackgroundQueue", 0);
		#endif
	}
	return self;
}

//=============================================================================================================================
#pragma mark Notifications
- (void) applicationWillEnterForeground: (NSNotification *) note {
	[self performSelector: @selector(determineConnectionLevelAvailable) withObject: nil afterDelay: 0.0];			//defer this call so as not to slow down the startup procedure
	[self fireReachabilityStatus];
}

//=============================================================================================================================
#pragma mark Actions
- (BOOL) queueConnection: (SA_Connection *) connection {
	if (self.offline || connection == nil) return NO;
	
	[self.privateQueue addOperationWithBlock: ^{
		if (connection.ignoreLater) {
			[self isExistingConnectionSimilar: connection completion: ^(BOOL similar) {
				if (!similar) {
					connection.ignoreLater = YES;
					[self queueConnection: connection];
				}
			}];
			return;
		} else if (connection.replaceOlder) {
			[self removeConnectionsTaggedWith: connection.tag delegate: connection.delegate];
			connection.replaceOlder = NO;
			[self queueConnection: connection];
			return;
		}
		
		[self.privateQueue addOperationWithBlock: ^{
			SA_Assert(!connection.alreadyStarted, @"Can't queue an already started connection");

			self.pending = [self.pending arrayByAddingObject: connection];
			connection.order = self.pending.count;

			[self reorderPendingConnectionsByPriority];
			if (self.managePleaseWaitDisplay && connection.showsPleaseWait) {
				[self.pleaseWaitConnections addObject: connection];
			}
			
			#if TARGET_OS_IPHONE
				if (self.managePleaseWaitDisplay && connection.priority >= _minimumIndicatedPriorityLevel && self.showProgressInPleaseWaitDisplay) self.highwaterMark++;
			#endif
			
			[self deferQueueProcessing];
			if (self.managePleaseWaitDisplay) [self updatePleaseWaitDisplay];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_Queued object: connection];
		}];
	}];
	return YES;
}

- (void) resetOfflineAlerts {
	self.offlineAlertShown = NO;
}

- (void) attempToGoOnline {
	if (!self.offline) return;
	
	[self fireReachabilityStatus];
}

- (void) showOfflineAlertAllowingRetry: (BOOL) allowingRetry {
	#if TARGET_OS_IPHONE
		NSString		*title = NSLocalizedString(@"Connection Error", @"Connection Error");
		NSString		*body = NSLocalizedString(@"Unable to connect. Please try again later.", @"Unable to connect. Please try again later.");
	
		[SA_AlertView showAlertWithTitle: title message: body buttons: @[ NSLocalizedString(@"Cancel", @"Cancel back online"), NSLocalizedString(@"Retry", @"Retry online") ] buttonBlock: ^(NSInteger buttonIndex) {

			if (buttonIndex != 0) {
				self.offline = NO;
				[self resetOfflineAlerts];
			}
		}];
	#endif
	
	self.offlineAlertShown = YES;
}

- (BOOL) queueConnection: (SA_Connection *) connection andPromptIfOffline: (BOOL) prompt {
	if (connection && [self queueConnection: connection]) return YES;
	
	if (connection.discardIfOffline) [connection cancel: NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_NotConnectedToInternet object: self];
	if (self.offlineAlertShown || self.suppressOfflineAlerts) return NO;
	if (prompt) [self showOfflineAlertAllowingRetry: !connection.discardIfOffline];
	return NO;
}

- (void) reorderPendingConnectionsByPriority {
	[self.privateQueue addOperationWithBlock:^{
		if (self.pending.count > 1) self.pending = [self.pending sortedArrayUsingDescriptors: _connectionSortDescriptors];
	}];
}

- (void) setPaused: (BOOL) paused {
	if (paused == _paused) return;
	
	_paused = paused;
	if (!paused) [self deferQueueProcessing];
}

- (void) deferQueueProcessing {
	[self.privateQueue addOperationWithBlock: ^{ [self processQueue]; }];
}

- (void) processQueue {
	[self.privateQueue addOperationWithBlock:^{
		[self.queueProcessingTimer invalidate];
        #if !TARGET_OS_MAC
			if (self.active.count == 0 && self.pending.count == 0 && self.backgroundTaskID == UIBackgroundTaskInvalid) return;
			if (self.active.count == 0 && self.backgroundTaskID == UIBackgroundTaskInvalid) {
				self.backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
					if (self.backgroundTaskID != UIBackgroundTaskInvalid) {
						dispatch_async_main_queue(^{
							if (self.backgroundTaskID != UIBackgroundTaskInvalid) {
								SA_BASE_LOG(@"Expiring background task (forced)");
								[[UIApplication sharedApplication] endBackgroundTask: self.backgroundTaskID];
								self.backgroundTaskID = UIBackgroundTaskInvalid;
							}
						});
					}
				}];
			}
		#endif
		
		while (!self.offline && !self.paused && self.active.count < self.maxSimultaneousConnections && self.pending.count) {
			SA_Connection				*connection = self.pending[0];
			
			SA_Assert(!connection.alreadyStarted, @"Somehow a previously started connection is in the pending list: %@", connection);
			for (NSString *key in self.headers) {[connection addHeader: self.headers[key] label: key];}
			if ([connection start]) {
				self.activityIndicatorCount++;
				self.active = [self.active setByAddingObject: connection];
			} else {
				SA_BASE_LOG(@"Connection failed to start: %@", connection);
				[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionFailedToStart object: connection];
			}
			self.pending = [self.pending SA_arrayByRemovingObject: connection];
		}

		if (self.active.count == 0 && !_paused) {
			if (self.pending.count == 0) {
				self.highwaterMark = 0;
				[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_AllConnectionsCompleted object: self];
			}
            #if !TARGET_OS_MAC
				if (self.backgroundTaskID != UIBackgroundTaskInvalid) {
					dispatch_async_main_queue(^{
						if (self.backgroundTaskID != UIBackgroundTaskInvalid && self.active.count == 0) {
							[[UIApplication sharedApplication] endBackgroundTask: self.backgroundTaskID];
							self.backgroundTaskID = UIBackgroundTaskInvalid;
						}
					});
				}
			#endif
		}
		
		if (self.managePleaseWaitDisplay) [self updatePleaseWaitDisplay];
	}];
}

- (void) addHeader: (NSString *) header label: (NSString *) label { self.headers[label] = header; }
- (void) removeHeader: (NSString *) label { [self.headers removeObjectForKey: label]; }
- (void) removeAllHeaders { [self.headers removeAllObjects]; }


- (void) removeConnectionsTaggedWith: (NSString *) tag { [self removeConnectionsTaggedWith: tag delegate: nil]; }
- (void) removeConnectionsWithDelegate: (id) delegate { [self removeConnectionsTaggedWith: nil delegate: delegate]; }
- (void) removeConnectionsTaggedWith: (NSString *) tag delegate: (id) delegate {
	[self.privateQueue addOperationWithBlock:^{
		for (SA_Connection *connection in self.active) {
			if ((tag == nil || [connection.tag rangeOfString: tag].location != NSNotFound) && (delegate == nil || connection.delegate == delegate)) {
				[connection cancel: YES];
				self.activityIndicatorCount--;
			}
		}
		
		for (SA_Connection *connection in self.pending) {
			if ((tag == nil || [connection.tag rangeOfString: tag].location != NSNotFound) && (delegate == nil || connection.delegate == delegate)) {
				[connection cancel: YES];
			}
		}

		[self deferQueueProcessing];
	}];

}

- (void) cancelAllConnections { [self removeConnectionsTaggedWith: nil delegate: nil]; }

- (void) isExistingConnectionSimilar: (SA_Connection *) targetConnection completion: (booleanArgumentBlock) completion {
	if (targetConnection.tag || targetConnection.delegate) {
		[self isExistingConnectionTaggedWith: targetConnection.tag delegate: targetConnection.delegate completion: completion];
		return;
	}

	[self.privateQueue addOperationWithBlock: ^{
		NSSet				*checkSet = [self.active setByAddingObjectsFromArray: self.pending];
		
		for (SA_Connection *connection in checkSet) {
			if (!connection.canceled && [targetConnection.url isEqual: connection.url]) {
				completion(YES);
				return;
			}
		}
		completion(NO);
	}];
}

- (void) isExistingConnectionTaggedWith: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate completion: (booleanArgumentBlock) completion {
	[self findExistingConnectionsTaggedWith: tag delegate: delegate completion:^(SA_Connection *found) {
		completion(found != nil);
	}];
}

- (void) findExistingConnectionsTaggedWith: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate completion: (SA_ConnectionBlock) completion {
	[self.privateQueue addOperationWithBlock: ^{
		NSMutableSet		*checkSet = self.active.mutableCopy ?: [NSMutableSet new];
		
		if (self.pending.count) [checkSet addObjectsFromArray: self.pending];

		for (SA_Connection *connection in checkSet) {
			if ((tag == nil && connection.tag != nil) || (tag != nil && connection.tag == nil)) continue;
			if (tag && [connection.tag rangeOfString: tag].location == NSNotFound) continue;
			
			if ((delegate == nil && connection.delegate == nil) || delegate == connection.delegate) {
				completion(connection);
				return;
			}
		}
		completion(nil);
	}];
}

- (void) resetHighwaterMark { self.highwaterMark = 0; }

//=============================================================================================================================
#pragma mark Properties
- (BOOL) offline { return _offline; }
- (void) setOffline: (BOOL) offline {
	if (offline == _offline) return;
	
	_offline = offline;

	if (_offline) {				//need too cancel all active connections
		[self.privateQueue addOperationWithBlock: ^{
			for (SA_Connection *connection in self.active) {
				SA_Assert(!connection.alreadyStarted, @"There was an unstarted connection in the active list: %@", connection);
				[connection reset];
				self.activityIndicatorCount--;
				if (![self.pending containsObject: connection]) self.pending = [self.pending arrayByAddingObject: connection];
			}

			if (self.managePleaseWaitDisplay) {
				[self.pleaseWaitConnections removeAllObjects];
				[self updatePleaseWaitDisplay];
			}

			self.active = [NSSet set];
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_NotConnectedToInternet object: self];
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionStateChanged object: @(!offline)];
		}];

	} else {
		self.offlineAlertShown = NO;
		[self deferQueueProcessing];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionStateChanged object: @(!offline)];
	}
	if (!self.offline)[[SA_ConnectionQueue sharedQueue] resetOfflineAlerts];
}

- (NSUInteger) maxSimultaneousConnections {
	if (_maxSimultaneousConnections) return _maxSimultaneousConnections;
	return _wifiAvailable ? 7 : 3;	
}

- (void) setMaxSimultaneousConnections: (NSUInteger) max { _maxSimultaneousConnections = max; }
- (BOOL) connectionsArePending {
	__block BOOL			pending = NO;
	[self.privateQueue addOperations: @[ [NSBlockOperation blockOperationWithBlock: ^{
		pending = (self.pending.count > 0 || self.active.count > 0);
	}] ] waitUntilFinished: YES];
	return pending;
}

- (NSUInteger) connectionCount {
	__block NSUInteger			count = 0;
	
	[self.privateQueue addOperations: @[ [NSBlockOperation blockOperationWithBlock: ^{
		count = self.active.count + self.pending.count;
	}] ] waitUntilFinished: YES];
	return count;
}

//=============================================================================================================================
#pragma mark Activity Indicator
- (void) setActivityIndicatorCount: (NSInteger) activityIndicatorCount {
	_activityIndicatorCount = activityIndicatorCount;
	
	if (_activityIndicatorCount <= 0) {
		dispatch_async_main_queue(^{
			[[SA_ConnectionQueue sharedQueue] performSelector: @selector(hideActivityIndicator) withObject: nil afterDelay: 0.05];
		});
	} else {
		IF_IOS([UIApplication sharedApplication].networkActivityIndicatorVisible = YES);
	}
}

- (NSInteger) activityIndicatorCount { return _activityIndicatorCount; }

- (void) hideActivityIndicator {
	IF_IOS(
		   if (self.activityIndicatorCount <= 0) [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		   );
}

//=============================================================================================================================
#pragma mark Callbacks
- (void) dequeueConnection: (SA_Connection *) connection {
	
	[self.privateQueue addOperationWithBlock:^{
		if ([self.active containsObject: connection]) {
			self.activityIndicatorCount--;
			self.active = [self.active sa_setByRemovingObject: connection];
		}
		if (self.managePleaseWaitDisplay) [self.pleaseWaitConnections removeObject: connection];
		self.pending = [self.pending SA_arrayByRemovingObject: connection];

		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_Dequeued object: connection];
		[self deferQueueProcessing];
	}];
}

- (void) connectionFailed: (SA_Connection *) connection withError: (NSError *) error {
	if (error.isNoInternetConnectionError) {					//if we're not connected, then we'll stop all future connections, and save this one
		[connection reset];

		if (!self.offline) {
			self.offline = YES;
	
			SA_BASE_LOG(@"Tried to push connection: %@, but not connected to the internet", connection);
			if (!connection.suppressConnectionAlerts) [self queueConnection: nil andPromptIfOffline: YES];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_NotConnectedToInternet object: self];
		}
	}
	[self dequeueConnection: connection];
}

#if TARGET_OS_IPHONE
	- (void) hidePleaseWaitDisplay {
		if (!self.managePleaseWaitDisplay) return;
		NSInteger					remaining = [self remainingConnectionsAboveMinimum];
		
		if (remaining == 0) {
			[SA_PleaseWaitDisplay hidePleaseWaitDisplay];
		} else
			[SA_PleaseWaitDisplay pleaseWaitDisplay].progressValue = (self.highwaterMark - remaining) / self.highwaterMark;
	}
#endif

- (void) incrementBytesDownloaded: (long long) byteCount {
	[self.privateQueue addOperationWithBlock:^{
		_bytesDownloaded += byteCount;
	}];
}

- (void) resetBytesDownloaded {
	[self.privateQueue addOperationWithBlock:^{
		_bytesDownloaded = 0;
	}];
}

//=============================================================================================================================
#pragma mark Please Wait Support
- (void) updatePleaseWaitDisplay {
#if TARGET_OS_IPHONE
	SA_Connection					*topConnection = nil;						//look for the first conenction whose delegate implements pleaseWaitMajorStringForConnection:
	
	if (_suppressPleaseWaitDisplay || self.managePleaseWaitDisplay) return;
	
	if (self.offline || (!self.shouldPleaseWaitBeVisible && self.managePleaseWaitDisplay)) {					//no pending connections, we're done
		[SA_PleaseWaitDisplay hidePleaseWaitDisplay];
		return;
	}
	 for (SA_Connection *connection in self.pleaseWaitConnections) {
		 if ([connection.delegate respondsToSelector: @selector(pleaseWaitMajorStringForConnection:)]) {
			 topConnection = connection;
			 break;
		 }
	 } 
	 
	if (topConnection == self.currentTopPleaseWaitConnection) return;				//no change
	 
	self.currentTopPleaseWaitConnection = topConnection;
	
	NSString							*majorText = [topConnection.delegate respondsToSelector: @selector(pleaseWaitMajorStringForConnection:)] ? [topConnection.delegate pleaseWaitMajorStringForConnection: topConnection] : NSLocalizedString(@"Please Wait…", @"Please Wait…");
	NSString							*minorText = [topConnection.delegate respondsToSelector: @selector(pleaseWaitMinorStringForConnection:)] ? [topConnection.delegate pleaseWaitMinorStringForConnection: topConnection] : NSLocalizedString(@"Please Wait…", @"Please Wait…");
	BOOL								canCancel = [topConnection.delegate conformsToProtocol: @protocol(SA_PleaseWaitDisplayDelegate)];
	BOOL								showProgress = [topConnection.delegate respondsToSelector: @selector(pleaseWaitShowProgressValueForConnection:)] ? [topConnection.delegate pleaseWaitShowProgressValueForConnection: topConnection] : NO;
	
	 
	[SA_PleaseWaitDisplay showPleaseWaitDisplayWithMajorText: majorText minorText: minorText cancelLabel: canCancel ? NSLocalizedString(@"Cancel", @"Cancel") : nil showProgressBar: showProgress delegate: canCancel ? (id <SA_PleaseWaitDisplayDelegate>) topConnection.delegate : nil];
#endif
}

- (void) setSuppressPleaseWaitDisplay: (BOOL) set {
	if (set) {
		if (_suppressPleaseWaitDisplay) return;
		_suppressPleaseWaitDisplay = YES;
		#if TARGET_OS_IPHONE
			[SA_PleaseWaitDisplay hidePleaseWaitDisplay];
		#endif
		self.currentTopPleaseWaitConnection = nil;
	} else {
		if (!_suppressPleaseWaitDisplay) return;
		_suppressPleaseWaitDisplay = NO;
		[self updatePleaseWaitDisplay];
	}
}

- (BOOL) shouldPleaseWaitBeVisible {
	return self.pleaseWaitConnections.count > 0;
}

- (BOOL) shouldProcessSuccessfulConnection: (SA_Connection *) connection { return YES; }
- (BOOL) shouldProcessFailedConnection: (SA_Connection *) connection { return YES; }

//=============================================================================================================================
#pragma mark Reachability
void ReachabilityChanged(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

- (void) fireReachabilityStatus {
	SCNetworkReachabilityFlags				flags;
	
	if (self.reachabilityRef == NULL) return;
	if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
		ReachabilityChanged(self.reachabilityRef, flags, NULL);
	} else {
		SA_BASE_LOG(@"SCNetworkReachabilityGetFlags failed");
		#if TARGET_OS_IPHONE
			if (SA_Base_DebugMode()) [SA_AlertView showAlertWithTitle: @"SCNetworkReachabilityGetFlags failed" message: @"Failed to update connection status"];
		#endif
	}
}

void ReachabilityChanged(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info) {
	IF_IOS([SA_ConnectionQueue sharedQueue]->_wlanAvailable = (flags & kSCNetworkReachabilityFlagsIsWWAN) != 0);
	[SA_ConnectionQueue sharedQueue]->_wifiAvailable = ![SA_ConnectionQueue sharedQueue]->_wlanAvailable && ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
	
	#if TARGET_IPHONE_SIMULATOR
		[SA_ConnectionQueue sharedQueue]->_wifiAvailable = (flags & (kSCNetworkReachabilityFlagsIsLocalAddress | kSCNetworkReachabilityFlagsReachable)) > 0;
	#endif
	
	[SA_ConnectionQueue sharedQueue].offline = (![SA_ConnectionQueue sharedQueue]->_wlanAvailable && ![SA_ConnectionQueue sharedQueue]->_wifiAvailable);
    
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionReachabilityChanged object:[SA_ConnectionQueue sharedQueue]];
}

- (void) determineConnectionLevelAvailable {
	if (self.reachabilityRef == NULL) {
		struct sockaddr_in							address = {};
		
		memset(&address, sizeof(struct sockaddr_in), 0);
		address.sin_family = AF_INET;
		address.sin_len = sizeof(struct sockaddr_in);
		
		inet_aton("0.0.0.0", &address.sin_addr);
		self.reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (struct sockaddr *) &address);
		
		if (self.reachabilityRef && SCNetworkReachabilitySetCallback(self.reachabilityRef, ReachabilityChanged, nil)) {
			SCNetworkReachabilityScheduleWithRunLoop(self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
			[self fireReachabilityStatus];
		} else if (self.reachabilityRef == nil) {
			SA_BASE_LOG(@"Failed to create a ReachabilityRef");
			#if TARGET_OS_IPHONE
				if (SA_Base_DebugMode()) [SA_AlertView showAlertWithTitle: @"Failed to create a ReachabilityRef" message: @"Unable to track connection status"];
			#endif
		}
	} else {
		[self fireReachabilityStatus];
	}
}

//=============================================================================================================================
#pragma mark Misc
- (NSInteger) remainingConnectionsAboveMinimum {
	__block NSInteger				count = 0;
	
	[self.privateQueue addOperations: @[ [NSBlockOperation blockOperationWithBlock:^{
		for (SA_Connection *connection in self.active) { if (connection.priority >= _minimumIndicatedPriorityLevel) count++; }
		for (SA_Connection *connection in self.pending) { if (connection.priority >= _minimumIndicatedPriorityLevel) count++; }
	}] ] waitUntilFinished: YES];
	
	return count;
}

- (NSString *) description {
	__block NSMutableString				*results = [NSMutableString string];
	
	[self.privateQueue addOperations: @[ [NSBlockOperation blockOperationWithBlock: ^{
		[results appendFormat: @"\nActive (%ld):\n", (long) self.active.count];
		for (SA_Connection *connection in self.active) {
			[results appendFormat: @"\t\t%@\n", connection];
		}
		
		if (self.active.count && self.pending.count) [results appendString: @"\n"];
		[results appendFormat: @"Pending (%ld):\n", (long) self.pending.count];
		for (SA_Connection *connection in self.pending) {
			[results appendFormat: @"\t\t%@\n", connection];
		}
	}] ] waitUntilFinished: YES];
	
	return results;
}


@end






//=============================================================================================================================
#pragma mark SA_Connection

@implementation SA_Connection
@synthesize tag = _tag, priority = _priority;
@synthesize order = _order, file = _file, filename = _filename, allResponseHeaders = _responseHeaders, statusCode = _statusCode;
@synthesize replaceOlder = _replaceOlder, ignoreLater = _ignoreLater, showsPleaseWait = _showsPleaseWait, resumable = _resumable, completeInBackground = _completeInBackground, prefersFileStorage = _prefersFileStorage;
@synthesize suppressConnectionAlerts = _suppressConnectionAlerts, canceled = _canceled, inProgress = _inProgress, request = _request;
@synthesize allowRepeatedKeys = _allowRepeatedKeys, discardIfOffline = _discardIfOffline, connectionFinishedBlock = _connectionFinishedBlock, timeoutInterval = _timeoutInterval;

@synthesize requestStartedAt = _requestStartedAt, responseReceivedAt = _responseReceivedAt, finishedLoadingAt = _finishedLoadingAt;

+ (id) connectionWithURL: (NSURL *) url completionBlock: (connectionFinished) completionBlock {
	SA_Connection		*connection = [[self alloc] initWithURL: url payload: nil method: @"GET" priority: [SA_ConnectionQueue sharedQueue].defaultPriorityLevel tag: nil delegate: nil];
	
	connection.connectionFinishedBlock = (completionBlock);
	return connection;
}

+ (id) connectionWithURLRequest: (NSURLRequest *) request completionBlock: (connectionFinished) completionBlock {
	SA_Connection		*connection = [[self alloc] initWithURL: request.URL payload: nil method: @"GET" priority: [SA_ConnectionQueue sharedQueue].defaultPriorityLevel tag: nil delegate: nil];
	
	connection.request = request;
	connection.method = request.HTTPMethod;
	connection.payload = request.HTTPBody;
	connection.connectionFinishedBlock = (completionBlock);
	return connection;
}

+ (id) connectionWithURL: (NSURL *) url payload: (NSData *) payload method: (NSString *) method priority: (NSInteger) priority completionBlock: (connectionFinished) completionBlock {
	SA_Connection		*connection = [[self alloc] initWithURL: url payload: payload method: method priority: priority tag: nil delegate: nil];
	
	connection.connectionFinishedBlock = (completionBlock);
	return connection;
}

+ (SA_Connection *) downloadURL: (NSURL *) url withCompletionBlock: (connectionFinished) completionBlock {
	SA_Connection			*connection = [self connectionWithURL: url payload: nil method: @"GET" priority: 5 completionBlock: completionBlock];
	
	[[SA_ConnectionQueue sharedQueue] performSelector: @selector(queueConnection:) withObject: connection afterDelay: 0.0];
	return connection;
}

+ (SA_Connection *) downloadURLRequest: (NSURLRequest *) urlRequest withCompletionBlock: (connectionFinished) completionBlock {
	SA_Connection			*connection = [self connectionWithURLRequest: urlRequest completionBlock: completionBlock];
	
	[[SA_ConnectionQueue sharedQueue] performSelector: @selector(queueConnection:) withObject: connection afterDelay: 0.0];
	return connection;
}

+ (id) connectionWithURL: (NSURL *) url tag: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate {
	return [[self alloc] initWithURL: url payload: nil method: @"GET" priority: [SA_ConnectionQueue sharedQueue].defaultPriorityLevel tag: tag delegate: delegate];
}

+ (id) connectionWithURL: (NSURL *) url payload: (NSData *) payload method: (NSString *) method priority: (NSInteger) priority tag: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate {
	return [[self alloc] initWithURL: url payload: payload method: method priority: priority tag: tag delegate: delegate];
}

- (id) initWithURL: (NSURL *) url payload: (NSData *) payload method: (NSString *) method priority: (NSInteger) priority tag: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate {
	SA_Assert(url != nil, @"Cannot initWithURL an SA_Connection with a nil URL");
	if ((self = [super init])) {
		self.payload = payload;
		self.method = method;
		self.priority = priority;
		self.url = url;
		self.tag = tag;
		self.delegate = delegate;
	}
	return self;
}

- (BOOL) completed {
	return _statusCode != 0;
}

- (id) copyWithZone: (NSZone *) ignored {
	SA_Connection					*connection = [[[self class] alloc] init];
	
	connection.url = self.url;
	connection.payload = self.payload;
	connection.priority = self.priority;
	connection.tag = self.tag;
	connection.delegate = self.delegate;
	connection.method = self.method;
	connection.sentCookies = self.sentCookies.copy;
	connection.connectionHeaders = [self.connectionHeaders mutableCopy];
	
	return connection;
}

- (void) removeHeader: (NSString *) label {
	[self.connectionHeaders removeObjectForKey: label];
}

- (void) addHeader: (NSString *) header label: (NSString *) label {
	if (self.connectionHeaders == nil) self.connectionHeaders = [[NSMutableDictionary alloc] init];
	
	if (self.connectionHeaders[label]) {
		NSArray				*components = [self.connectionHeaders[label] componentsSeparatedByString: @";"];
		
		if ([components containsObject: header]) return;
		header = [NSString stringWithFormat: @"%@;%@", header, self.connectionHeaders[label]];
	} 
	self.connectionHeaders[label] = header;
}

- (void) setPayload: (NSData *) payload {
	if (_payload != payload) {
		_payload = payload;
	}
	
	if (payload && (self.method == nil || [self.method isEqual: @"GET"])) self.method = @"POST";
}

- (NSComparisonResult) comparePriorities: (SA_Connection *) other {
	return self.priority - other.priority;
}

- (NSURLRequest *) generatedRequest {
	NSMutableURLRequest				*request = 	[NSMutableURLRequest requestWithURL: self.url];

	if (self.timeoutInterval) request.timeoutInterval = self.timeoutInterval;
	if (self.method) [request setHTTPMethod: self.method];
	if (self.payload) [request setHTTPBody: self.payload];
	if (self.disableNativeCookieHandling) [request setHTTPShouldHandleCookies: NO];
	
	NSDictionary			*headers = [self generatedHeaders];
	if (headers) [request setAllHTTPHeaderFields: headers];

	return request;
}



- (BOOL) start {
	SA_Assert(self.url != nil, @"Cannot start an SA_Connection with a nil URL");
	SA_Assert(!self.alreadyStarted, @"Can't restart an already used connection.");
	
	if ([self.method isEqual: @"GET"] && self.payload.length) SA_BASE_LOG(@"Attaching a Payload to a GET request will probably fail \n\n %@", self);
	
	if (self.request == nil) self.request = [self generatedRequest];
	
	
	_inProgress = YES;
	_canceled = NO;
	if (self.request == nil) return NO;			//bad URL
	
	if (self.prefersFileStorage) {
		[self switchToFileStorage];
		if (self.resumable) {
			NSUInteger						offset = [_file seekToEndOfFile];
			
			if (offset) {
				if (self.connectionHeaders == nil) self.connectionHeaders = [[NSMutableDictionary alloc] init];
				[self.connectionHeaders setObject: [NSString stringWithFormat: @" bytes=%lu-", (unsigned long)offset] forKey: @"Range"];
			}
		}
	} else
		self.mutableData = [[NSMutableData alloc] init];
	
	
	if ([_delegate respondsToSelector: @selector(connectionWillBegin:)]) [_delegate connectionWillBegin: self];
	
	self.connection = [[NSURLConnection alloc] initWithRequest: self.request delegate: self startImmediately: NO];
	
	[self.connection setDelegateQueue: [SA_ConnectionQueue sharedQueue].privateQueue];
	[self.connection start];
	
	self.requestStartedAt = [NSDate date];
	
	if (self.logPhases) SA_BASE_LOG(@"%@: <%@>", @"Started", self);

	if (self.connection)
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionStarted object: self];
	else
		SA_BASE_LOG(@"Error while starting connection: %@", self);
	
	return (self.connection != nil);
}

//=============================================================================================================================
#pragma mark Ending connections
- (void) cancel: (BOOL) clearDelegate {
	__strong SA_Connection		*strongSelf = self;
	if (self.logPhases) SA_BASE_LOG(@"%@: <%@>", @"Cancelled", self.url)
	
	if ([_delegate respondsToSelector: @selector(connectionCancelled:)]) [_delegate connectionCancelled: strongSelf];
	if (clearDelegate) strongSelf.delegate = nil;
	if (_canceled) return;

	[[SA_ConnectionQueue sharedQueue] dequeueConnection: strongSelf];

	[self.connection cancel];
	_canceled = YES;
	[strongSelf reset];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionCancelled object: strongSelf];
}

- (void) cancelIfNotInProgress: (BOOL) clearDelegate {
	if (!_inProgress) 
		[self cancel: clearDelegate];
	else if (clearDelegate) self.delegate = nil;
}

- (BOOL) alreadyStarted {
	return self.mutableData != nil || self.connection != nil;
}
- (void) reset {
	_statusCode = 0;
	self.mutableData = nil;
	[self.connection cancel];
	self.connection = nil;
	_file = nil;
	_filename = nil;
}

- (NSURLRequest *) connection: (NSURLConnection *) connection willSendRequest: (NSURLRequest *) request redirectResponse: (NSURLResponse *) redirectResponse {
	NSMutableURLRequest				*newRequest = request.mutableCopy;
	
	if (self.method) [newRequest setHTTPMethod: self.method];
	if (self.payload) [newRequest setHTTPBody: self.payload];
	if (self.disableNativeCookieHandling) [newRequest setHTTPShouldHandleCookies: NO];
	
	NSDictionary			*headers = [self generatedHeaders];
	if (headers) [newRequest setAllHTTPHeaderFields: headers];
	
//	if ([_delegate respondsToSelector: @selector(connectionWillBegin:)]) [_delegate connectionWillBegin: self];
	return newRequest;
}

- (NSDictionary *) generatedHeaders {
	if (self.sentCookies.count == 0) return self.connectionHeaders;
	
	NSMutableDictionary				*headers = self.connectionHeaders.mutableCopy;
	
	headers[@"Cookie"] = [self.sentCookies componentsJoinedByString: @","];
	return headers;
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error {
	_inProgress = NO;
	if (self.logPhases) SA_BASE_LOG(@"Failed (%@): <%@>", error, self.url)
	if (SA_Base_DebugMode()) self.finishedLoadingAt = [NSDate date];SA_BASE_LOG(@"Connection %@ failed: %@", self, error.isNoInternetConnectionError ? @"NO CONNECTION" : (id) error);
	
	if (_canceled) return;

	if (self.connectionFinishedBlock) {
		self.connectionFinishedBlock(self, self.statusCode, error);
	} else if ([_delegate respondsToSelector: @selector(connectionFailed:withError:)]) 
		[_delegate connectionFailed: self withError: error];
	
	[[SA_ConnectionQueue sharedQueue] connectionFailed: self withError: error];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionFailed object: self];
	self.connection = nil;
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection {
	_inProgress = NO;

	self.finishedLoadingAt = [NSDate date];
	if (_canceled) return;

	if (self.logPhases) SA_BASE_LOG(@"Completed: <%@>", self.url)
	
	if ([SA_ConnectionQueue sharedQueue].logAllConnections) {
		[[self downloadedDataStream] writeToFile: [SA_ConnectionQueue nextPrefixed: @"download" pathForTag: self.tag] atomically: YES];
	}
	
	if (_file) [_file closeFile];
	
	[[SA_ConnectionQueue sharedQueue] dequeueConnection: self];			//dequeue the connection, and start the queue working on the next one, then we handle this one's data
	self.connection = nil;
	
	if (![[SA_ConnectionQueue sharedQueue].router shouldProcessSuccessfulConnection: self]) return;
	
	BOOL					dontProcessFailedStatusCodes = [SA_ConnectionQueue sharedQueue].dontProcessFailedStatusCodes;

	if (self.prefersFileStorage) 
		[self switchToFileStorage];
	else if (self.mutableData == nil && _file)
		self.mutableData = [NSMutableData dataWithContentsOfFile: _filename];
	

	if (self.connectionFinishedBlock) dontProcessFailedStatusCodes = NO;
	
	if (HTTP_STATUS_CODE_IS_ERROR(_statusCode)) {										//some sort of failure
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionReturnedBadStatus object: self];
		if (dontProcessFailedStatusCodes) {
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionFailed object: self];
			return;
		}
	}

	if (self.connectionFinishedBlock) {
		self.connectionFinishedBlock(self, self.statusCode, nil);
	} else if (self.completeInBackground) {
		if ([SA_ConnectionQueue sharedQueue].backgroundQueue) {
			dispatch_async([SA_ConnectionQueue sharedQueue].backgroundQueue,  ^{
				if ([_delegate respondsToSelector: @selector(connectionDidFinish:)]) [_delegate connectionDidFinish: self];
				
				[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionFinished object: self];
			});
		}
	} else {
		if ([_delegate respondsToSelector: @selector(connectionDidFinish:)]) [_delegate connectionDidFinish: self];
	} 
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionFinished object: self];
}

- (void) backgroundConnectionDidFinish {
	@autoreleasepool {
		if ([_delegate respondsToSelector: @selector(connectionDidFinish:)]) [_delegate connectionDidFinish: self];

		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionFinished object: self];
	}
}


//=============================================================================================================================
#pragma mark Security Callbacks
#if ALLOW_UNTRUSTED_CERTS
//#define this to allow untrusted and self-signed https certs
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	//	if ([trustedHosts containsObject:challenge.protectionSpace.host])
			[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
} 
#endif

//=============================================================================================================================
#pragma mark Other callbacks
- (void) connection: (NSURLConnection *) connection didReceiveResponse: (NSURLResponse *) response {

	//SA_BASE_LOG(@"Request Response Time: %@, Start Time: %@", [NSDate date], [NSDate dateWithTimeIntervalSinceReferenceDate: _requestStart]);
	self.responseReceivedAt = [NSDate date];
	
	if (self.logPhases) SA_BASE_LOG(@"Received Response (%@): <%@>", response, self.url)

	if (_file == nil && [SA_ConnectionQueue sharedQueue].fileSwitchOverLimit && [response expectedContentLength] > [SA_ConnectionQueue sharedQueue].fileSwitchOverLimit) {
		[self switchToFileStorage]; 
	}
	
	if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
		_responseHeaders = [(id) response allHeaderFields];
		_statusCode = [(NSHTTPURLResponse *) response statusCode];
		
		if (HTTP_STATUS_CODE_IS_ERROR(_statusCode)) {
//			if ([_delegate respondsToSelector: @selector(connectionFailed:withStatusCode:)] && ![_delegate connectionFailed: self withStatusCode: _statusCode]) {
//				 [self cancel: YES];
//			} 
			if ([SA_ConnectionQueue sharedQueue].dontProcessFailedStatusCodes && [_delegate respondsToSelector: @selector(connectionFailed:withError:)]) {
				[_delegate connectionFailed: self withError: [NSError errorWithDomain: SA_BaseErrorDomain code: sa_base_error_connection_failed userInfo: @{ @"statusCode": @(_statusCode)} ]];
			}
		}  else {
			NSString			*cookieString = _responseHeaders[@"Set-Cookie"];
			if (cookieString) self.receivedCookies = [cookieString componentsSeparatedByString: @","];
		}
	}
}

- (void) connection: (NSURLConnection *) connection didReceiveData: (NSData *) data {
	if (self.logPhases) SA_BASE_LOG(@"Received Data (%d): <%@>", (uint32_t) data.length, self.url)
	if (_canceled) return;
	if (_file)
		[_file writeData: data];
	else
		[self.mutableData appendData: data];
	
	[[SA_ConnectionQueue sharedQueue] incrementBytesDownloaded: data.length];
}



- (NSString *) description {
	return $S(@"[%@]", self.url);
}

- (NSString *) debugDescription {
	NSMutableString				*desc = [NSMutableString stringWithFormat: @"<0x%x>%@", (UInt16) self, NSStringFromClass([self class])];
	if (self.tag) [desc appendFormat: @", tag: %@", self.tag];
	[desc appendFormat: @", Pri: %ld", (long)_priority];
	if (self.delegate) [desc appendFormat: @", delegate: <0x%@> %@", self.delegate, NSStringFromClass([self.delegate class])];
	
	[desc appendFormat: @"\nHeaders:\n"];
	NSMutableDictionary			*headers = [NSMutableDictionary dictionaryWithDictionary: self.connectionHeaders ?: @{}];
	for (NSString *header in self.request.allHTTPHeaderFields) { headers[header] = self.request.allHTTPHeaderFields[header]; }
	
	for (NSString *field in headers) {
		[desc appendFormat: @"\t%@:\t\t\t%@\n", field, [headers valueForKey: field]];
	}
	[desc appendFormat: @"URL:\t\t\t%@\nMethod:\t\t\t%@\n", self.url, self.method];
	if (self.payload.length) [desc appendFormat: @"Payload:\n%@\n", self.payloadString];

	if (self.mutableData.length) [desc appendFormat: @"\nResult (%ld): \n", (long)self.statusCode];
	
	[desc appendFormat: @"\nResponse Headers:\n"];
	for (NSString *field in _responseHeaders) {
		[desc appendFormat: @"\t%@:\t\t\t%@\n", field, [_responseHeaders valueForKey: field]];
	}

	
	[desc appendString: @"\n"];
	[desc appendString: self.dataString ?: @"## no_data_received ##"];
	return desc;
	
	return [NSString stringWithFormat: @"<0x%@>[%ld.%ld] %@ [%@]%@", self, (long)_priority, (long)_order, [self.url absoluteString], _tag, self.alreadyStarted ? @" (started)" : @""];
}

- (void) setFilename: (NSString *) newFilename {
	SA_Assert(_file == nil, @"SA_Connection: Can't change the filename once the file has been opened.");
	_filename = newFilename;
	
	self.prefersFileStorage = (_filename.length > 0);
}

- (void) switchToFileStorage {
	if (_file) return;				//already switched
	
	if (_filename.length == 0) {
		NSString					*name = [[self.url absoluteString] lastPathComponent];
		NSString					*extension = [name pathExtension];
		
		if (name.length > 30) name = NSLocalizedString(@"Download", @"Download");
		if (extension.length > 5 || extension.length == 0) extension = @"data";
		
		_filename = [NSString tempFileNameWithSeed: [name stringByDeletingPathExtension] ofType: extension];
	}
	
	FILE						*f = fopen([_filename fileSystemRepresentation], self.resumable ? "a+" : "w+");
	
	fclose(f);

	//SA_BASE_LOG(@"Created file: %@, (%@)", _filename, [[NSFileManager defaultManager] fileExistsAtPath: _filename] ? @"exists" : @"doesn't exist");
	_file = [NSFileHandle fileHandleForUpdatingAtPath: _filename];
	if (_file == nil) {
		SA_BASE_LOG(@"Failed to create switched-over file at %@", _filename);
		return;
	}
	
	if (self.mutableData.length) [_file writeData: self.mutableData];
	self.mutableData = nil;
}

- (void) setUsername:(NSString *)username password:(NSString *) password {
	NSString				*authString = [NSString stringWithFormat: @"%@:%@", username, password];
	NSData					*authData = [NSData dataWithBytes: [authString UTF8String] length: authString.length];
	
	[self addHeader: [NSString stringWithFormat: @"Basic %@", [authData SA_base64Encoded]] label: @"Authorization"];	
}

- (NSString *) responseHeader: (NSString *) key {
	return [_responseHeaders objectForKey: key];
}

- (void) enqueue { [[SA_ConnectionQueue sharedQueue] queueConnection: self]; }

- (NSData *) uploadedDataStream {
	NSString			*rawURL = [self.url absoluteString];
	NSMutableData		*data = [NSMutableData dataWithBytes: [rawURL UTF8String] length: rawURL.length];
	char				*method = (char *) [(_method ? _method : @"GET") UTF8String];
	
	[data appendBytes: "\n\nMethod: " length: 10];
	[data appendBytes: method length: strlen(method)];
	[data appendBytes: "\n" length: 1];
	
	for (NSString *key in self.connectionHeaders) {
		char					*label = (char *) [key UTF8String];
		char					*value = (char *) [self.connectionHeaders[key] UTF8String];
		
		[data appendBytes: label length: strlen(label)];
		[data appendBytes: ": " length: 2];
		[data appendBytes: value length: strlen(value)];
		[data appendBytes: "\n" length: 1];
	}

	[data appendBytes: "\n\n" length: 2];
	
	
	if (self.payload) {
		[data appendData: self.payload];
	}
	return data;
}

- (NSData *) downloadedDataStream {
	NSMutableData		*raw = [self uploadedDataStream].mutableCopy;
	char				*resultString = (char *) [[NSString stringWithFormat: @"\nStatus Code: %ld\n\n", (long)self.statusCode] UTF8String];
	
	[raw appendBytes: "\n" length: 1];
	if (SA_Base_DebugMode()) {
		NSString			*timeString = [NSString stringWithFormat: @"\nRequest: %.5fs, Data: %.5fs", [self.responseReceivedAt timeIntervalSinceDate: self.requestStartedAt], [self.finishedLoadingAt timeIntervalSinceDate: self.responseReceivedAt]];
		char				*timeChars = (char *) [timeString UTF8String];
		[raw appendBytes: timeChars length: strlen(timeChars)];
		
		//SA_BASE_LOG(@"============================================================%@", timeString);
	}
	
	[raw appendBytes: resultString length: strlen(resultString)];
	
	[raw appendData: self.downloadedData];
	return raw;
}

- (NSData *) downloadedData {
	if (self.mutableData) return self.mutableData;
	if (_filename) return [NSData dataWithContentsOfFile: _filename];
	return nil;
}

- (NSData *) data { return self.mutableData; }

- (NSDictionary *) submissionParameters {
	return [NSDictionary dictionaryWithPostData: _payload];
}

- (void) setSubmissionParameters: (NSDictionary *) parameters {
	_payload = [parameters encodedPostData];
}

- (NSString *) dataString { return [NSString stringWithData: self.mutableData]; }
- (NSString *) payloadString { return [NSString stringWithData: self.payload]; }

//=============================================================================================================================
#pragma mark KVC
- (void) setValue: (id) value forUndefinedKey: (NSString *) key {
	if (self.extraKeyValues == nil) self.extraKeyValues = [NSMutableDictionary new];
	
	[self.extraKeyValues setObject: value forKey: key];
}

- (id) valueForUndefinedKey: (NSString *) key {
	return self.extraKeyValues[key];
}

@end

@implementation NSDictionary (SA_Connection)
- (NSData *) encodedPostData {return [self postDataByEncoding: YES];}
- (NSData *) postData {return [self postDataByEncoding: NO];}

- (NSData *) postDataByEncoding: (BOOL) encode {
	NSMutableString					*string = [NSMutableString string];
	
	for (NSString *key in self) {
		id				value = [self valueForKey: key];
		
		if (![value isKindOfClass: [NSArray class]]) value = [NSArray arrayWithObject: value];
		
		for (id component in value) {
			if (encode) 
				[string appendFormat: @"%@%@=%@", string.length ? @"&" : @"", [[key description] stringByPrettyingForURL], [[component description] stringByPrettyingForURL]];
			else
				[string appendFormat: @"%@%@=%@", string.length ? @"&" : @"", [key description], [component description]];
		}
	}
	
	return [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}

+ (NSDictionary *) dictionaryWithParameterString: (NSString *) string {
	NSArray					*array = [string componentsSeparatedByString: @"&"];
	NSMutableDictionary		*dict = [NSMutableDictionary dictionary];
	
	for (NSString *chunk in array) {
		NSArray					*elements = [chunk componentsSeparatedByString: @"="];
		NSString				*key = (elements.count > 0) ? [elements objectAtIndex: 0] : nil;
		NSString				*value = (elements.count > 1) ? [elements objectAtIndex: 1] : nil;
		
		if (value && key) [dict setObject: [value stringByReplacingPercentEscapesUsingEncoding: NSASCIIStringEncoding] forKey: [key stringByReplacingPercentEscapesUsingEncoding: NSASCIIStringEncoding]];
	}
	
	return dict;
}

+ (NSDictionary *) dictionaryWithPostData: (NSData *) data {
	NSString				*string = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
	NSDictionary			*results = [self dictionaryWithParameterString: string];
	
	return results;
}

@end


