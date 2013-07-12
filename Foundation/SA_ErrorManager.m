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

- (id) init {
	if (self = [super init]) {
		self.filterLevel = SA_Error_Filter_Level_NormalUse;
	}
	return self;
}

- (void) handleError: (NSError *) error withTitle: (NSString *) title ofLevel: (SA_Error_Level) level {
	if (self.filterLevel != SA_Error_Level_User) {
		NSLog(@"****** Error Received: %@ (%@) ********\n%@\n", title, [SA_ErrorManager convertErrLevelToString: level], error);
	}
	if (self.filterLevel < (int) level) return;
	[self reportTitle: title error: error];
}

- (void) handleMessage: (NSString *) message ofLevel: (SA_Error_Level) level {
	[self handleMessage: message withTitle: nil ofLevel: level];
}

- (void) handleMessage: (NSString *) message withTitle: (NSString *) title ofLevel: (SA_Error_Level) level {
	if (self.filterLevel != SA_Error_Level_User) {
		NSLog(@"****** Message Received: %@ (%@) ********\n", title ?: @"", [SA_ErrorManager convertErrLevelToString: level]);
	}

	if (self.filterLevel < (int) level) return;
	[self reportTitle: title message: message];
}

- (void) reportTitle: (NSString *) title message: (NSString *) message {
	if (self.messageBlock)
		self.messageBlock(title, message);
	else
		[SA_AlertView showAlertWithTitle: title message: message];
}

- (void) reportTitle: (NSString *) title error: (NSError *) error {
	if (self.errorBlock)
		self.errorBlock(title, error);
	else
		[SA_AlertView showAlertWithTitle: title error: error];
}




+ (NSString *) convertErrLevelToString: (SA_Error_Level) level {
	static NSArray		*strings = nil;
	if (strings == nil) strings = @[ @"Low", @"User Testing", @"Developer Testing", @"Verbose" ];
	return strings[level];
}

@end
