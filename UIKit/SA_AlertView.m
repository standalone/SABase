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

static int				g_alertsVisible = 0;

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
+ (SA_AlertView *) showAlertWithException: (NSException *) e {
	return [self showAlertWithTitle: [e name] message: [e reason]];
}

+ (SA_AlertView *) showAlertWithTitle: (NSString *) title message: (NSString *) message tag: (int) tag {
	return [self showAlertWithTitle: title message: message tag: tag delegate: nil button: nil];
}

+ (SA_AlertView *) showAlertWithTitle: (NSString *) title message: (NSString *) message, ... {
	va_list					list;
	NSString				*fullMessage = @"";
	
	if (message) {
		va_start(list, message);
		fullMessage = [[NSString alloc] initWithFormat: message arguments: list];
		va_end(list);
	}

	return [self showAlertWithTitle: title message: fullMessage tag: 0];
}

+ (SA_AlertView *) showAlertWithTitle: (NSString *) title	error: (NSError *) error {
	return [self showAlertWithTitle: title message: [error fullDescription]];
}

+ (SA_AlertView *) showAlertWithTitle: (NSString *)title message: (NSString *)message tag: (int)tag delegate: (id) delegate button: (NSString *) buttonTitle {
	SA_AlertView		*alert = [self alertWithTitle: title message: message tag: tag button: buttonTitle];
	
	alert.delegate = delegate;
	[alert performSelectorOnMainThread: @selector(show) withObject: nil waitUntilDone: NO];
	return alert;
}

+ (SA_AlertView *) alertWithTitle: (NSString *) title message: (NSString *) message tag: (int) tag button: (NSString *) buttonTitle {
	if (tag && s_displayedAlerts) {
		for (SA_AlertView *alert in s_displayedAlerts) {
			if (alert.tag == tag) return nil;					//alert is already shown
		}
	}
	
	if (message == nil) message = @"";
	if (title == nil) title = @"";
	
	NSString						*cancelTitle = buttonTitle.length ? NSLocalizedString(@"Cancel", @"Cancel") : NSLocalizedString(@"OK", @"OK");
	SA_AlertView					*alert = [[[SA_AlertView alloc] initWithTitle: title message: message delegate: nil cancelButtonTitle: cancelTitle otherButtonTitles: buttonTitle, nil] autorelease];
	
	if (tag) {
		if (s_displayedAlerts == nil) s_displayedAlerts = [[NSMutableArray alloc] init];
		alert.tag = tag;
		[s_displayedAlerts addObject: alert];
	}
	return alert;
}

//=============================================================================================================================
#pragma mark Please Wait interactions

- (void) show {
	[SA_PleaseWaitDisplay pleaseWaitDisplay].view.alpha = 0.0;
	g_alertsVisible++;
	
	[super show];
}

- (void) dealloc {
	#if NS_BLOCKS_AVAILABLE
		self.alertButtonHitBlock = nil;
	#endif
	g_alertsVisible--;
	if (g_alertsVisible == 0) [SA_PleaseWaitDisplay pleaseWaitDisplay].view.alpha = 1.0;
	[super dealloc];
}

//=============================================================================================================================
#pragma mark Overrides
- (void) didMoveToSuperview {
	if (self.superview == nil) {
		[s_displayedAlerts removeObject: self];
	}
	[super didMoveToSuperview];
}

#if NS_BLOCKS_AVAILABLE
@synthesize alertButtonHitBlock = _alertButtonHitBlock;
+ (SA_AlertView *) showAlertWithTitle: (NSString *)title message: (NSString *) message button: (NSString *) button buttonBlock: (booleanArgumentBlock) buttonHitBlock {
	if (!GCD_AVAILABLE) return nil;
	
	SA_AlertView				*alert = [self showAlertWithTitle: title message: message tag: 0 delegate: nil button: button];
	
	alert.alertButtonHitBlock = (buttonHitBlock);
	return alert;
}

- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndex {
	if (self.alertButtonHitBlock) self.alertButtonHitBlock(buttonIndex == alertView.cancelButtonIndex);
}

- (void) setAlertButtonHitBlock: (booleanArgumentBlock) alertButtonHitBlock {
	if (_alertButtonHitBlock) Block_release(_alertButtonHitBlock);
	_alertButtonHitBlock = alertButtonHitBlock ? Block_copy(alertButtonHitBlock) : nil;
	self.delegate = self;
}
#endif

@end
