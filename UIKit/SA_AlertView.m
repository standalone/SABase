//
//  SA_AlertView.m
//  
//
//  Created by Ben Gottlieb on 7/26/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import "SA_AlertView.h"
#import "SA_PleaseWaitDisplay.h"
#import "SA_Utilities.h"
#import "NSObject+SA_Additions.h"
#import "dispatch_additions_SA.h"
#import "UIViewController+SA_Additions.h"

static NSInteger				g_alertsVisible = 0;

NSMutableArray			*s_displayedAlerts = nil;

@implementation NSError (SA_Alert)

- (NSString *) fullDescription {
	NSString					*errorText = [self localizedDescription];
	
	for (NSString *key in self.userInfo) {
		if ([key isEqual: @"NSLocalizedDescription"]) continue;
		errorText = [NSString stringWithFormat: @"%@\n%@: %@", errorText, key, [self.userInfo valueForKey: key]];
	}
	return errorText;
}

@end


@implementation SA_AlertView

//=============================================================================================================================
#pragma mark Convenience Methods

+ (id) showAlertIn: (UIViewController *) parent withException: (NSException *) e {
	return [self showAlertIn: parent withTitle: [e name] message: [e reason]];
}

+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag {
	return [self showAlertIn: parent withTitle: title message: message tag: tag delegate: nil button: nil];
}

+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *) title message: (NSString *) message, ... {
	va_list					list;
	NSString				*fullMessage = @"";
	
	if (message) {
		va_start(list, message);
		fullMessage = [[NSString alloc] initWithFormat: message arguments: list];
		va_end(list);
	}

	return [self showAlertIn: parent withTitle: title message: fullMessage tag: 0];
}

+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *) title	error: (NSError *) error {
	return [self showAlertIn: parent withTitle: title message: [error fullDescription]];
}

+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *)title message: (NSString *)message tag: (NSUInteger) tag delegate: (id) delegate button: (NSString *) buttonTitle {
	return [SA_AlertView showAlertIn: parent withTitle: title message: message button: buttonTitle buttonBlock: ^(BOOL cancelled) {} ];
}

//=============================================================================================================================
#pragma mark Please Wait interactions

//=============================================================================================================================


+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *) title message: (NSString *) message button: (NSString *) button buttonBlock: (booleanArgumentBlock) buttonHitBlock {
	if (![NSThread isMainThread]) {
		dispatch_async_main_queue(^{
			[self showAlertIn: parent withTitle: title message: message button: button buttonBlock: buttonHitBlock];
		});
		return nil;
	}
	
	NSString						*cancelTitle = button.length ? NSLocalizedString(@"Cancel", @"Cancel") : NSLocalizedString(@"OK", @"OK");

	NSMutableArray				*buttons = [NSMutableArray array];
	
	if (button != nil) { [buttons addObject: button]; }
	[buttons addObject: cancelTitle];
	
	SA_AlertView				*alert = [SA_AlertView showAlertIn: parent withTitle: title message: message buttons: buttons buttonBlock:^(NSInteger index) {
		buttonHitBlock(index == 0);
	}];

	return alert;
}

+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *)title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (intArgumentBlock) buttonHitBlock {
	if (![NSThread isMainThread]) {
		dispatch_async_main_queue(^{
			[self showAlertIn: parent withTitle: title message: message buttons: buttons buttonBlock: buttonHitBlock];
		});
		return nil;
	}

	SA_AlertView			*alert = [[SA_AlertView alloc] initWithTitle: title message: message buttons: buttons buttonBlock: buttonHitBlock];
	

	dispatch_async_main_queue(^{ [alert showIn: parent]; });
	return alert;
}

- (void) showIn: (UIViewController *) parent {
	UIViewController			*presenter = parent ?: [UIViewController frontmostViewController];
	
	[presenter presentViewController: self.alertController animated: true completion: nil];
}

- (void) dismissWithClickedButtonIndex: (NSInteger) buttonIndex animated: (BOOL) animated {}


- (void) cancel {
	[self.alertController dismissViewControllerAnimated: true completion: nil];
}

- (void) showOnMainThread {
	[self performSelectorOnMainThread: @selector(show) withObject: nil waitUntilDone: NO];
}

- (void) show {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread: @selector(show) withObject: nil waitUntilDone: NO];
		return;
	}
	[SA_PleaseWaitDisplay pleaseWaitDisplay].view.alpha = 0.0;
	g_alertsVisible++;
	
	[self showIn: [UIViewController frontmostViewController]];
}

- (void) dealloc {
	g_alertsVisible--;
	if (g_alertsVisible == 0) [SA_PleaseWaitDisplay pleaseWaitDisplay].view.alpha = 1.0;
	[s_displayedAlerts removeObject: @(self.tag)];
}


//- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex {
//	if (self.alertCancelButtonHitBlock) self.alertCancelButtonHitBlock(buttonIndex == alertView.cancelButtonIndex);
//	if (self.alertButtonHitBlock) self.alertButtonHitBlock(buttonIndex);
//	
//	self.alertButtonHitBlock = nil;
//	self.alertCancelButtonHitBlock = nil;
//}

- (instancetype) initWithTitle: (NSString *) title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (intArgumentBlock) buttonHitBlock {
	if (self = [super init]) {
		self.alertController = [UIAlertController alertControllerWithTitle: title message: message preferredStyle: UIAlertControllerStyleAlert];
		
		for (int i = 0; i < buttons.count; i++) {
			if ([buttons[i] length] == 0) { continue; }
			[self.alertController addAction: [UIAlertAction actionWithTitle: buttons[i] style: UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				
				buttonHitBlock(i);
			}]];
		}
	}
	return self;
}

//=============================================================================================================================
#pragma mark Properties

//+ (SA_AlertView *) alertWithTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag button: (NSString *) buttonTitle {
//	if ([s_displayedAlerts containsObject: @(tag)]) return nil;
//	
//	if (message == nil) message = @"";
//	if (title == nil) title = @"";
//	
//	NSString						*cancelTitle = buttonTitle.length ? NSLocalizedString(@"Cancel", @"Cancel") : NSLocalizedString(@"OK", @"OK");
//	SA_AlertView			*alert = [[SA_AlertView alloc] initWithTitle: title message: message buttons: @[button, cancelTitle]] buttonBlock:^(NSInteger index) {
//		
//		if (index == 0) { }
//	}
//	
//	alert.tag = tag;
//	if (tag) {
//		if (s_displayedAlerts == nil) s_displayedAlerts = [[NSMutableArray alloc] init];
//		[s_displayedAlerts addObject: @(tag)];
//	}
//	return alert;
//}

//+ (SA_AlertView *) showAlertWithTitle: (NSString *)title message: (NSString *)message tag: (NSUInteger) tag delegate: (id) delegate button: (NSString *) buttonTitle {
//	if (![NSThread isMainThread]) {
//		dispatch_async_main_queue(^{
//			[self showAlertWithTitle: title message: message tag: tag delegate: delegate button: buttonTitle];
//		});
//		return nil;
//	}
//	SA_AlertView		*alert = [SA_AlertView alertWithTitle: title message: message tag: tag button: buttonTitle];
//	
//	dispatch_async_main_queue(^{ [alert show]; });
//	return alert;
//}

@end
