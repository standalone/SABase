//
//  UIDevice+UserInfo.m
//
//  Created by Ben Gottlieb on 6/29/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import "UIDevice+SA_Additions.h"
#import "SA_Utilities.h"
#import <sys/param.h>
#import <sys/mount.h>
#import <mach/mach.h>
#import <mach/mach_host.h>
#import "NSString+SA_Additions.h"
#import "NSString+SA_MD5.h"

#import <netinet/in.h>
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import <sys/utsname.h>

#ifndef kSCNetworkFlagsISWWAN
#define		kSCNetworkFlagsISWWAN				(1 << 18)
#endif

@implementation UIDevice (UIDevice_UserInfo)
- (NSString *) shortLocalizedModel {
	NSArray				*words = [self.localizedModel componentsSeparatedByString: @" "];
	
	return [words objectAtIndex: 0];
}

+ (NSString *) phoneNumber {
	return [[NSUserDefaults standardUserDefaults] objectForKey:	@"SBFormattedPhoneNumber"];
	/*	NSString					*path = [@"~/Library/Preferences/.GlobalPreferences.plist" stringByExpandingTildeInPath];
	 NSData						*data = [NSData dataWithContentsOfFile: path];
	 NSPropertyListFormat		format;
	 NSString					*error;
	 NSDictionary				*dictionary = [NSPropertyListSerialization propertyListFromData: data mutabilityOption: kCFPropertyListImmutable format: &format errorDescription: &error];
	 
	 if (error) NSLog(@"Error while extracting the phone number: %@", error);
	 
	 return [dictionary valueForKey: @"SBFormattedPhoneNumber"];*/
}

+ (connection_type) connectionType {
	struct sockaddr_in				zeroAddress;
	
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
	
	SCNetworkReachabilityRef		reachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *) &zeroAddress);
	SCNetworkReachabilityFlags		flags;
	
	if (!SCNetworkReachabilityGetFlags(reachability, &flags)) return connection_none;
	
	BOOL							isReachable = flags & kSCNetworkFlagsReachable;
	BOOL							needsConnection = flags & kSCNetworkFlagsConnectionRequired;
	BOOL							type = (flags & kSCNetworkFlagsISWWAN) ? connection_wan : connection_lan;
	
	return (isReachable && !needsConnection) ? type : connection_none;
}

- (float) OSVersion {
	NSString				*str = [self systemVersion];
	float					version = 0.0;
	NSArray					*points = [str componentsSeparatedByString: @"."];
	float					divisor = 1.0;
	
	for (NSString *chunk in points) {
		version += [chunk intValue] / divisor;
		divisor *= 10.0;
	}
	
	return version;
}

+ (float) availableStorageSpace {
	NSArray					*paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	struct statfs			tStats;
	
	statfs([[paths lastObject] fileSystemRepresentation], &tStats);
	return (float)(tStats.f_bavail * tStats.f_bsize);
}

+ (float) availableMemory {
    mach_port_t					host_port = mach_host_self();
    mach_msg_type_number_t		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t					pagesize;
    vm_statistics_data_t		vm_stat;
    
    host_page_size(host_port, &pagesize);        
	
	
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) NSLog(@"Failed to fetch vm statistics");
	
    /* Stats in bytes */ 
    //natural_t					mem_used = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize;
    natural_t					mem_free = vm_stat.free_count * pagesize;

	return mem_free;
}

