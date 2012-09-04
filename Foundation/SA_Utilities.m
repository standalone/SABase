//
//  SA_Utilities.m
//
//  Created by Ben Gottlieb on 7/2/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import "SA_Utilities.h"
#import <Foundation/Foundation.h>
#import <mach/mach.h>
#import <mach/mach_host.h>

#if TARGET_OS_IPHONE
	#import "UIDevice+SA_Additions.h"
	#import "SA_AlertView.h"
#endif

const CGPoint		CGPointNone = {-10001.10001, -10001.10001};			


//id			dictof(const struct dictpair* pairs, size_t count, BOOL makeMutable) {
//	id					objects[count], keys[count];
//	size_t				i, n = 0;
//	
//	for (i = 0; i < count; i++,pairs++) {
//		if (pairs->value) {
//			objects[n] = pairs->value;
//			keys[n] = pairs->key;
//			n++;
//		}
//	}
//	
//    if (makeMutable) return [NSMutableDictionary dictionaryWithObjects: objects forKeys: keys count: n];
//    return [NSDictionary dictionaryWithObjects: objects forKeys: keys count: n];
//}

BOOL			EQUAL(id obj1, id obj2) {
	if (obj1 == nil) return (obj2 == nil);
	return [obj1 isEqual: obj2];
}

NSValue*	box(const void *value, const char *encoding) {
	// http://developer.apple.com/documentation/DeveloperTools/gcc-4.0.1/gcc/Type-encoding.html
	char e = encoding[0];
	if ( e == 'r') e = encoding[1];               // ignore 'const' modifier
	switch(e) {
		case 'c':   return [NSNumber numberWithChar: *(char *) value];
		case 'C':   return [NSNumber numberWithUnsignedChar: *(char *) value];
		case 's':   return [NSNumber numberWithShort: *(short *) value];
		case 'S':   return [NSNumber numberWithUnsignedShort: *(unsigned short *) value];
		case 'i':   return [NSNumber numberWithInt: *(int *) value];
		case 'I':   return [NSNumber numberWithUnsignedInt: *(unsigned int *) value];
		case 'l':   return [NSNumber numberWithLong: *(long *) value];
		case 'L':   return [NSNumber numberWithUnsignedLong: *(unsigned long *) value];
		case 'q':   return [NSNumber numberWithLongLong: *(long long *) value];
		case 'Q':   return [NSNumber numberWithUnsignedLongLong: *(unsigned long long *) value];
		case 'f':   return [NSNumber numberWithFloat: *(float *) value];
		case 'd':   return [NSNumber numberWithDouble: *(double *) value];
		case '*':   return [NSString stringWithUTF8String: *(char **) value];
		//case '@':   return *(id *) value;
		default:    return [NSValue value: value withObjCType: encoding];
	}
}

natural_t			freeMemory(BOOL logIt) {
//    mach_port_t					host_port = mach_host_self();
//    mach_msg_type_number_t		host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
//    vm_size_t					pagesize;
//    vm_statistics_data_t		vm_stat;
//    
//    host_page_size(host_port, &pagesize);        
//	
//	
//    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) NSLog(@"Failed to fetch vm statistics");
//	
//    /* Stats in bytes */ 
//    natural_t					mem_used = (vm_stat.active_count + vm_stat.inactive_count + vm_stat.wire_count) * pagesize;
//    natural_t					mem_free = vm_stat.free_count * pagesize;
//    natural_t					mem_total = mem_used + mem_free;
//    if (logIt) NSLog(@"used: %uk free: %uk total: %uk", mem_used / 1024, mem_free / 1024, mem_total / 1024);
	if (logIt) LOG(@"Logging memory no longer supported");
	#if TARGET_OS_IPHONE
		return [UIDevice availableMemory];
	#endif
	return -1;
}

void			MailDataWithTitle(NSData *data, NSString *title) {
	NSURL						*url = [NSURL URLWithString: [NSString stringWithFormat: @"http://www.standalone.com/cgi/relay_file.cgi?name=%@", title]];
	NSMutableURLRequest			*request = [NSMutableURLRequest requestWithURL: url];
	
	if (data) {
		[request setHTTPBody: data];
		[request setHTTPMethod: @"POST"];
	}
	
	[NSURLConnection connectionWithRequest: request delegate: nil];
}

#if TARGET_OS_IPHONE
	void						displayAlert(NSString *title, NSString *message) {
		[SA_AlertView showAlertWithTitle: title message: message];
	}
#endif

#if TARGET_OS_IPHONE
NSString *		NSStringFromInterfaceOrientation(UIInterfaceOrientation orientation) {
	NSString			*labels[] = {
		    @"UIDeviceOrientationUnknown",
			@"UIDeviceOrientationPortrait",
			@"UIDeviceOrientationPortraitUpsideDown",
			@"UIDeviceOrientationLandscapeLeft",
			@"UIDeviceOrientationLandscapeRight",
			@"UIDeviceOrientationFaceUp",
			@"UIDeviceOrientationFaceDown"};	
			
					
	return labels[orientation];
}
#endif

