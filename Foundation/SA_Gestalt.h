//
//  SA_Gestalt.h
//  SABase
//
//  Created by Ben Gottlieb on 12/29/16.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt8, sa_provisioningType) {
	sa_provisioningTypeDevelopment,
	sa_provisioningTypeTestFlight,
	sa_provisioningTypeAppStore
};

@interface SA_Gestalt : NSObject
@property (class, nonatomic, readonly) sa_provisioningType provisioningType;
@property (class, nonatomic, readonly) BOOL isInDebugger;
@property (class, nonatomic, readonly) BOOL isInExtension;
@end
