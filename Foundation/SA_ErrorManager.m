//
//  SA_ErrorManager.m
//  Crosswords iOS
//
//  Created by Ben Gottlieb on 7/12/13.
//
//

#import "SA_ErrorManager.h"

@implementation SA_ErrorManager
SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(SA_ErrorManager, defaultManager);
- (void) handleError: (NSError *) error withTitle: (NSString *) title ofLevel: (SA_Error_Level) level {
	if (self.showErrorsOfLevelAndBelow != SA_Error_Level_Low) {
		NSLog(@"****** Error Received: %@ (%@) ********\n%@\n", title, [SA_ErrorManager convertErrLevelToString: level], error);
	}
	if (self.showErrorsOfLevelAndBelow < level) return;
	[SA_AlertView showAlertWithTitle: title error: error];
}

- (void) handleMessage: (NSString *) message ofLevel: (SA_Error_Level) level {
	[self handleMessage: message withTitle: nil ofLevel: level];
}

- (void) handleMessage: (NSString *) message withTitle: (NSString *) title ofLevel: (SA_Error_Level) level {
	if (self.showErrorsOfLevelAndBelow != SA_Error_Level_Low) {
		NSLog(@"****** Message Received: %@ (%@) ********\n", title ?: @"", [SA_ErrorManager convertErrLevelToString: level]);
	}

	if (self.showErrorsOfLevelAndBelow < level) return;
	[SA_AlertView showAlertWithTitle: title message: message];
}






+ (NSString *) convertErrLevelToString: (SA_Error_Level) level {
	static NSArray		*strings = nil;
	if (strings == nil) strings = @[ @"Low", @"User Testing", @"Developer Testing", @"Verbose" ];
	return strings[level];
}

@end