NSString *				NSStringFromCGColor(CGColorRef color) {
	size_t					componentCount = CGColorGetNumberOfComponents(color);
	const CGFloat			*comp = CGColorGetComponents(color);
	
	if (componentCount == 2) return $S(@"White: %.0f, a: %.0f", comp[0], comp[1]);
	
	if (componentCount != 4) return $S(@"not an RGB color (%d comp)", (int) componentCount);
	return $S(@"R: %.0f, G: %.0f, B: %.0f, a: %.0f", comp[0], comp[1], comp[2], comp[3]);
}


//=============================================================================================================================
#pragma mark Logging
NSString *		RedirectedFilePath(void) {
	NSArray			*paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString			*documentsDirectory = [paths objectAtIndex:0];
	NSString			*logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
	
	return logPath;
}

void		RedirectConsoleLogToDocumentFolder(void) {

	freopen([RedirectedFilePath() cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

void ClearConsoleLog(void) {
	NSError									*error = nil;
	[[NSFileManager defaultManager] removeItemAtPath: RedirectedFilePath() error: &error];
	RedirectConsoleLogToDocumentFolder();
}

#if TARGET_OS_IPHONE
//=============================================================================================================================
#pragma mark Frame Conversion
CGRect ConvertFrameFromPortraitToLandscape(CGRect frame) {	
	CGRect					screenBounds = [[UIScreen mainScreen] bounds];
	float					statusBarHeight = MIN([UIApplication sharedApplication].statusBarFrame.size.height, [UIApplication sharedApplication].statusBarFrame.size.width);
	CGRect					currentScreenBounds = CGRectMake(0, statusBarHeight, MIN(screenBounds.size.width, screenBounds.size.height), MAX(screenBounds.size.width, screenBounds.size.height) - statusBarHeight);
	CGRect					newScreenBounds = CGRectMake(0, statusBarHeight, MAX(screenBounds.size.width, screenBounds.size.height), MIN(screenBounds.size.width, screenBounds.size.height) - statusBarHeight);
	
	float					rightMargin = currentScreenBounds.size.width - CGRectGetMaxX(frame);
	float					bottomMargin = currentScreenBounds.size.height - CGRectGetMaxY(frame);
	
	BOOL					pinnedToLeft = ABS(frame.origin.x) <= 50;
	BOOL					pinnedToRight = ABS(rightMargin) <= 50;
	BOOL					pinnedToTop = ABS(frame.origin.y) <= 50;
	BOOL					pinnedToBottom = ABS(bottomMargin) <= 50;
	
	float					fractionX = CGRectCenter(frame).x / currentScreenBounds.size.width, fractionY = CGRectCenter(frame).y / currentScreenBounds.size.height;
	
	CGRect					newFrame = frame;
	
	if (pinnedToLeft)
		newFrame.origin.x = frame.origin.x;
	else if (pinnedToRight) 
		newFrame.origin.x = newScreenBounds.size.width - (frame.size.width + rightMargin);
	else
		newFrame.origin.x = newScreenBounds.size.width * fractionX - newFrame.size.width / 2;
	
	
	if (pinnedToTop)
		newFrame.origin.y = frame.origin.y;
	else if (pinnedToBottom) 
		newFrame.origin.y = newScreenBounds.size.height - (frame.size.height + bottomMargin);
	else
		newFrame.origin.y = newScreenBounds.size.height * fractionY - newFrame.size.height / 2;
	
	return newFrame;
}

CGRect ConvertFrameFromLandscapeToPortrait(CGRect frame) {	
	CGRect					screenBounds = [[UIScreen mainScreen] bounds];
	float					statusBarHeight = MIN([UIApplication sharedApplication].statusBarFrame.size.height, [UIApplication sharedApplication].statusBarFrame.size.width);
	CGRect					currentScreenBounds = CGRectMake(0, statusBarHeight, MAX(screenBounds.size.width, screenBounds.size.height), MIN(screenBounds.size.width, screenBounds.size.height) - statusBarHeight);
	CGRect					newScreenBounds = CGRectMake(0, statusBarHeight, MIN(screenBounds.size.width, screenBounds.size.height), MAX(screenBounds.size.width, screenBounds.size.height) - statusBarHeight);
	
	BOOL					pinnedToLeft = ABS(frame.origin.x) <= 50;
	BOOL					pinnedToRight = ABS((frame.origin.x + frame.size.width) - currentScreenBounds.size.width) <= 50;
	BOOL					pinnedToTop = ABS(frame.origin.y) <= 50;
	BOOL					pinnedToBottom = ABS((frame.origin.y + frame.size.height) - currentScreenBounds.size.height) <= 50;
	
	float					fractionX = CGRectCenter(frame).x / currentScreenBounds.size.width, fractionY = CGRectCenter(frame).y / currentScreenBounds.size.height;
	
	CGRect					newFrame = frame;
	
	if (pinnedToLeft)
		newFrame.origin.x = frame.origin.x;
	else if (pinnedToRight) 
		newFrame.origin.x = newScreenBounds.size.width - (frame.size.width + (currentScreenBounds.size.width - (frame.origin.x + frame.size.width)));
	else
		newFrame.origin.x = newScreenBounds.size.width * fractionX - newFrame.size.width / 2;
	
	
	if (pinnedToTop)
		newFrame.origin.y = frame.origin.y;
	else if (pinnedToBottom) 
		newFrame.origin.y = newScreenBounds.size.height - (frame.size.height + (currentScreenBounds.size.height - (frame.origin.y + frame.size.height)));
	else
		newFrame.origin.y = newScreenBounds.size.height * fractionY - newFrame.size.height / 2;
	
	return newFrame;
}

CGSize	CGSizeScaledWithinLimitSize(CGSize size, CGSize limitSize) {
	float				myAspectRatio = size.width / size.height;
	float				incomingAspectRatio = limitSize.width / limitSize.height;
	CGSize				calculatedSize = limitSize;
	
	if (myAspectRatio < incomingAspectRatio) {				//we are skinnier than they are, there will be size margins, height will be what's passed in
		calculatedSize.width = limitSize.height * myAspectRatio;
	} else {												//we are fatter than they are, there will be top/bottom margins, width will be what's passed in
		calculatedSize.height = limitSize.width / myAspectRatio;
	}
	
	return calculatedSize;	
}

CGRect	CGRectPlacedInRectWithContentMode(CGRect child, CGRect parent, UIViewContentMode mode) {
	CGSize					newSize = child.size;
	CGRect					newRect = parent;
	CGFloat					delta = 0.0;
	
	switch (mode) {
		case UIViewContentModeScaleToFill: newSize = parent.size; break;			//just draw the image in the rect. done.
		case UIViewContentModeScaleAspectFill:     // contents scaled to fill with fixed aspect. some portion of content may be clipped.
			newSize = CGSizeScaledWithinLimitSize(child.size, parent.size);
			if (newSize.height < newRect.size.height) {			//image is too short to fit. 
				delta = newSize.width * (newRect.size.height / newSize.height) - newSize.width;
				newSize.width = newRect.size.width + delta;
				newSize.height = newRect.size.height;
				newRect.origin.x -= delta / 2;
			} else if (newSize.width < newRect.size.width) {
				delta = newSize.height * (newRect.size.width / newSize.width) - newSize.height;
				newSize.height = newRect.size.height + delta;
				newSize.width = newRect.size.width;
				newRect.origin.y -= delta / 2;
			}
			break;
			
		case UIViewContentModeScaleAspectFit:     // contents scaled to fit with fixed aspect. remainder is transparent.
			newSize = CGSizeScaledWithinLimitSize(child.size, parent.size);
			if (newSize.height < newRect.size.height) {			//image is too short to fit. 
				delta = newRect.size.height - newSize.height;
				newRect.origin.y += delta / 2;
			} else if (newSize.width < newRect.size.width) {
				delta = newRect.size.width - newSize.width;
				newRect.origin.x += delta / 2;
			}
			break;
			
		case UIViewContentModeRedraw: break;              // redraw on bounds change (calls -setNeedsDisplay)
		case UIViewContentModeCenter:
			newRect.origin.x += (newRect.size.width - newSize.width) / 2;
			newRect.origin.y += (newRect.size.height - newSize.height) / 2;
			break;
			
		case UIViewContentModeTop: 
			newRect.origin.x += (newRect.size.width - newSize.width) / 2;
			break;
			
		case UIViewContentModeBottom:
			newRect.origin.x += (newRect.size.width - newSize.width) / 2;
			newRect.origin.y += (newRect.size.height - newSize.height);
			break;
			
		case UIViewContentModeLeft:
			newRect.origin.y += (newRect.size.height - newSize.height) / 2;
			break;
			
		case UIViewContentModeRight:
			newRect.origin.x += (newRect.size.width - newSize.width);
			newRect.origin.y += (newRect.size.height - newSize.height) / 2;
			break;
			
		case UIViewContentModeTopLeft:
			break;
			
		case UIViewContentModeTopRight:
			newRect.origin.x += (newRect.size.width - newSize.width);
			break;
			
		case UIViewContentModeBottomLeft:
			newRect.origin.y += (newRect.size.height - newSize.height);
			break;
			
		case UIViewContentModeBottomRight:
			newRect.origin.x += (newRect.size.width - newSize.width);
			newRect.origin.y += (newRect.size.height - newSize.height);
			break;
			
	}
	
	newRect.size = newSize;
	return newRect;
}
#endif