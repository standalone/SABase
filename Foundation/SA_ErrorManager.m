//
//  SA_ErrorManager.m
//  Crosswords iOS
//
//  Created by Ben Gottlieb on 7/12/13.
//
//

#import "SA_ErrorManager.h"
#import "NSError+SA_Additions.h"
#import <UIKit/UIKit.h>
#import "SA_AlertView.h"
#import "UIViewController+SA_Additions.h"
@import SA_Base;

@implementation SA_ErrorManager
SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(SA_ErrorManager, defaultManager);

- (id) init {
	if (self = [super init]) {
		self.filterLevel = SA_Error_Filter_Level_NormalUse;
	}
	return self;
}

- (void) handleError: (NSError *) error withTitle: (NSString *) title devNote: (NSString *) devNote ofLevel: (SA_Error_Level) level {
	if (error == nil) return;
	
	if (self.filterLevel != SA_Error_Level_User) {
		NSLog(@"****** Error Received: %@ (%@) ********\n%@%@%@\n", title, [SA_ErrorManager convertErrLevelToString: level], devNote ?: @"", devNote.length ? @"\n" : @"", error);
	
		if (error.isNoInternetConnectionError) return;
	}
	if (self.filterLevel < (int) level) return;
	[self reportTitle: title error: error devNote: devNote];
}

- (void) handleMessage: (NSString *) message devNote: (NSString *) devNote ofLevel: (SA_Error_Level) level {
	[self handleMessage: message withTitle: nil devNote: devNote ofLevel: level];
}

- (void) handleMessage: (NSString *) message withTitle: (NSString *) title devNote: (NSString *) devNote ofLevel: (SA_Error_Level) level {
	if (message == nil) return;
	if (self.filterLevel != SA_Error_Level_User) {
		NSLog(@"****** Message Received: %@ (%@) ********\n%@%@%@\n", title ?: @"", [SA_ErrorManager convertErrLevelToString: level], devNote ?: @"", devNote.length ? @"\n" : @"", message);
	}

	if (self.filterLevel < (int) level) return;
	[self reportTitle: title message: message devNote: devNote];
}

- (void) reportTitle: (NSString *) title message: (NSString *) message devNote: (NSString *) devNote {
	
	if (self.delegate && [self.delegate respondsToSelector: _cmd])
		[self.delegate reportTitle: title message: message devNote: devNote];
	else
		[[self alertClass] showAlertIn: [UIViewController frontmostViewController] withTitle: title message: message];
}

- (void) reportTitle: (NSString *) title error: (NSError *) error devNote: (NSString *) devNote {
//	if (error.shouldProbablyBeSupressedForMostUsers) return;
	
	dispatch_async_main_queue(^{
		if (self.delegate && [self.delegate respondsToSelector: _cmd])
			[self.delegate reportTitle: title error: error devNote: devNote];
		else
			[[self alertClass] showAlertIn: [UIViewController frontmostViewController] withTitle: title error: error];
	});
}

- (Class) alertClass { return _alertClass ?: [SA_AlertView class]; }


+ (NSString *) convertErrLevelToString: (SA_Error_Level) level {
	static NSArray		*strings = nil;
	if (strings == nil) strings = @[ @"Low", @"User Testing", @"Developer Testing", @"Verbose" ];
	return strings[level];
}

@end
