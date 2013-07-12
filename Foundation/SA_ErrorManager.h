//
//  SA_ErrorManager.h
//  Crosswords iOS
//
//  Created by Ben Gottlieb on 7/12/13.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt8, SA_Error_Level) {
	SA_Error_Level_User,
	SA_Error_Level_User_Testing,
	SA_Error_Level_Developer_Testing,
	SA_Error_Level_Verbose_Only
};

typedef NS_ENUM(UInt8, SA_Error_Filter_Level) {
	SA_Error_Filter_Level_NormalUse,
	SA_Error_Filter_Level_User_Testing,
	SA_Error_Filter_Level_Developer_Testing,
	SA_Error_Filter_Level_All
};

@protocol SA_ErrorManagerDelegate <NSObject>
@optional
- (void) reportTitle: (NSString *) title message: (NSString *) message devNote: (NSString *) devNote;
- (void) reportTitle: (NSString *) title error: (NSError *) error devNote: (NSString *) devNote;
@end

@interface SA_ErrorManager : NSObject
SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(SA_ErrorManager, defaultManager);

@property (nonatomic) SA_Error_Filter_Level filterLevel;
@property (nonatomic, unsafe_unretained) id <SA_ErrorManagerDelegate> delegate;

- (void) handleError: (NSError *) error withTitle: (NSString *) title devNote: (NSString *) devNote ofLevel: (SA_Error_Level) level;
- (void) handleMessage: (NSString *) message devNote: (NSString *) devNote ofLevel: (SA_Error_Level) level;
- (void) handleMessage: (NSString *) message withTitle: (NSString *) title devNote: (NSString *) devNote ofLevel: (SA_Error_Level) level;

- (void) reportTitle: (NSString *) title message: (NSString *) message devNote: (NSString *) devNote;
- (void) reportTitle: (NSString *) title error: (NSError *) error devNote: (NSString *) devNote;
@end
