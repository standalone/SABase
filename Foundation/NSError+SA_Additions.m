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
@end
