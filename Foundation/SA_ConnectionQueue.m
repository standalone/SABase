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

#if TARGET_OS_IPHONE
	
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

#if ENABLE_RECORDING
	#import "SA_ConnectionQueue+Recording.h"
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

@interface SA_ConnectionQueue () 
- (void) fireReachabilityStatus;
- (void) reorderPendingConnectionsByPriority;
- (void) incrementBytesDownloaded: (long long) byteCount;

@property (nonatomic, strong) NSOperationQueue *privateQueue;
@property (nonatomic, weak) NSTimer *queueProcessingTimer;
@property (nonatomic) long long bytesDownloaded;

@property (nonatomic, strong) NSArray *pending;
@property (nonatomic, strong) NSSet *active;
@end

//=============================================================================================================================
//=============================================================================================================================
#pragma mark SA_ConnectionQueue
@implementation SA_ConnectionQueue
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
		_pleaseWaitConnections = [[NSMutableArray alloc] init];
		_headers = [[NSMutableDictionary alloc] init];
		_defaultPriorityLevel = 5;
		_minimumIndicatedPriorityLevel = 5;
		_fileSwitchOverLimit = 1024 * 20;			//switch to a file after 20k has been downloaded
		self.managePleaseWaitDisplay = YES;
		
		_connectionSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey: @"priority" ascending: YES], [NSSortDescriptor sortDescriptorWithKey: @"order" ascending: YES]];
		[self performSelector: @selector(determineConnectionLevelAvailable) withObject: nil afterDelay: 0.0];			//defer this call so as not to slow down the startup procedure
		
		#if TARGET_OS_IPHONE
			_backgroundTaskID = kUIBackgroundTaskInvalid;
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
	if (_offline || connection == nil) return NO;
	
	[self.privateQueue addOperationWithBlock: ^{
		if (connection.ignoreLater) {
			if ([self isExistingConnectionSimilar: connection]) {		//already queued, ignore it
				[self reorderPendingConnectionsByPriority];
				return;
			}
		} else if (connection.replaceOlder) {
			[self removeConnectionsTaggedWith: connection.tag delegate: connection.delegate];
		}
		
		[self.privateQueue addOperationWithBlock: ^{
			SA_Assert(!connection.alreadyStarted, @"Can't queue an already started connection");

			self.pending = [self.pending arrayByAddingObject: connection];
			connection.order = self.pending.count;
			if (connection.persists && [self respondsToSelector: @selector(persistConnection:)]) {
				if (connection.completeInBackground) {LOG(@"Trying to persist a background connection. This is not allowed. (%@)", connection);}
			}

			[self reorderPendingConnectionsByPriority];
			if (self.managePleaseWaitDisplay && connection.showsPleaseWait) {
				[_pleaseWaitConnections addObject: connection];
			}
			
			#if TARGET_OS_IPHONE
				if (self.managePleaseWaitDisplay && connection.priority >= _minimumIndicatedPriorityLevel && self.showProgressInPleaseWaitDisplay) _highwaterMark++;
			#endif
			
			[self deferQueueProcessing];
			if (self.managePleaseWaitDisplay) [self updatePleaseWaitDisplay];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_Queued object: connection];
		}];
	}];
	return YES;
}

- (void) resetOfflineAlerts {
	_offlineAlertShown = NO;
}

- (void) attempToGoOnline {
	if (!self.offline) return;
	
	[self fireReachabilityStatus];
}

- (void) showOfflineAlertAllowingRetry: (BOOL) allowingRetry {
	#if TARGET_OS_IPHONE
		NSString		*title = NSLocalizedString(@"Connection Error", @"Connection Error");
		NSString		*body = NSLocalizedString(@"Unable to connect. Please try again later.", @"Unable to connect. Please try again later.");
		
		SA_AlertView	*alert = [[SA_AlertView alloc] initWithTitle: title
															  message: body
															 delegate: self
													cancelButtonTitle: NSLocalizedString(@"Cancel", nil)
												 otherButtonTitles: allowingRetry ? NSLocalizedString(@"Retry", nil) : nil, nil];
		
		[alert show];
	#endif
	
	_offlineAlertShown = YES;
}

