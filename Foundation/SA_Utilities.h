//
//  SA_Utilities.h
//
//  Created by Ben Gottlieb on 7/2/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//
//	 Common #defines and utiliities useful in many projects
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define		DIM(a)				(sizeof(a) / sizeof(((a)[0])))
#define		FREE(p)				{if (p) { free(p); (p) = nil; }}
#define		SYNTHESIZE(_X_)		@synthesize _X_ = _##_X_;

#if DEBUG || AD_HOC
	#define		IF_NOT_PRODUCTION(...)				{__VA_ARGS__;}
	#define		IF_PRODUCTION(...)	
#else
	#define		IF_NOT_PRODUCTION(...)
	#define		IF_PRODUCTION(...)					{__VA_ARGS__;}
#endif

#if BUILD_USER_ben && (DEBUG || AD_HOC)
	#define		IF_IS_BENS_BUILD(...)					{__VA_ARGS__;}
#else
	#define		IF_IS_BENS_BUILD(...)					{}
#endif

#if DEBUG
	#define		IF_DEBUG(...)							{__VA_ARGS__;}
#else
	#define		IF_DEBUG(...)							{}
#endif

#if TARGET_IPHONE_SIMULATOR
	#define		IF_SIM(...)								{__VA_ARGS__;}
	#define		DISABLE_CORRECTIONS_FOR_TEXTFIELD_IN_SIM(tv)	{tv.autocapitalizationType = UITextAutocapitalizationTypeNone;tv.autocorrectionType = UITextAutocorrectionTypeNo;}
	#define		IF_DEVICE(...)							{}
#else
	#define		DISABLE_CORRECTIONS_FOR_TEXTFIELD_IN_SIM(tv)
	#define		IF_SIM(...)								{}
	#define		IF_DEVICE(...)							{__VA_ARGS__;}
#endif

#define				TRY(...)					@try {__VA_ARGS__;} @catch (id e) {LOG(@"Got exception: %@", e);}

#ifndef __has_feature
	#define __has_feature(x) 0
#endif


#define				OS_40_BUILD					(__IPHONE_OS_VERSION_MAX_ALLOWED >= 40000)
#define				OS_42_BUILD					(__IPHONE_OS_VERSION_MAX_ALLOWED >= 40200)
#define				OS_50_BUILD					(__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
#define				RUNNING_UNDER_ARC			((__has_feature(objc_arc)))
#define				NOT_RUNNING_UNDER_ARC		(!(RUNNING_UNDER_ARC))


//=============================================================================================================================
#pragma mark ARC conversion
#if NOT_RUNNING_UNDER_ARC
	#define			BEGIN_AUTORELEASEPOOL()		NSAutoreleasePool *__autoreleasePool = [[NSAutoreleasePool alloc] init];
	#define			END_AUTORELEASEPOOL()		[__autoreleasePool release];
	#define			CFBridgingRetain(p)			(p)
	#define			CFBridgingRelease(p)		(p)
	#define         RELEASE(p)                  {[p release]; p = nil;}
	#if !OS_50_BUILD && TARGET_OS_IPHONE
		#define         objc_retainedObject(p)      ((id) (p))
		#define			objc_unretainedObject(o)			((id) o) 
	#endif
	#define			STATIC_CONSTANT(type, name, value)		static type *name = nil; if (name == nil) name = [value retain];
	#define			IF_NOTARC(...)				{__VA_ARGS__;}
	#define			_retain						retain		
	#define			unsafe						assign
#else
	#define			BEGIN_AUTORELEASEPOOL()		@autoreleasepool {
	#define			END_AUTORELEASEPOOL()		}
	#define         RELEASE(p)                  
	#define			STATIC_CONSTANT(type, name, value)		static type *name = nil; if (name == nil) name = value;
	#define			IF_NOTARC(...)
	#define			autorelease					self
	#define			release						self
	#define			_retain						self
	#define			unsafe						unsafe_unretained
#endif

//=============================================================================================================================
#pragma mark Device/OS Info
#define			PRINTING_AVAILABLE				(OS_42_BUILD && [NSClassFromString(@"UIPrintInteractionController") performSelector: @selector(isPrintingAvailable)])

