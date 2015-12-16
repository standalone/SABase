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

+ (void) showAlertWithTitle: (NSString *)title message: (NSString *)message tag: (NSUInteger) tag delegate: (id) delegate button: (NSString *) buttonTitle;
+ (void) showAlertWithTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag;
+ (void) showAlertWithTitle: (NSString *) title message: (NSString *) message, ...;
+ (void) showAlertWithTitle: (NSString *) title	error: (NSError *) error;
+ (void) showAlertWithException: (NSException *) e;

+ (void) showAlertWithTitle: (NSString *)title message: (NSString *) message button: (NSString *) button buttonBlock: (booleanArgumentBlock) buttonHitBlock;
+ (void) showAlertWithTitle: (NSString *)title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (intArgumentBlock) buttonHitBlock;
@end


@interface NSError (SA_Alert) 
- (NSString *) fullDescription;
@end