- (BOOL) queueConnection: (SA_Connection *) connection andPromptIfOffline: (BOOL) prompt {
	if (connection && [self queueConnection: connection]) return YES;
	
	if (connection.discardIfOffline) [connection cancel: NO];
	
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_NotConnectedToInternet object: self];
	if (_offlineAlertShown || self.suppressOfflineAlerts) return NO;
	if (prompt) [self showOfflineAlertAllowingRetry: !connection.discardIfOffline];
	return NO;
}

- (void) reorderPendingConnectionsByPriority {
	if (self.pending.count > 1) self.pending = [self.pending sortedArrayUsingDescriptors: _connectionSortDescriptors];
}

- (BOOL) performInvocationIfOffline: (NSInvocation *) invocation {
	self.backOnlineInvocation = invocation;
	[self showOfflineAlertAllowingRetry: YES];
	
	return NO;
}

#if TARGET_OS_IPHONE
	- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex {
		if (buttonIndex != alertView.cancelButtonIndex) {
			self.offline = NO;
			[self resetOfflineAlerts];
			
			if (self.backOnlineInvocation) {
				[self.backOnlineInvocation invoke];
			}
		}
		self.backOnlineInvocation = nil;
	}
#endif

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
		#ifdef kUIBackgroundTaskInvalid
        #if !TARGET_OS_MAC
			if (self.active.count == 0 && self.pending.count == 0 && _backgroundTaskID == kUIBackgroundTaskInvalid) return;
			if (self.active.count == 0 && _backgroundTaskID == kUIBackgroundTaskInvalid) {
				_backgroundTaskID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler: ^{
					if (_backgroundTaskID != kUIBackgroundTaskInvalid) {
						dispatch_async_main_queue(^{
							if (_backgroundTaskID != kUIBackgroundTaskInvalid) {
								LOG(@"Expiring background task (forced)");
								[[UIApplication sharedApplication] endBackgroundTask: _backgroundTaskID];
								_backgroundTaskID = kUIBackgroundTaskInvalid;
							}
						});
					}
				}];
			}
		#endif
        #endif
		
		while (!_offline && !self.paused && self.active.count < self.maxSimultaneousConnections && self.pending.count) {
			SA_Connection				*connection = self.pending[0];
			
			SA_Assert(!connection.alreadyStarted, @"Somehow a previously started connection is in the pending list: %@", connection);
			for (NSString *key in _headers) {[connection addHeader: _headers[key] label: key];}
			if ([connection start]) {
				self.activityIndicatorCount++;
				self.active = [self.active setByAddingObject: connection];
			} else {
				LOG(@"Connection failed to start: %@", connection);
				[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionFailedToStart object: connection];
			}
			self.pending = [self.pending SA_arrayByRemovingObject: connection];
		}

		if (self.active.count == 0 && !_paused) {
			if (self.pending.count == 0) {
				_highwaterMark = 0;
				[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_AllConnectionsCompleted object: self];
			}
			#ifdef kUIBackgroundTaskInvalid
            #if !TARGET_OS_MAC
				if (_backgroundTaskID != kUIBackgroundTaskInvalid) {
					dispatch_async_main_queue(^{
						if (_backgroundTaskID != kUIBackgroundTaskInvalid && self.active.count == 0) {
							[[UIApplication sharedApplication] endBackgroundTask: _backgroundTaskID];
							_backgroundTaskID = kUIBackgroundTaskInvalid;
						}
					});
				}
			#endif
            #endif
		}
		
		if (self.managePleaseWaitDisplay) [self updatePleaseWaitDisplay];
	}];
}

- (void) addHeader: (NSString *) header label: (NSString *) label { _headers[label] = header; }
- (void) removeHeader: (NSString *) label { [_headers removeObjectForKey: label]; }
- (void) removeAllHeaders { [_headers removeAllObjects]; }