#if TARGET_OS_IPHONE
	#define				MULTITASKING_AVAILABLE			(([[UIDevice currentDevice] respondsToSelector: @selector(isMultitaskingSupported)]) && ([[UIDevice currentDevice] isMultitaskingSupported]))
	#define				MAJOR_OS_VERSION				([[UIDevice currentDevice].systemVersion intValue])
	#define				GCD_AVAILABLE					(RUNNING_ON_40)
	#define				RUNNING_ON_IPAD					(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	#define				RUNNING_ON_IPHONE				(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	#define				RUNNING_ON_40					([[UIDevice currentDevice].systemVersion intValue] >= 4)
	#define				RUNNING_ON_50					([[UIDevice currentDevice].systemVersion intValue] >= 5)
	#define				IS_RETINA_DEVICE				([UIScreen mainScreen].scale > 1.0)
	#define				IF_IOS(...)						{__VA_ARGS__;}
	#define				IF_MACOS(...)
#else
	#define				RUNNING_ON_40					NO
	#define				RUNNING_ON_50					NO
	#define				MULTITASKING_AVAILABLE			NO
	#define				MAJOR_OS_VERSION				10
	#define				GCD_AVAILABLE					YES
	#define				IF_IOS(...)
	#define				IF_MACOS(...)					{__VA_ARGS__;}
#endif
//=============================================================================================================================
#pragma mark String Conversion

#define			CharIsWhitespace(ch)			(ch == ' ' || ch == '\n' || ch == '\t' || ch == '\0')

//==========================================================================================
#pragma mark Logging			

void		RedirectConsoleLogToDocumentFolder(void);
NSString*	RedirectedFilePath(void);
void		ClearConsoleLog(void);


#if DEBUG
	#define			IS_DEVELOPER_BUILD								([[NSBundle mainBundle] pathForResource: @"DEVELOPER_BUILD" ofType: @"dat"].length > 0)
	#define			SA_Assert(condition, desc, ...)					IF_SIM(NSAssert(condition, desc, ##  __VA_ARGS__))
	#define			SA_AssertAndReturn(condition, desc, ...)		IF_SIM(NSAssert(condition, desc, ##  __VA_ARGS__)); if (!(condition)) return;
	#define			SA_AssertAndReturnNil(condition, desc, ...)		IF_SIM(NSAssert(condition, desc, ##  __VA_ARGS__)); if (!(condition)) return nil;

	#if TARGET_OS_IPHONE
		#define			SA_TRY(a)										@try {a;} @catch (id e) {[SA_AlertView showAlertWithException: e];}
	#else
		#define			SA_TRY(a)										@try {a;} @catch (id e) {LOG(@"%@", e);}
	#endif
#else
	#define			IS_DEVELOPER_BUILD								0
	#define			SA_Assert(condition, desc, ...)					if (!(condition)) LOG(desc)
	#define			SA_AssertAndReturn(condition, desc, ...)		if (!(condition)) {LOG(desc); return;}
	#define			SA_AssertAndReturnNil(condition, desc, ...)		if (!(condition)) {LOG(desc); return nil;}

	#define			SA_TRY(a)										@try {a;} @catch (id e) {}
#endif

#ifdef DDLogError
	#define		LOG				DDLogVerbose
	#define		LOG_ERR			DDLogError
#elif DEBUG || ADHOC
	#define		LOG				NSLog
	#define		LOG_ERR			NSLog
#else
	#define			LOG(...)					{}
	#define			LOG_ERR(...)				{}
#endif


#if DEBUG || AD_HOC
	#define			INIT_COUNT(_X_)				static int g_##_X_##_objectCount = 0;
	#define			INCR_COUNT(_X_)				if (g_##_X_##_objectCount++ > 0) NSLog(@"%d %@ objects created", g_##_X_##_objectCount, [_X_ class]);
	#define			DECR_COUNT(_X_)				g_##_X_##_objectCount--;

	#define			INCR_COUNT_LABELED(_X_, l)	if (g_##_X_##_objectCount++ > 0) NSLog(@"%d %@ instances created", g_##_X_##_objectCount, l);
	#define			DECR_COUNT_RELEASE(_X_, o)	if ([o retainCount] <= 1) g_##_X_##_objectCount--; RELEASE(o);

	#define			LOG_DATA(d, n)						[d writeToFile: [[NSString stringWithFormat: @"~/tmp/%@.txt", n] stringByExpandingTildeInPath] options: 0 error: nil]

	#define			DISPLAY_ALERT(t, m)			displayAlert(t, m);
#else
	#define			INIT_COUNT(_X_)
	#define			INCR_COUNT(_X_)
	#define			DECR_COUNT(_X_)

	#define			INCR_COUNT_LABELED(_X_, l)
	#define			DECR_COUNT_RELEASE(_X_, o)	RELEASE(o)

	#define			LOG_DATA(...)				{}
	#define			DISPLAY_ALERT(...)			{}
#endif

natural_t			freeMemory(BOOL logIt);
void				displayAlert(NSString *title, NSString *message);

