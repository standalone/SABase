//
//  SA_Alert.h
//  
//
//  Created by Ben Gottlieb on 7/26/09.
//  Copyright 2009 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SA_AlertView : UIAlertView {
}

#if NS_BLOCKS_AVAILABLE
	@property (nonatomic, copy) booleanArgumentBlock alertButtonHitBlock;
#endif


+ (SA_AlertView *) showAlertWithTitle: (NSString *)title message: (NSString *)message tag: (int)tag delegate: (id) delegate button: (NSString *) buttonTitle;
+ (SA_AlertView *) showAlertWithTitle: (NSString *) title message: (NSString *) message tag: (int) tag;
+ (SA_AlertView *) showAlertWithTitle: (NSString *) title message: (NSString *) message;
+ (SA_AlertView *) showAlertWithTitle: (NSString *) title	error: (NSError *) error;
+ (SA_AlertView *) showAlertWithException: (NSException *) e;

+ (SA_AlertView *) alertWithTitle: (NSString *)title message: (NSString *) message tag: (int) tag button: (NSString *) buttonTitle;

#if NS_BLOCKS_AVAILABLE
	+ (SA_AlertView *) showAlertWithTitle: (NSString *)title message: (NSString *) message button: (NSString *) button buttonBlock: (booleanArgumentBlock) buttonHitBlock;
#endif
@end


@interface NSError (SA_Alert) 
- (NSString *) fullDescription;
@end