- (void) removeConnectionsTaggedWith: (NSString *) tag { [self removeConnectionsTaggedWith: tag delegate: nil]; }
- (void) removeConnectionsWithDelegate: (id) delegate { [self removeConnectionsTaggedWith: nil delegate: delegate]; }
- (void) removeConnectionsTaggedWith: (NSString *) tag delegate: (id) delegate {
	[self.privateQueue addOperationWithBlock:^{
		for (SA_Connection *connection in self.active.copy) {
			if ((tag == nil || [connection.tag rangeOfString: tag].location != NSNotFound) && (delegate == nil || connection.delegate == delegate)) {
				[connection cancel: YES];
				self.activityIndicatorCount--;
			}
		}
		
		for (SA_Connection *connection in self.pending.copy) {
			if ((tag == nil || [connection.tag rangeOfString: tag].location != NSNotFound) && (delegate == nil || connection.delegate == delegate)) {
				[connection cancel: YES];
			}
		}

		[self deferQueueProcessing];
	}];

}

- (void) cancelAllConnections { [self removeConnectionsTaggedWith: nil delegate: nil]; }

- (BOOL) isExistingConnectionSimilar: (SA_Connection *) targetConnection {
	@try {
		if (targetConnection.tag || targetConnection.delegate) return [self isExistingConnectionsTaggedWith: targetConnection.tag delegate: targetConnection.delegate];
		
		NSURL				*url = targetConnection.url;
		
		for (SA_Connection *connection in self.active.copy) {
			if (!connection.canceled &&  [url isEqual: connection.url]) return YES;
		}
		
		for (SA_Connection *connection in self.pending.copy) {
			if (!connection.canceled &&  [url isEqual: connection.url]) return YES;
		}
	} @catch (NSException *e) {}
	
	return NO;
	
}

- (BOOL) isExistingConnectionsTaggedWith: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate {
	return [self existingConnectionsTaggedWith: tag delegate: delegate] != nil;
}

- (SA_Connection *) existingConnectionsTaggedWith: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate {
	@try {
		for (SA_Connection *connection in self.active.copy) {
			if (tag == nil && connection.tag != nil) continue;
			if (tag != nil && connection.tag == nil) continue;
			if (tag && [connection.tag rangeOfString: tag].location == NSNotFound) continue;
			
			if (delegate == nil && connection.delegate == nil) return connection;
			if (delegate == connection.delegate) return connection;
		}
		
		for (SA_Connection *connection in self.pending.copy) {
			if (tag == nil && connection.tag != nil) continue;
			if (tag != nil && connection.tag == nil) continue;
			if (tag && [connection.tag rangeOfString: tag].location == NSNotFound) continue;
			
			if (delegate == nil && connection.delegate == nil) return connection;
			if (delegate == connection.delegate) return connection;
		}
	} @catch (NSException *e) {};
	
	return nil;
}

- (void) resetHighwaterMark { _highwaterMark = 0; }

//=============================================================================================================================
#pragma mark Properties
- (void) setOffline: (BOOL) offline {
	if (offline == _offline) return;
	
	_offline = offline;

	if (_offline) {				//need too cancel all active connections
		[self.privateQueue addOperationWithBlock:^{
			for (SA_Connection *connection in self.active.copy) {
				SA_Assert(!connection.alreadyStarted, @"There was an unstarted connection in the active list: %@", connection);
				[connection reset];
				self.activityIndicatorCount--;
				if (![self.pending containsObject: connection]) self.pending = [self.pending arrayByAddingObject: connection];
			}

			if (self.managePleaseWaitDisplay) {
				[_pleaseWaitConnections removeAllObjects];
				[self updatePleaseWaitDisplay];
			}

			self.active = [NSSet set];
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_NotConnectedToInternet object: self];
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionStateChanged object: @(!offline)];
		}];

	} else {
		_offlineAlertShown = NO;
		[self deferQueueProcessing];
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionStateChanged object: @(!offline)];
	}
	if (!_offline)[[SA_ConnectionQueue sharedQueue] resetOfflineAlerts];
}