#define				TIMING_START					NSDate			*__timing_start = [NSDate date];
#define				TIMING_LOG(s)					NSLog(@"%@ Took %.5f", s, ABS([__timing_start timeIntervalSinceNow]));

//==========================================================================================
#pragma mark Collection and Conversion
#define		ARRAY(OBJS...)     ({id objs[]={OBJS}; [NSArray arrayWithObjects: objs count: sizeof(objs)/sizeof(id)];})
#define		MARRAY(OBJS...)    ({id objs[]={OBJS}; [NSMutableArray arrayWithObjects: objs count: sizeof(objs)/sizeof(id)];})
#define		DICT(PAIRS...)     ({struct dictpair pairs[]={PAIRS}; dictof(pairs, DIM(pairs), NO);})
#define		MDICT(PAIRS...)    ({struct dictpair pairs[]={PAIRS};  dictof(pairs, DIM(pairs), YES);})

#define		OBJECT(VAL)        ({__typeof(VAL) v = (VAL); box(&v, @encode(__typeof(v)));})

#define		IS_KIND_OF(o, c)			([o isKindOf: [c class]])

#define		$D(...)						[NSDictionary dictionaryWithObjectsAndKeys: __VA_ARGS__, nil]
#define		$Dm(...)					[NSMutableDictionary dictionaryWithObjectsAndKeys: __VA_ARGS__, nil]
#define		$A(...)						[NSArray arrayWithObjects: __VA_ARGS__, nil]
#define		$Am(...)					[NSMutableArray arrayWithObjects: __VA_ARGS__, nil]
#define		$S(format, ...)				[NSString stringWithFormat: format, ##  __VA_ARGS__]
#define		$U(format, ...)				[NSURL URLWithString: [NSString stringWithFormat: format, ##  __VA_ARGS__]]
#define		$P(format, ...)				[NSPredicate predicateWithFormat: format, ##  __VA_ARGS__]
#define		$F(f)						[NSNumber numberWithFloat: f]
#define		$I(i)						[NSNumber numberWithInt: i]
#define		$B(b)						[NSNumber numberWithBool: b]
#define		$Vrect(r)					[NSValue valueWithCGRect: r]
#define		$Vpoint(x, y)				[NSValue valueWithCGPoint: CGPointMake(x, y)]
#define		$Vsize(w, h)				[NSValue valueWithCGSize: CGSizeMake(w, h)]
#define		$C(r, b, g, a)				[UIColor colorWithRed: r green: g blue: blue alpha: a]

BOOL		EQUAL(id obj1, id obj2);


#define		CGRectCenter(r)					(CGPointMake(CGRectGetMidX(r), CGRectGetMidY(r)))
#define		CGRectScale(r, xF, yF)			(CGRectMake(r.origin.x * xF, r.origin.y * yF, r.size.width * xF, r.size.height * yF))
#define		CGRectScaleAndCenter(r, xF, yF)	(CGRectMake(r.origin.x * xF + r.size.width * (1.0 - xF) * 0.5, r.origin.y * yF + r.size.height * (1.0 - yF) * 0.5, r.size.width * xF, r.size.height * yF))
#define		CGPointScale(p, xF, yF)			(CGPointMake(p.x * xF, p.y * yF))
#define		CGSizeScale(p, xF, yF)			(CGSizeMake(p.width * xF, p.height * yF))
#define		CGDistanceBetweenPoints(a, b)	(sqrt(pow(a.x - b.x, 2) + (pow(a.y - b.y, 2))))
#define		CGPointOffsetFromPoint(a, b)	(CGPointMake(a.x - b.x, a.y - b.y))
#define		CGPointAddPoint(a, b)			(CGPointMake(a.x + b.x, a.y + b.y))	
#define		CGPointSubtractPoint(a, b)		(CGPointMake(a.x - b.x, a.y - b.y))	
#define		CGRectIntegerize(r)				(CGRectMake(round(r.origin.x), round(r.origin.y), round(r.size.width), round(r.size.height)))
#define		CGSizeCenterInRect(s, r)		(CGRectMake(r.origin.x + (r.size.width - s.width) / 2, r.origin.y + (r.size.height - s.height) / 2, s.width, s.height))
#define		CGRectFromSize(s)				(CGRectMake(0, 0, s.width, s.height))
#define		CGRectMidpoint(r)				(CGPointMake(r.origin.x + r.size.width / 2, r.origin.y + r.size.height / 2))

#define		RAD_TO_DEG(r)					((r) * 360 / (2 * M_PI))
#define		DEG_TO_RAD(d)					((d) * (2 * M_PI) / 360)

