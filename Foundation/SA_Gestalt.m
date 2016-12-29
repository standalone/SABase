//
//  SA_Gestalt.m
//  SABase
//
//  Created by Ben Gottlieb on 12/29/16.
//
//

#import "SA_Gestalt.h"

@implementation SA_Gestalt

+ (sa_provisioningType) provisioningType {
	NSURL		*recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
	NSString	*filename = [recepitURL lastPathComponent];
	
	if (s_DEBUG_mode) { return sa_provisioningTypeDevelopment; }
	if ([filename isEqualToString: @"sandboxReceipt"]) { return sa_provisioningTypeTestFlight; }
	
	return sa_provisioningTypeAppStore;
}

+ (BOOL) isInDebugger {
	return isatty(STDERR_FILENO) != 0;
}

@end