- (BOOL) offline {
	return _offline;
}

- (NSUInteger) maxSimultaneousConnections {
	if (_maxSimultaneousConnections) return _maxSimultaneousConnections;
	return _wifiAvailable ? 7 : 3;	
}

- (void) setMaxSimultaneousConnections: (NSUInteger) max { _maxSimultaneousConnections = max; }
- (BOOL) connectionsArePending { return (self.pending.count > 0 || self.active.count > 0); }
- (NSUInteger) connectionCount { return self.active.count + self.pending.count; }

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
		if (self.managePleaseWaitDisplay) [_pleaseWaitConnections removeObject: connection];
		self.pending = [self.pending SA_arrayByRemovingObject: connection];

		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_Dequeued object: connection];
		[self deferQueueProcessing];
	}];
}

- (void) connectionFailed: (SA_Connection *) connection withError: (NSError *) error {
	if (error.isNoInternetConnectionError) {					//if we're not connected, then we'll stop all future connections, and save this one
		[connection reset];
		[self.privateQueue addOperationWithBlock:^{
			if (![self.pending containsObject: connection] && connection.persists) {
				SA_Assert(!connection.alreadyStarted, @"Can't queue an already started connection");
				self.pending = [self.pending arrayByAddingObject: connection];
			}
		}];
		
		if (!_offline) {
			_offline = YES;
	
			LOG(@"Tried to push connection: %@, but not connected to the internet", connection);
			if (!connection.suppressConnectionAlerts) [self queueConnection: nil andPromptIfOffline: YES];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_NotConnectedToInternet object: self];
		}
	}
	[self dequeueConnection: connection];
}

#if TARGET_OS_IPHONE
	- (void) hidePleaseWaitDisplay {
		if (!self.managePleaseWaitDisplay) return;
		int					remaining = [self remainingConnectionsAboveMinimum];
		
		if (remaining == 0) {
			[SA_PleaseWaitDisplay hidePleaseWaitDisplay];
		} else
			[SA_PleaseWaitDisplay pleaseWaitDisplay].progressValue = (_highwaterMark - remaining) / _highwaterMark;
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
	
	if (_offline || (!self.shouldPleaseWaitBeVisible && self.managePleaseWaitDisplay)) {					//no pending connections, we're done
		[SA_PleaseWaitDisplay hidePleaseWaitDisplay];
		return;
	}
	 for (SA_Connection *connection in _pleaseWaitConnections.copy) {
		 if ([connection.delegate respondsToSelector: @selector(pleaseWaitMajorStringForConnection:)]) {
			 topConnection = connection;
			 break;
		 }
	 } 
	 
	if (topConnection == _currentTopPleaseWaitConnection) return;				//no change
	 
	_currentTopPleaseWaitConnection = topConnection;
	
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
		_currentTopPleaseWaitConnection = nil;
	} else {
		if (!_suppressPleaseWaitDisplay) return;
		_suppressPleaseWaitDisplay = NO;
		[self updatePleaseWaitDisplay];
	}
}

- (BOOL) shouldPleaseWaitBeVisible {
	return _pleaseWaitConnections.count > 0;
}

- (BOOL) shouldProcessSuccessfulConnection: (SA_Connection *) connection { return YES; }
- (BOOL) shouldProcessFailedConnection: (SA_Connection *) connection { return YES; }

