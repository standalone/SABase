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

@property (nonatomic, copy) booleanArgumentBlock alertCancelButtonHitBlock;
@property (nonatomic, copy) intArgumentBlock alertButtonHitBlock;
@property (nonatomic, strong) UIAlertController *alertController;

@property (nonatomic) NSInteger tag;

+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *)title message: (NSString *)message tag: (NSUInteger) tag delegate: (id) delegate button: (NSString *) buttonTitle;
+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag;
+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *) title message: (NSString *) message, ...;
+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *) title	error: (NSError *) error;
+ (id) showAlertIn: (UIViewController *) parent withException: (NSException *) e;

+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *)title message: (NSString *) message button: (NSString *) button buttonBlock: (booleanArgumentBlock) buttonHitBlock;
+ (id) showAlertIn: (UIViewController *) parent withTitle: (NSString *)title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (intArgumentBlock) buttonHitBlock;

- (void) dismissWithClickedButtonIndex: (NSInteger) buttonIndex animated: (BOOL) animated;
- (void) cancel;

- (instancetype) initWithTitle: (NSString *) title message: (NSString *) message buttons: (NSArray *) buttons buttonBlock: (intArgumentBlock) buttonHitBlock;
- (void) showIn: (UIViewController *) parent;

//+ (SA_AlertView *) alertWithTitle: (NSString *) title message: (NSString *) message tag: (NSUInteger) tag button: (NSString *) buttonTitle;
@end


@interface NSError (SA_Alert) 
- (NSString *) fullDescription;
@end

