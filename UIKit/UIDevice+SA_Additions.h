//
//  UIDevice+UserInfo.h
//
//  Created by Ben Gottlieb on 6/29/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>

/*		-deviceMachineName
 i386           Simulator
 x86_64         Simulator
 
 iPad1,1		iPad
 iPad2,1		iPad 2 WiFi
 iPad2,2		iPad 2 GSM
 iPad2,3		iPad 3 CDMA
 iPad2,4		iPad 2 2012 WiFi
 iPad2,5		?mini
 iPad2,6		?mini
 
 iPad4,2		iPad air VZN
 iPad4,5		iPad mini retina VZN
 
 iPhone1,1      iPhone
 iPhone1,2      iPhone 3G
 iPhone2,1      iPhone 3GS
 iPhone3,1      iPhone 4
 iPhone3,3      iPhone 4 Verizon
 iPhone4,1      iPhone 4S
 iPhone5,1      iPhone 5
 iPhone5,2      iPhone 5 CDMA?
 iPhone6,1		iPhone 5s
 iPhone7,1		iPhone 6+
 iPhone7,2		iPhone 6
 
 iPod1,1		iPod Touch
 iPod2,1		iPod Touch 2G
 iPod3,1		iPod Touch 3G
 iPod4,1		iPod Touch 4G
 iPod5,1		?iPod Touch 5G (2012)
 
 
 */

typedef enum {
	connection_none,
	connection_wan,
	connection_lan
} connection_type;

#define					kTransform_Portrait				CGAffineTransformMake(1, 0, 0, 1, 0, 0)
#define					kTransform_PortraitUpsideDown	CGAffineTransformMake(-1, 0, 0, -1, 0, 0)
#define					kTransform_LandscapeLeft		CGAffineTransformMake(0, 1, -1, 0, 0, 0)
#define					kTransform_LandscapeRight		CGAffineTransformMake(0, -1, 1, 0, 0, 0)

@interface UIDevice (UIDevice_UserInfo)

@property (nonatomic, readonly) BOOL isHookedUpToDebugger;
@property (nonatomic, readonly) natural_t totalStorageSpace, availableStorageSpace, availableMemory;
@property (nonatomic, readonly) connection_type connectionType;
@property (nonatomic, readonly) NSString *deviceMachineName, *shortLocalizedModel, *displayName;
@property (nonatomic, readonly) float OSVersion;
@property (nonatomic, readonly) UIInterfaceOrientation userInterfaceOrientation;
@property (nonatomic, readonly) BOOL isInLandscapeOrientation;

@property (nonatomic, readonly) NSString *legacyUniqueIdentifier;

@end


@interface UIScreen (SA_Additions)
- (CGRect) currentFrameConsideringInterfaceOrientation;		//not working properly yet

@property (nonatomic, readonly) CGFloat sa_maxDimension, sa_minDimension;

@end