//=============================================================================================================================
#pragma mark Reachability
void ReachabilityChanged(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

- (void) fireReachabilityStatus {
	SCNetworkReachabilityFlags				flags;
	
	if (_reachabilityRef == NULL) return;
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		ReachabilityChanged(_reachabilityRef, flags, NULL);
	} else {
		LOG(@"SCNetworkReachabilityGetFlags failed");
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
}

- (void) determineConnectionLevelAvailable {
	if (_reachabilityRef == NULL) {
		struct sockaddr_in							address = {};
		
		memset(&address, sizeof(struct sockaddr_in), 0);
		address.sin_family = AF_INET;
		address.sin_len = sizeof(struct sockaddr_in);
		
		inet_aton("0.0.0.0", &address.sin_addr);
		_reachabilityRef = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (struct sockaddr *) &address);
		
		if (_reachabilityRef && SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityChanged, nil)) {
			SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
			[self fireReachabilityStatus];
		} else if (_reachabilityRef == nil) {
			LOG(@"Failed to create a ReachabilityRef");
			#if TARGET_OS_IPHONE
				if (SA_Base_DebugMode()) [SA_AlertView showAlertWithTitle: @"Failed to create a ReachabilityRef" message: @"Unable to track connection status"];
			#endif
		}
	} else {
		
	}
}

//=============================================================================================================================
#pragma mark Misc
- (float) remainingConnectionsAboveMinimum {
	float				count = 0;
	
	for (SA_Connection *connection in self.active.copy) { if (connection.priority >= _minimumIndicatedPriorityLevel) count++; }
	for (SA_Connection *connection in self.pending.copy) { if (connection.priority >= _minimumIndicatedPriorityLevel) count++; }
	
	return count;
}

- (NSString *) description {
	NSMutableString				*results = [NSMutableString string];
	
	[results appendFormat: @"\nActive (%ld):\n", (long) self.active.count];
	for (SA_Connection *connection in self.active.copy) {
		[results appendFormat: @"\t\t%@\n", connection];
	}
	
	if (self.active.count && self.pending.count) [results appendString: @"\n"];
	[results appendFormat: @"Pending (%ld):\n", (long) self.pending.count];
	for (SA_Connection *connection in self.pending.copy) {
		[results appendFormat: @"\t\t%@\n", connection];
	}
	
	return results;
}


@end






//=============================================================================================================================
#pragma mark SA_Connection

@interface SA_Connection()
- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error;
@end

@implementation SA_Connection
@synthesize url = _url, data = _data, payload = _payload, method = _method, delegate = _delegate, tag = _tag, priority = _priority, persists = _persists;
@synthesize persistantID = _persistantID, order = _order, file = _file, filename = _filename, allResponseHeaders = _responseHeaders, statusCode = _statusCode;
@synthesize replaceOlder = _replaceOlder, ignoreLater = _ignoreLater, showsPleaseWait = _showsPleaseWait, resumable = _resumable, completeInBackground = _completeInBackground, prefersFileStorage = _prefersFileStorage;
@synthesize suppressConnectionAlerts = _suppressConnectionAlerts, canceled = _canceled, inProgress = _inProgress, request = _request;
@synthesize allowRepeatedKeys = _allowRepeatedKeys, discardIfOffline = _discardIfOffline, connectionFinishedBlock = _connectionFinishedBlock, timeoutInterval = _timeoutInterval;

@synthesize requestLogFileName = _requestLogFileName;
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
		self.persists = YES;
	}
	return self;
}

- (BOOL) completed {
	return _statusCode != 0;
}

- (NSData *) data {
	return _data;
}

- (id) copyWithZone: (NSZone *) ignored {
	SA_Connection					*connection = [[[self class] alloc] init];
	
	connection.url = self.url;
	connection.payload = self.payload;
	connection.priority = self.priority;
	connection.tag = self.tag;
	connection.delegate = self.delegate;
	connection.persists = self.persists;
	connection.method = self.method;
	connection.sentCookies = self.sentCookies.copy;
	connection->_headers = [_headers mutableCopy];
	
	return connection;
}

- (void) removeHeader: (NSString *) label {
	[_headers removeObjectForKey: label];
}

- (void) addHeader: (NSString *) header label: (NSString *) label {
	if (_headers == nil) _headers = [[NSMutableDictionary alloc] init];
	
	if ([_headers objectForKey: label]) {
		NSArray				*components = [[_headers objectForKey: label] componentsSeparatedByString: @";"];
		
		if ([components containsObject: header]) return;
		header = [NSString stringWithFormat: @"%@;%@", header, [_headers objectForKey: label]];
	} 
	[_headers setObject: header forKey: label];
}

