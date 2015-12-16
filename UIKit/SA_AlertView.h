//
//  SA_Alert.h
//  
//
//  Created by Ben Gottlieb on 7/26/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SA_AlertView;

#define		SA_ALERT_CANCEL_BUTTON_INDEX				NSUIntegerMax

@interface SA_AlertView : NSObject

+ (id) showAlertWithTitle: (NSString *)title message: (NSString *)message tag: (NSUInteger) tag delegate: (id) delegate button: (NSString *) buttonTitle;
+ (id) showAlertWithTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag;
+ (id) showAlertWithTitle: (NSString *) title message: (NSString *) message, ...;
+ (id) showAlertWithTitle: (NSString *) title	error: (NSError *) error;
+ (id) showAlertWithException: (NSException *) e;

+ (id) showAlertWithTitle: (NSString *)title message: (NSString *) message button: (NSString *) button buttonBlock: (booleanArgumentBlock) buttonHitBlock;
+ (id) showAlertWithTitle: (NSString *)title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (intArgumentBlock) buttonHitBlock;

- (void) dismissWithClickedButtonIndex: (NSInteger) buttonIndex animated: (BOOL) animated;
- (void) clearAlertCancelButtonHitBlock;
- (void) cancel;
@end


@interface NSError (SA_Alert) 
- (NSString *) fullDescription;
@end

