//
//  UIDevice+UserInfo.m
//
//  Created by Ben Gottlieb on 6/29/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//


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

- (connection_type) connectionType {
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

- (natural_t) totalStorageSpace {
	NSArray					*paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	struct statfs			tStats;
	
	statfs([[paths lastObject] fileSystemRepresentation], &tStats);
	return (natural_t) (tStats.f_blocks * tStats.f_bsize);
}

- (natural_t) availableStorageSpace {
	NSArray					*paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	struct statfs			tStats;
	
	statfs([[paths lastObject] fileSystemRepresentation], &tStats);
	return (natural_t) (tStats.f_bavail * tStats.f_bsize);
}

- (natural_t) availableMemory {
    mach_port_t					host_port = mach_host_self();
    mach_msg_type_number_t		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t					pagesize;
    vm_statistics_data_t		vm_stat;
    
    host_page_size(host_port, &pagesize);        
	
	
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) SA_BASE_LOG(@"Failed to fetch vm statistics");
	
    /* Stats in bytes */ 
    //natural_t					mem_used = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize;
    natural_t					mem_free = vm_stat.free_count * (natural_t) pagesize;

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
	
	//SA_BASE_LOG(@"Orientation: %@, Transform: %@", NSStringFromInterfaceOrientation(orientation), NSStringFromCGAffineTransform(activeTransform));
	
	if (CGAffineTransformEqualToTransform(activeTransform, kTransform_Portrait)) return UIInterfaceOrientationPortrait;
	if (CGAffineTransformEqualToTransform(activeTransform, kTransform_PortraitUpsideDown)) return UIInterfaceOrientationPortraitUpsideDown;
	if (CGAffineTransformEqualToTransform(activeTransform, kTransform_LandscapeLeft)) return UIInterfaceOrientationLandscapeRight;
	if (CGAffineTransformEqualToTransform(activeTransform, kTransform_LandscapeRight)) return UIInterfaceOrientationLandscapeLeft;

	if (UIDeviceOrientationIsValidInterfaceOrientation(lastOrientation)) return interfaceOrientations[lastOrientation];
	return UIInterfaceOrientationPortrait;
}

- (NSString *) deviceMachineName {
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

#if TARGET_IPHONE_SIMULATOR
	- (NSString *) displayName {
		struct			utsname name = {};
		uname(&name);
		
		return [NSString stringWithFormat:@"iOS Simulator: %s", name.nodename];
	}
#else
	- (NSString *) displayName { return [[UIDevice currentDevice] name]; }
#endif

- (BOOL) isHookedUpToDebugger {
	if (SA_Base_DebugMode()) {
		int                 junk;
		int                 mib[4];
		struct kinfo_proc   info;
		size_t              size;
		
		// Initialize the flags so that, if sysctl fails for some bizarre
		// reason, we get a predictable result.
		
		info.kp_proc.p_flag = 0;
		
		// Initialize mib, which tells sysctl the info we want, in this case
		// we're looking for information about a specific process ID.
		
		mib[0] = CTL_KERN;
		mib[1] = KERN_PROC;
		mib[2] = KERN_PROC_PID;
		mib[3] = getpid();
		
		// Call sysctl.
		
		size = sizeof(info);
		junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
		assert(junk == 0);
		
		// We're being debugged if the P_TRACED flag is set.
		
		return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
	}
	return NO;
}

- (NSString *) legacyUniqueIdentifier {
	if (RUNNING_ON_60) return self.identifierForVendor.UUIDString;
	
	SUPPRESS_LEAK_WARNING(return [self performSelector: NSSelectorFromString(@"uniqueIdentifier")];);
}

@end


@implementation UIScreen (SA_Additions)
- (CGRect) currentFrameConsideringInterfaceOrientation {
	CGRect				screenBounds = self.bounds;
	CGFloat				maxSize = MAX(screenBounds.size.width, screenBounds.size.height);
	CGFloat				minSize = MIN(screenBounds.size.width, screenBounds.size.height);
//	NSLog(@"Orientation: %d, maxSize: %.0f, minSize: %.0f", [UIDevice currentDevice].userInterfaceOrientation, maxSize, minSize);
	
	switch ([UIDevice currentDevice].userInterfaceOrientation) {
		case UIInterfaceOrientationPortrait:
		case UIInterfaceOrientationPortraitUpsideDown:
			return CGRectMake(0, 0, minSize, maxSize);
			
		case UIInterfaceOrientationLandscapeLeft:
		case UIInterfaceOrientationLandscapeRight:
			return CGRectMake(0, 0, maxSize, minSize);
	}
	return screenBounds;
}
@end