- (void) setPayload: (NSData *) payload {
	#if VALIDATE_XML_UPLOADS
	if (SA_Base_DebugMode()) {
		if (payload.length && strstr((char *) [payload bytes], "<?xml version=\"1.0\"") != NULL) {
			SA_Assert([SA_XMLGenerator validateXML: payload], @"SA_Connection: XML Validation failed");
		}
	}
	#endif
	
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
	
	if ([self.method isEqual: @"GET"] && self.payload.length) LOG(@"Attaching a Payload to a GET request will probably fail \n\n %@", self);
	
	if (self.request == nil) self.request = [self generatedRequest];
	
	
	_inProgress = YES;
	_canceled = NO;
	if (self.request == nil) return NO;			//bad URL
	
	if (self.prefersFileStorage) {
		[self switchToFileStorage];
		if (self.resumable) {
			NSUInteger						offset = [_file seekToEndOfFile];
			
			if (offset) {
				if (_headers == nil) _headers = [[NSMutableDictionary alloc] init];
				[_headers setObject: [NSString stringWithFormat: @" bytes=%lu-", (unsigned long)offset] forKey: @"Range"];
			}
		}
	} else
		_data = [[NSMutableData alloc] init];
	
	
	if ([_delegate respondsToSelector: @selector(connectionWillBegin:)]) [_delegate connectionWillBegin: self];
	
	#if ENABLE_RECORDING	
		if ([SA_ConnectionQueue sharedQueue].recordSetting == connection_playback || [SA_ConnectionQueue sharedQueue].recordSetting == connection_playbackAndFetch) {
			if ([self playback]) {
				[self performSelector: @selector(connectionDidFinishLoading:) withObject: nil afterDelay: 1.0];
				return YES;
			}
			if ([SA_ConnectionQueue sharedQueue].recordSetting == connection_playback) {
				[NSObject performBlock: ^{
					NSError				*error = nil;//[NSError errorWithDomain: @"Connection Failed" code: NSURLErrorNotConnectedToInternet userInfo: nil];
					[self connection: nil didFailWithError: error];
				} afterDelay: 1.0];
				return NO;
			}
		}
	#endif
	_connection = [[NSURLConnection alloc] initWithRequest: self.request delegate: self startImmediately: NO];
	
	if (RUNNING_ON_60) {
		[_connection setDelegateQueue: [SA_ConnectionQueue sharedQueue].privateQueue];
		[_connection start];
	} else {
		[_connection performSelectorOnMainThread: @selector(start) withObject: nil waitUntilDone: NO];
	}
	
	self.requestStartedAt = [NSDate date];
	
	LOG_CONNECTION_START(self);
	if (_connection == nil) LOG(@"Error while starting connection: %@", self);
			
	if (_connection) { 
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionStarted object: self];
	}
	return (_connection != nil);
}

//=============================================================================================================================
#pragma mark Ending connections
- (void) cancel: (BOOL) clearDelegate {
	__strong SA_Connection		*strongSelf = self;
	LOG_CONNECTION_PHASE(@"Cancelled", strongSelf);
	
	if ([_delegate respondsToSelector: @selector(connectionCancelled:)]) [_delegate connectionCancelled: strongSelf];
	if (clearDelegate) strongSelf.delegate = nil;
	if (_canceled) return;

	[[SA_ConnectionQueue sharedQueue] dequeueConnection: strongSelf];

	[_connection cancel];
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
	return _data != nil || _connection != nil;
}
- (void) reset {
	_statusCode = 0;
	_data = nil;
	[_connection cancel];
	_connection = nil;
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
	if (self.sentCookies.count == 0) return _headers;
	
	NSMutableDictionary				*headers = _headers.mutableCopy;
	
	headers[@"Cookie"] = [self.sentCookies componentsJoinedByString: @","];
	return headers;
}

