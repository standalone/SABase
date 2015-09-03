//
//  SA_ConnectionQueue.h
//
//  Created by Ben Gottlieb on 3/29/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

@import Foundation;
@import SystemConfiguration;

@class SA_ThreadsafeMutableDictionary, SA_ThreadsafeMutableArray;


#define			HTTP_STATUS_CODE_IS_ERROR(c)				(c >= 400)


@class SA_Connection;

typedef void (^connectionFinished)(SA_Connection *incoming, NSInteger resultCode, id error);
typedef void (^SA_ConnectionBlock)(SA_Connection *found);

typedef enum {
	connection_dontRecord,				//default behavior
	connection_record,					//record all transactions
	connection_playback,				//playback pre-recorded transactions, fail others
	connection_playbackAndFetch			//playback pre-recorded transactions, run others as normal
} connection_record_setting;


@protocol SA_ConnectionRouter <NSObject>
- (BOOL) shouldProcessSuccessfulConnection: (SA_Connection *) connection;
- (BOOL) shouldProcessFailedConnection: (SA_Connection *) connection;
@end

@protocol SA_ConnectionDelegate <NSObject>
@optional
- (void) connectionWillBegin: (SA_Connection *) connection;
- (void) connectionDidFinish: (SA_Connection *) connection;
- (void) connectionFailed: (SA_Connection *) connection withError: (NSError *) error;
- (BOOL) connectionFailed: (SA_Connection *) connection withStatusCode: (NSInteger) statusCode;			//return YES to continue the connection anyway
- (void) connectionCancelled: (SA_Connection *) connection;

//please wait support
- (NSString *) pleaseWaitMajorStringForConnection: (SA_Connection *) connection;
- (NSString *) pleaseWaitMinorStringForConnection: (SA_Connection *) connection;
- (BOOL) pleaseWaitShowProgressValueForConnection: (SA_Connection *) connection;	
- (float) pleaseWaitProgressValueForConnection: (SA_Connection *) connection;
@end


@interface SA_Connection : NSObject <NSCopying>

@property (nonatomic, copy) NSString *tag;							//a tag, broken down into different.segment.types, for filtering and identification
@property (nonatomic, readwrite) NSInteger priority;									//where in the pending queue should this transaction fall?
@property (nonatomic, readwrite) NSInteger order;
@property (nonatomic, readwrite) BOOL replaceOlder, ignoreLater;					//should older connections be deleted if they match the tag, or should this be tossed?
@property (nonatomic, readwrite) BOOL showsPleaseWait, resumable, completeInBackground, prefersFileStorage, suppressConnectionAlerts;
@property (nonatomic, readwrite, copy) NSDictionary *submissionParameters;
@property (nonatomic, readwrite) NSTimeInterval timeoutInterval;
@property (nonatomic, readwrite) BOOL disableNativeCookieHandling;
@property (nonatomic, copy) NSArray *sentCookies;
@property (nonatomic, copy) connectionFinished connectionFinishedBlock;
@property (nonatomic) BOOL logPhases;
@property (nonatomic, copy) NSString *method;						//what HTTP method should be used? Defaults to GET
@property (nonatomic, copy) NSData *payload;						//data to be pushed up, usually with a PUT or POST call

@property (nonatomic, readonly) NSURL *url;								//the URL to be hit
@property (nonatomic, readonly) NSURLRequest *request;					//for pre-configured requests
@property (nonatomic, readonly) NSURLRequest *generatedRequest;					//takes the configured values and returns an NSURLRequest
@property (nonatomic, readonly) NSData *data;									//the data returned by the server
@property (nonatomic, readonly) NSFileHandle *file;								//if storing in a file, the file
@property (nonatomic, strong) NSString *filename;						//if storing in a file, the filenamel this can be set if a known filename is desired
@property (nonatomic, readonly) id <SA_ConnectionDelegate> delegate;	//where completed/failed messages are sent
@property (nonatomic, readonly) NSDictionary *allResponseHeaders;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonatomic, readonly) NSData *downloadedData;
@property (nonatomic, readonly) BOOL completed, alreadyStarted, canceled;
@property (nonatomic, readonly) BOOL inProgress;
@property (nonatomic, readwrite) BOOL allowRepeatedKeys, discardIfOffline;
@property (nonatomic, readonly) NSString *dataString, *payloadString;
@property (nonatomic, readonly) NSArray *receivedCookies;
@property (nonatomic, readonly) NSData *uploadedDataStream, *downloadedDataStream;
@property (nonatomic, readonly) NSDate *requestStartedAt, *responseReceivedAt, *finishedLoadingAt;


+ (id) connectionWithURL: (NSURL *) url completionBlock: (connectionFinished) completionBlock;
+ (id) connectionWithURL: (NSURL *) url payload: (NSData *) payload method: (NSString *) method priority: (NSInteger) priority completionBlock: (connectionFinished) completionBlock;

+ (id) connectionWithURL: (NSURL *) url tag: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate;
+ (id) connectionWithURL: (NSURL *) url payload: (NSData *) payload method: (NSString *) method priority: (NSInteger) priority tag: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate;
+ (id) connectionWithURLRequest: (NSURLRequest *) request completionBlock: (connectionFinished) completionBlock;

