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

static NSInteger				g_alertsVisible = 0;

NSMutableArray			*s_displayedAlerts = nil;

@interface SA_AlertViewImplementation: UIAlertView
@property (nonatomic, copy) booleanArgumentBlock alertCancelButtonHitBlock;
@property (nonatomic, copy) intArgumentBlock alertButtonHitBlock;

+ (SA_AlertViewImplementation *) alertWithTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag button: (NSString *) buttonTitle;
+ (SA_AlertViewImplementation *) showAlertWithTitle: (NSString *)title message: (NSString *)message tag: (NSUInteger) tag delegate: (id) delegate button: (NSString *) buttonTitle;
@end

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

+ (id) showAlertWithException: (NSException *) e {
	return [self showAlertWithTitle: [e name] message: [e reason]];
}

+ (id) showAlertWithTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag {
	return [self showAlertWithTitle: title message: message tag: tag delegate: nil button: nil];
}

+ (id) showAlertWithTitle: (NSString *) title message: (NSString *) message, ... {
	va_list					list;
	NSString				*fullMessage = @"";
	
	if (message) {
		va_start(list, message);
		fullMessage = [[NSString alloc] initWithFormat: message arguments: list];
		va_end(list);
	}

	return [self showAlertWithTitle: title message: fullMessage tag: 0];
}

+ (id) showAlertWithTitle: (NSString *) title	error: (NSError *) error {
	return [self showAlertWithTitle: title message: [error fullDescription]];
}

+ (id) showAlertWithTitle: (NSString *)title message: (NSString *)message tag: (NSUInteger) tag delegate: (id) delegate button: (NSString *) buttonTitle {
	return [SA_AlertViewImplementation showAlertWithTitle: title message: message tag: tag delegate: delegate button: buttonTitle];
}

//=============================================================================================================================
#pragma mark Please Wait interactions

//=============================================================================================================================
+ (id) showAlertWithTitle: (NSString *)title message: (NSString *) message button: (NSString *) button buttonBlock: (booleanArgumentBlock) buttonHitBlock {
	if (![NSThread isMainThread]) {
		dispatch_async_main_queue(^{
			[self showAlertWithTitle: title message: message button: button buttonBlock: buttonHitBlock];
		});
		return nil;
	}
	SA_AlertViewImplementation				*alert = [SA_AlertViewImplementation showAlertWithTitle: title message: message tag: 0 delegate: nil button: button];
	
	alert.delegate = alert;
	alert.alertCancelButtonHitBlock = (buttonHitBlock);
	return alert;
}

+ (id) showAlertWithTitle: (NSString *)title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (intArgumentBlock) buttonHitBlock {
	if (![NSThread isMainThread]) {
		dispatch_async_main_queue(^{
			[self showAlertWithTitle: title message: message buttons: buttons buttonBlock: buttonHitBlock];
		});
		return nil;
	}

	SA_AlertViewImplementation			*alert = [[SA_AlertViewImplementation alloc] initWithTitle: title ?: @"" message: message ?: @"" delegate: nil cancelButtonTitle: nil otherButtonTitles: nil];
	
	for (NSString *title in buttons) [alert addButtonWithTitle: title];
	
	alert.delegate = alert;
	alert.alertButtonHitBlock = (buttonHitBlock);
	[alert performSelector: @selector(showOnMainThread) withObject: nil afterDelay: 0.0];
	return alert;
}

- (void) dismissWithClickedButtonIndex: (NSInteger) buttonIndex animated: (BOOL) animated {}
- (void) clearAlertCancelButtonHitBlock {}

- (void) cancel {}
@end

@implementation SA_AlertViewImplementation
- (void) cancel {
	[self dismissWithClickedButtonIndex: self.cancelButtonIndex animated: NO];
}

- (void) clearAlertCancelButtonHitBlock {
	self.alertCancelButtonHitBlock = nil;
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
	
	[super show];
}

- (void) dealloc {
	g_alertsVisible--;
	if (g_alertsVisible == 0) [SA_PleaseWaitDisplay pleaseWaitDisplay].view.alpha = 1.0;
	[s_displayedAlerts removeObject: @(self.tag)];
}


- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex {
	if (self.alertCancelButtonHitBlock) self.alertCancelButtonHitBlock(buttonIndex == alertView.cancelButtonIndex);
	if (self.alertButtonHitBlock) self.alertButtonHitBlock(buttonIndex);
	
	self.alertButtonHitBlock = nil;
	self.alertCancelButtonHitBlock = nil;
}

//=============================================================================================================================
#pragma mark Properties
- (void) setAlertButtonHitBlock: (intArgumentBlock) alertButtonHitBlock {
	_alertButtonHitBlock = (alertButtonHitBlock);
	self.delegate = self;
}

- (void) setAlertCancelButtonHitBlock: (booleanArgumentBlock) alertCancelButtonHitBlock {
	_alertCancelButtonHitBlock = (alertCancelButtonHitBlock);
	self.delegate = self;
}

+ (SA_AlertViewImplementation *) alertWithTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag button: (NSString *) buttonTitle {
	if ([s_displayedAlerts containsObject: @(tag)]) return nil;
	
	if (message == nil) message = @"";
	if (title == nil) title = @"";
	
	NSString						*cancelTitle = buttonTitle.length ? NSLocalizedString(@"Cancel", @"Cancel") : NSLocalizedString(@"OK", @"OK");
	SA_AlertViewImplementation			*alert = [[SA_AlertViewImplementation alloc] initWithTitle: title message: message delegate: nil cancelButtonTitle: cancelTitle otherButtonTitles: buttonTitle, nil];
	
	alert.tag = tag;
	if (tag) {
		if (s_displayedAlerts == nil) s_displayedAlerts = [[NSMutableArray alloc] init];
		[s_displayedAlerts addObject: @(tag)];
	}
	return alert;
}

+ (SA_AlertViewImplementation *) showAlertWithTitle: (NSString *)title message: (NSString *)message tag: (NSUInteger) tag delegate: (id) delegate button: (NSString *) buttonTitle {
	if (![NSThread isMainThread]) {
		dispatch_async_main_queue(^{
			[self showAlertWithTitle: title message: message tag: tag delegate: delegate button: buttonTitle];
		});
		return nil;
	}
	SA_AlertViewImplementation		*alert = [SA_AlertViewImplementation alertWithTitle: title message: message tag: tag button: buttonTitle];
	
	alert.delegate = delegate;
	[alert performSelector: @selector(showOnMainThread) withObject: nil afterDelay: 0.0];
	return alert;
}

@end