//
//  NSError+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 12/30/13.
//
//

#import "NSError+SA_Additions.h"

@implementation NSError (SA_Additions)
- (BOOL) isNoInternetConnectionError {
	return [self.domain isEqual: NSURLErrorDomain] && self.code == NSURLErrorNotConnectedToInternet;
}

- (BOOL) shouldProbablyBeSupressedForMostUsers {
	if ([self.domain isEqual: NSURLErrorDomain]) {
		if (self.code == NSURLErrorCancelled || self.code == NSURLErrorUserCancelledAuthentication || self.code == NSURLErrorZeroByteResource || self.code == NSURLErrorServerCertificateHasBadDate || self.code == NSURLErrorServerCertificateUntrusted || self.code == NSURLErrorServerCertificateHasUnknownRoot || self.code == NSURLErrorServerCertificateNotYetValid || self.code == NSURLErrorClientCertificateRejected || self.code == NSURLErrorClientCertificateRequired || self.code == NSURLErrorCannotLoadFromNetwork) return YES;
	}
	return NO;
}
@end