+ (SA_Connection *) downloadURL: (NSURL *) url withCompletionBlock: (connectionFinished) completionBlock;
+ (SA_Connection *) downloadURLRequest: (NSURLRequest *) urlRequest withCompletionBlock: (connectionFinished) completionBlock;

- (id) initWithURL: (NSURL *) url payload: (NSData *) payload method: (NSString *) method priority: (NSInteger) priority tag: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate;

- (void) addHeader: (NSString *) header label: (NSString *) label;
- (void) removeHeader: (NSString *) label;
- (BOOL) start;
- (void) reset;
- (void) cancel: (BOOL) clearDelegate;
- (void) cancelIfNotInProgress: (BOOL) clearDelegate;
- (void) switchToFileStorage;
- (void) setUsername: (NSString *) username password: (NSString *) password;

- (NSString *) responseHeader: (NSString *) key;
- (void) enqueue;

- (void) connectionDidFinishLoading: (NSURLConnection *) connection;		//so that subclasses can call super

@end



@interface SA_ConnectionQueue : NSObject <SA_ConnectionRouter>

SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(SA_ConnectionQueue, sharedQueue);

@property (atomic, readwrite) NSInteger activityIndicatorCount;

@property (readwrite) BOOL offline, showProgressInPleaseWaitDisplay, logAllConnections;
@property (readonly) BOOL wifiAvailable, wlanAvailable;
@property (readwrite) NSUInteger maxSimultaneousConnections;
@property (nonatomic, readwrite) NSInteger defaultPriorityLevel, minimumIndicatedPriorityLevel, fileSwitchOverLimit;
@property (nonatomic, readonly) NSUInteger connectionCount;
@property (nonatomic, readwrite) BOOL dontProcessFailedStatusCodes;
@property (nonatomic, readwrite) BOOL suppressPleaseWaitDisplay;
@property (nonatomic, readonly) BOOL shouldPleaseWaitBeVisible;					//used to check if a pleaseWait SHOLD be shown, regardless of whether _suppressPleaseWaitDisplay is set 
@property (nonatomic, readonly) BOOL connectionsArePending;
@property (nonatomic, readwrite) BOOL managePleaseWaitDisplay, suppressOfflineAlerts;
@property (nonatomic, weak) id <SA_ConnectionRouter> router;
@property (nonatomic, assign) dispatch_queue_t backgroundQueue;
@property (nonatomic) BOOL paused;
@property (nonatomic, readonly) long long bytesDownloaded;


- (BOOL) queueConnection: (SA_Connection *) connection;
- (BOOL) queueConnection: (SA_Connection *) connection andPromptIfOffline: (BOOL) prompt;
- (void) processQueue;
- (void) resetOfflineAlerts;
- (void) attempToGoOnline;

- (void) determineConnectionLevelAvailable;
- (void) resetHighwaterMark;								//call this to clear out the 'highwater mark', used when displaying progress

- (void) addHeader: (NSString *) header label: (NSString *) label;
- (void) removeHeader: (NSString *) label;
- (void) removeAllHeaders;

- (void) isExistingConnectionTaggedWith: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate completion: (booleanArgumentBlock) completion;
- (void) isExistingConnectionSimilar: (SA_Connection *) targetConnection completion: (booleanArgumentBlock) completion;
- (void) removeConnectionsTaggedWith: (NSString *) tag;
- (void) removeConnectionsWithDelegate: (id) delegate;
- (void) removeConnectionsTaggedWith: (NSString *) tag delegate: (id) delegate;
- (void) cancelAllConnections;
- (void) findExistingConnectionsTaggedWith: (NSString *) tag delegate: (id <SA_ConnectionDelegate>) delegate completion: (SA_ConnectionBlock) completion;

- (NSInteger) remainingConnectionsAboveMinimum;
- (void) dequeueConnection: (SA_Connection *) connection;
- (void) updatePleaseWaitDisplay;
- (void) hideActivityIndicator;

- (void) resetBytesDownloaded;

+ (NSString *) nextPrefixed: (NSString *) prefix pathForTag: (NSString *) tag;
+ (NSString *) logDirectoryPath;
@end

extern NSString *kConnectionNotification_Queued;
extern NSString *kConnectionNotification_ConnectionStarted;

extern NSString *kConnectionNotification_Dequeued;
extern NSString *kConnectionNotification_ConnectionFinished, *kConnectionNotification_ConnectionCancelled, *kConnectionNotification_ConnectionFailed;
extern NSString *kConnectionNotification_ConnectionStateChanged;
extern NSString *kConnectionNotification_ConnectionReachabilityChanged;



extern NSString *kConnectionNotification_NotConnectedToInternet, *kConnectionNotification_ConnectionFailedToStart, *kConnectionNotification_ConnectionReturnedBadStatus, *kConnectionNotification_AllConnectionsCompleted;


@interface NSDictionary (SA_Connection)
- (NSData *) postDataByEncoding: (BOOL) encode;
- (NSData *) encodedPostData;
- (NSData *) postData;
+ (NSDictionary *) dictionaryWithPostData: (NSData *) data;
+ (NSDictionary *) dictionaryWithParameterString: (NSString *) string;
@end