#define		REPORT_ERROR(e, m)						if (e) LOG(@"Problem in %@ (%@): %@", NSStringFromSelector(_cmd), m, e)
#define		REPORT_ERROR_AND_RETURN(e, m)			if (e) {LOG(@"Problem in %@ (%@): %@", NSStringFromSelector(_cmd), m, e); return;}
#define		REPORT_ERROR_AND_RETURN_VALUE(e, m, v)	if (e) {LOG(@"Problem in %@ (%@): %@", NSStringFromSelector(_cmd), m, e); return v;}

#if TARGET_OS_IPHONE
CGSize CGSizeScaledWithinLimitSize(CGSize size, CGSize limitSize);
CGRect ConvertFrameFromPortraitToLandscape(CGRect frame);
CGRect ConvertFrameFromLandscapeToPortrait(CGRect frame);
CGRect CGRectPlacedInRectWithContentMode(CGRect child, CGRect parent, UIViewContentMode mode);
#endif

#define AssertCast(CLS_, OBJ_) ({ NSAssert2([(OBJ_) isKindOfClass:[CLS_ class]], @"Object %@ not of class %@", OBJ_, NSStringFromClass([CLS_ class])); (CLS_ *)(OBJ_); })

//==========================================================================================
#pragma mark Graphics
extern const CGPoint		CGPointNone;			


//==========================================================================================
#pragma mark Defines
typedef enum {dir_left, dir_up, dir_right, dir_down} direction;


//==========================================================================================
#pragma mark Private Structures/Functions
//struct					dictpair { id value, key; };
//id						dictof(const struct dictpair*, size_t count, BOOL makeMutable);
NSValue *				box(const void *value, const char *encoding);

#if TARGET_OS_IPHONE
	NSString *				NSStringFromInterfaceOrientation(UIInterfaceOrientation orientation);
#endif

NSString *				NSStringFromCGColor(CGColorRef color);


void					MailDataWithTitle(NSData *data, NSString *title);

#define				UIInterfaceOrientationUnknown				((UIInterfaceOrientation) 0)

#if BACKGROUND_THREAD_SUPPORT
	#warning BACKGROUND_THREAD_SUPPORT has been deprecated
#endif

#if NS_BLOCKS_AVAILABLE
	typedef void (^booleanArgumentBlock)(BOOL value);
	typedef void (^intArgumentBlock)(int integer);
	typedef void (^simpleBlock)(void);
	typedef void (^idArgumentBlock)(id arg);
	typedef void (^stringArgumentBlock)(NSString *arg);
	typedef void (^idErrorArgumentBlock)(id arg, NSError *error);
	typedef id (^idArgumentBlockReturningID)(id arg);
	typedef void (^simpleArrayBlock)(NSArray *array);
	#if TARGET_OS_IPHONE
		typedef void (^simpleImageBlock)(UIImage *image);
	 #endif
	#define				$BW(b)					([SA_BlockWrapper wrapperWithBlock: (simpleBlock) b])
#endif

#define SINGLETON_INTERFACE_FOR_CLASS_AND_METHOD(classname, methodName)			+ (classname *) methodName;
#define SINGLETON_INSTANCE_FOR_CLASS_AND_METHOD(classname, methodName)		(s_##methodName)

#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_4_0
	#define SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(classname, methodName) \
		static classname *s_##methodName = nil; \
		+ (classname *) methodName {\
			static dispatch_once_t  once; dispatch_once(&once, ^ { s_##methodName = [[self alloc] init]; });\
			return s_##methodName; \
		}

	#define	STATIC_OBJECT_PROPERTY(name, value)	- (id) name {static id name = nil; if (name == nil) {static dispatch_once_t  once; dispatch_once(&once, ^ { name = [value retain]; });}
#else
	#define SINGLETON_IMPLEMENTATION_FOR_CLASS_AND_METHOD(classname, methodName) \
		static classname *s_##methodName = nil; \
		+ (classname *) methodName {\
			if (RUNNING_ON_40) { static dispatch_once_t  once; dispatch_once(&once, ^ { s_##methodName = [[self alloc] init]; }); }\
			else @synchronized(self) { if (s_##methodName == nil) { s_##methodName = [[self alloc] init]; } } \
			return s_##methodName; \
		}

	#define SINGLETON_INSTANCE_FOR_CLASS_AND_METHOD(classname, methodName)		(s_##methodName)


	#define	STATIC_OBJECT_PROPERTY(name, value)	- (id) name {static id name = nil; if (name == nil) {\
		if (RUNNING_ON_40) { static dispatch_once_t  once; dispatch_once(&once, ^ { name = [value retain]; }); else name = [value retain]; return name;\
	}
#endif