- (void) connection: (NSURLConnection *) connection didFailWithError: (NSError *) error {
	_inProgress = NO;
	LOG_CONNECTION_PHASE(@"Failed", self);
	if (SA_Base_DebugMode()) self.finishedLoadingAt = [NSDate date];LOG(@"Connection %@ failed: %@", self, error.internetConnectionFailed ? @"NO CONNECTION" : (id) error);
	
	if (_canceled) return;

	if (self.connectionFinishedBlock) {
		self.connectionFinishedBlock(self, self.statusCode, error);
	} else if ([_delegate respondsToSelector: @selector(connectionFailed:withError:)]) 
		[_delegate connectionFailed: self withError: error];
	
	[[SA_ConnectionQueue sharedQueue] connectionFailed: self withError: error];
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadName: kConnectionNotification_ConnectionFailed object: self];
	_connection = nil;
}

- (void) connectionDidFinishLoading: (NSURLConnection *) connection {
	_inProgress = NO;
	#if ENABLE_RECORDING
		if ([SA_ConnectionQueue sharedQueue].recordSetting == connection_record) [self record]; 
	#endif
	self.finishedLoadingAt = [NSDate date];
	if (_canceled) return;

	LOG_CONNECTION_PHASE(@"Finished", self);
	
	if ([SA_ConnectionQueue sharedQueue].logAllConnections) {
		NSError								*error = nil;
		if (self.requestLogFileName) [[NSFileManager defaultManager] removeItemAtPath: self.requestLogFileName error: &error];
		[[self downloadedDataStream] writeToFile: [SA_ConnectionQueue nextPrefixed: @"download" pathForTag: self.tag] atomically: YES];
	}
	
	if (_file) [_file closeFile];
	
	[[SA_ConnectionQueue sharedQueue] dequeueConnection: self];			//dequeue the connection, and start the queue working on the next one, then we handle this one's data
	_connection = nil;
	
	if (![[SA_ConnectionQueue sharedQueue].router shouldProcessSuccessfulConnection: self]) return;
	
	BOOL					dontProcessFailedStatusCodes = [SA_ConnectionQueue sharedQueue].dontProcessFailedStatusCodes;

	if (self.prefersFileStorage) 
		[self switchToFileStorage];
	else if (_data == nil && _file) 
		_data = [NSData dataWithContentsOfFile: _filename];
	

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
		} else  if ([SA_ConnectionQueue sharedQueue].backgroundThread)
			[self performSelector: @selector(backgroundConnectionDidFinish) onThread: [SA_ConnectionQueue sharedQueue].backgroundThread withObject: nil waitUntilDone: NO];
		else
			[NSThread detachNewThreadSelector: @selector(backgroundConnectionDidFinish) toTarget: self withObject: nil];
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

	//LOG(@"Request Response Time: %@, Start Time: %@", [NSDate date], [NSDate dateWithTimeIntervalSinceReferenceDate: _requestStart]);
	self.responseReceivedAt = [NSDate date];
	
	LOG_CONNECTION_PHASE(@"Received Response", self);
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
	LOG_CONNECTION_PHASE([NSString stringWithFormat: @"Received Data"], self);
	if (_canceled) return;
	if (_file)
		[_file writeData: data];
	else
		[_data appendData: data];
	
	[[SA_ConnectionQueue sharedQueue] incrementBytesDownloaded: data.length];
}