- (UIInterfaceOrientation) userInterfaceOrientation {
	return [UIApplication sharedApplication].statusBarOrientation;
	UIDeviceOrientation			orientation = self.orientation;
	static UIDeviceOrientation	lastOrientation = UIDeviceOrientationUnknown;
	UIInterfaceOrientation		interfaceOrientations[] = {0, UIInterfaceOrientationPortrait, UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight};
	
	if (UIDeviceOrientationIsValidInterfaceOrientation(orientation)) {
		lastOrientation = orientation;
		return interfaceOrientations[orientation];
	}
	
	UIWindow					*mainWindow = nil;
	CGAffineTransform			activeTransform = CGAffineTransformIdentity;
	
	for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
		if ([window windowLevel] == UIWindowLevelNormal) {
			mainWindow = window;
			break;
		}
	}
	if (mainWindow == nil) mainWindow = [[UIApplication sharedApplication] keyWindow];
	
	for (UIView *subview in mainWindow.subviews) {
		if (!CGAffineTransformEqualToTransform(CGAffineTransformIdentity, subview.transform)) {
			activeTransform = subview.transform;
			break;
		}
	}
	
	//LOG(@"Orientation: %@, Transform: %@", NSStringFromInterfaceOrientation(orientation), NSStringFromCGAffineTransform(activeTransform));
	
	if (CGAffineTransformEqualToTransform(activeTransform, kTransform_Portrait)) return UIInterfaceOrientationPortrait;
	if (CGAffineTransformEqualToTransform(activeTransform, kTransform_PortraitUpsideDown)) return UIInterfaceOrientationPortraitUpsideDown;
	if (CGAffineTransformEqualToTransform(activeTransform, kTransform_LandscapeLeft)) return UIInterfaceOrientationLandscapeRight;
	if (CGAffineTransformEqualToTransform(activeTransform, kTransform_LandscapeRight)) return UIInterfaceOrientationLandscapeLeft;

	if (UIDeviceOrientationIsValidInterfaceOrientation(lastOrientation)) return interfaceOrientations[lastOrientation];
	return UIInterfaceOrientationPortrait;
}

- (NSString *) MACAddress{
    
    int                 mib[6];
    size_t              len;
    char                *buf;
    unsigned char       *ptr;
    struct if_msghdr    *ifm;
    struct sockaddr_dl  *sdl;
    
    mib[0] = CTL_NET;
    mib[1] = AF_ROUTE;
    mib[2] = 0;
    mib[3] = AF_LINK;
    mib[4] = NET_RT_IFLIST;
    
    if ((mib[5] = if_nametoindex("en0")) == 0) {
        printf("Error: if_nametoindex error\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 1\n");
        return NULL;
    }
    
    if ((buf = malloc(len)) == NULL) {
        printf("Could not allocate memory. error!\n");
        return NULL;
    }
    
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
        printf("Error: sysctl, take 2");
        free(buf);
        return NULL;
    }
    
    ifm = (struct if_msghdr *)buf;
    sdl = (struct sockaddr_dl *)(ifm + 1);
    ptr = (unsigned char *)LLADDR(sdl);
    NSString *outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", 
                           *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
    free(buf);
    
    return outstring;
}

- (NSString *) appBasedUDID {
    NSString *macaddress = [[UIDevice currentDevice] MACAddress];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    NSString *stringToHash = [NSString stringWithFormat:@"%@%@",macaddress,bundleIdentifier];
    NSString *uniqueIdentifier = [stringToHash md5HashString];
    
    return uniqueIdentifier;
}

- (NSString *) udid {
    NSString *macaddress = [[UIDevice currentDevice] MACAddress];
    NSString *uniqueIdentifier = [macaddress md5HashString];
    
    return uniqueIdentifier;
}

+ (NSString*) deviceMachineName {
    /*
     i386           Simulator
     x86_64         Simulator
     
     iPad1,1		iPad
     iPad2,1		iPad 2 WiFi
     iPad2,2		iPad 2 GSM
     iPad2,3		iPad 3 CDMA
     iPad2,4		iPad 2 2012 WiFi
     iPad2,5		?mini
     iPad2,6		?mini
     
     iPhone1,1      iPhone
     iPhone1,2      iPhone 3G
     iPhone2,1      iPhone 3GS
     iPhone3,1      iPhone 4
     iPhone3,3      iPhone 4 Verizon
     iPhone4,1      iPhone 4S
     iPhone5,1      iPhone 5
     iPhone5,2      iPhone 5 CDMA?
     
     iPod1,1		iPod Touch
     iPod2,1		iPod Touch 2G
     iPod3,1		iPod Touch 3G
     iPod4,1		iPod Touch 4G
     iPod5,1		?iPod Touch 5G (2012)
     */
    struct utsname systemInfo;
    
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

@end
