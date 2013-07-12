//
//  SA_ErrorManager.h
//  Crosswords iOS
//
//  Created by Ben Gottlieb on 7/12/13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt8, SA_Error_Level) {
	SA_Error_Level_Low,
	SA_Error_Level_User_Testing,
	SA_Error_Level_Developer_Testing,
	SA_Error_Level_Verbose_Only
};

@interface SA_ErrorManager : NSObject
SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(SA_ErrorManager, defaultManager);

@property (nonatomic) SA_Error_Level showErrorsOfLevelAndBelow;

- (void) handleError: (NSError *) error withTitle: (NSString *) title ofLevel: (SA_Error_Level) level;
- (void) handleMessage: (NSString *) message ofLevel: (SA_Error_Level) level;
- (void) handleMessage: (NSString *) message withTitle: (NSString *) title ofLevel: (SA_Error_Level) level;
@end