- (NSString *) description {
	NSMutableString				*desc = [NSMutableString stringWithFormat: @"<0x%x>%@", (int) self, NSStringFromClass([self class])];
	if (self.tag) [desc appendFormat: @", tag: %@", self.tag];
	[desc appendFormat: @", Pri: %ld", (long)_priority];
	if (self.delegate) [desc appendFormat: @", delegate: <0x%@> %@", self.delegate, NSStringFromClass([self.delegate class])];
	
	[desc appendFormat: @"\nHeaders:\n"];
	NSMutableDictionary			*headers = [NSMutableDictionary dictionaryWithDictionary: _headers ?: @{}];
	for (NSString *header in self.request.allHTTPHeaderFields) { headers[header] = self.request.allHTTPHeaderFields[header]; }
	
	for (NSString *field in headers) {
		[desc appendFormat: @"\t%@:\t\t\t%@\n", field, [headers valueForKey: field]];
	}
	[desc appendFormat: @"URL:\t\t\t%@\nMethod:\t\t\t%@\n", self.url, self.method];
	if (self.payload.length) [desc appendFormat: @"Payload:\n%@\n", self.payloadString];

	if (self.data.length) [desc appendFormat: @"\nResult (%ld): \n", (long)self.statusCode];
	
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
	
	
//	long						filesize = 0;
//	
//	if (self.resumable) {
//		fseek(f, SEEK_END, 0);
//		filesize = ftell(f);
//	}
	fclose(f);

	//LOG(@"Created file: %@, (%@)", _filename, [[NSFileManager defaultManager] fileExistsAtPath: _filename] ? @"exists" : @"doesn't exist");
	_file = [NSFileHandle fileHandleForUpdatingAtPath: _filename];
	if (_file == nil) {
		LOG(@"Failed to create switched-over file at %@", _filename);
		return;
	}
	
	if (_data.length) [_file writeData: _data];
	_data = nil;
}

- (void) setUsername:(NSString *)username password:(NSString *) password {
	NSString				*authString = [NSString stringWithFormat: @"%@:%@", username, password];
	NSData					*authData = [NSData dataWithBytes: [authString UTF8String] length: authString.length];
	
	[self addHeader: [NSString stringWithFormat: @"Basic %@", [authData SA_base64Encoded]] label: @"Authorization"];	
}

- (NSString *) responseHeader: (NSString *) key {
	return [_responseHeaders objectForKey: key];
}

- (void) queue { [[SA_ConnectionQueue sharedQueue] queueConnection: self]; }

- (NSData *) uploadedDataStream {
	NSString			*rawURL = [self.url absoluteString];
	NSMutableData		*data = [NSMutableData dataWithBytes: [rawURL UTF8String] length: rawURL.length];
	char				*method = (char *) [(_method ? _method : @"GET") UTF8String];
	
	[data appendBytes: "\n\nMethod: " length: 10];
	[data appendBytes: method length: strlen(method)];
	[data appendBytes: "\n" length: 1];
	
	for (NSString *key in _headers) {
		char					*label = (char *) [key UTF8String];
		char					*value = (char *) [[_headers valueForKey: key] UTF8String];
		
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
		
		//LOG(@"============================================================%@", timeString);
	}
	
	[raw appendBytes: resultString length: strlen(resultString)];
	
	[raw appendData: self.downloadedData];
	return raw;
}

- (NSData *) downloadedData {
	if (_data) return _data;
	if (_filename) return [NSData dataWithContentsOfFile: _filename];
	return nil;
}

- (NSDictionary *) submissionParameters {
	return [NSDictionary dictionaryWithPostData: _payload];
}

- (void) setSubmissionParameters: (NSDictionary *) parameters {
	_payload = [parameters encodedPostData];
}

- (NSString *) dataString { return [NSString stringWithData: self.data]; }
- (NSString *) payloadString { return [NSString stringWithData: self.payload]; }

//=============================================================================================================================
#pragma mark KVC
- (void) setValue: (id) value forUndefinedKey: (NSString *) key {
	if (_extraKeyValues == nil) _extraKeyValues = [[NSMutableDictionary alloc] init];
	
	[_extraKeyValues setObject: value forKey: key];
}

- (id) valueForUndefinedKey: (NSString *) key {
	return [_extraKeyValues objectForKey: key];
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


@implementation NSError (SA_ConnectionQueue)
- (BOOL) internetConnectionFailed {
	return (self.code == NSURLErrorCannotConnectToHost || self.code == NSURLErrorNetworkConnectionLost || self.code == NSURLErrorNotConnectedToInternet);
}
@end

