//
//  NSError+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 12/30/13.
//
//

#import "NSError+SA_Additions.h"
#import "SA_ConnectionQueue.h"

const NSString			*SA_BaseErrorDomain = @"SA_BaseErrorDomain";

@implementation NSError (SA_Additions)
- (BOOL) checkForNoInternetConnectionErrorAndUpdateConnectionQueue: (BOOL) countTimeoutAsNoInternet {
	BOOL				isNoInternet = self.isNoInternetConnectionError;
	BOOL				isTimeout = self.isTimeoutError;
	
	if (isNoInternet || (countTimeoutAsNoInternet && isTimeout)) {
		[SA_ConnectionQueue sharedQueue].offline = YES;
	}
		
		return isTimeout || isNoInternet;
}

- (BOOL) isTimeoutError {
	return [self.domain isEqual: NSURLErrorDomain] && self.code == NSURLErrorTimedOut;
}

- (BOOL) isNoInternetConnectionError {
	if ([self.domain isEqual: @"CKErrorDomain"] && self.code == 4) return YES;		// CloudKit CKErrorNetworkFailure
//	if ([self.domain isEqual: @"CKErrorDomain"] && self.code == kCFURLErrorBadServerResponse) return YES;		// CloudKit CKErrorNetworkFailure
	
	if ([self.domain isEqual: NSURLErrorDomain] && (self.code == NSURLErrorNotConnectedToInternet || self.code == NSURLErrorCannotConnectToHost || self.code == NSURLErrorNetworkConnectionLost)) return YES;
	
	for (NSError *error in self.sa_underlyingErrors) {
		if (error.isNoInternetConnectionError) return YES;
	}
	return NO;
}

- (BOOL) shouldProbablyBeSupressedForMostUsers {
	if ([self.domain isEqual: NSURLErrorDomain]) {
		if (self.code == NSURLErrorCancelled || self.code == NSURLErrorUserCancelledAuthentication || self.code == NSURLErrorZeroByteResource || self.code == NSURLErrorServerCertificateHasBadDate || self.code == NSURLErrorServerCertificateUntrusted || self.code == NSURLErrorServerCertificateHasUnknownRoot || self.code == NSURLErrorServerCertificateNotYetValid || self.code == NSURLErrorClientCertificateRejected || self.code == NSURLErrorClientCertificateRequired || self.code == NSURLErrorCannotLoadFromNetwork) return YES;
	}
	return NO;
}

- (NSArray *) sa_underlyingErrors {
	NSMutableArray			*errors = [NSMutableArray array];
	
	if (self.userInfo[NSUnderlyingErrorKey]) [errors addObject: self.userInfo[NSUnderlyingErrorKey]];
	if (self.userInfo[@"CKPartialErrors"]) [errors addObjectsFromArray: [self.userInfo[@"CKPartialErrors"] allObjects]];
	return errors;
}
@end
