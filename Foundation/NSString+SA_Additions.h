//
//  NSString+SA_Additions.h
//
//  Created by Ben Gottlieb on 7/28/06.
//  Copyright 2006 Stand Alone, Inc.. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
#else 
	#import <AppKit/AppKit.h>
#endif

#define		CHAR_IS_NUMERIC(c)				(c >= '0' && c <= '9')
#define		CHAR_IS_NONNUMERIC(c)			(c < '0' || c > '9')
#define		CHAR_IS_ALPHA(c)				((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'))
#define		CHAR_IS_NONALPHA(c)				(!CHAR_IS_ALPHA(c))
#define		CHAR_IS_ALPHANUMERIC(c)			(CHAR_IS_ALPHA(c) || CHAR_IS_NUMERIC(c))
#define		CHAR_IS_NONALPHANUMERIC(c)		(!CHAR_IS_ALPHA(c) && !CHAR_IS_NUMERIC(c))


@interface NSString (SA_Additions)
@property (nonatomic, readonly) NSArray *characters;

+ (NSString *) tempFileNameWithSeed: (NSString *) seed ofType: (NSString *) type;
+ (NSString *) stringWithDuration: (float) seconds showingHours: (BOOL) showHours;
+ (NSString *) stringWithDuration: (float) fullSeconds showingHours: (BOOL) showHours showMinutes: (BOOL) showMinutes andSeconds: (BOOL) showSeconds;
+ (NSString *) stringWithData: (NSData *) data;
//+ (NSString *) stringWithFormat: (NSString *) format array: (NSArray *) arguments;

- (NSString *) stringByStrippingCharactersInSet: (NSCharacterSet *) set options: (int) options;

+ (NSString *) stringWithCGSize: (CGSize) size;
- (CGSize) CGSizeValue;

- (NSArray *) URLsContainedWithin;

- (NSArray *) componentsSeparatedByStringHeedingQuotes: (NSString *) string;
- (NSArray *) componentsSeparatedByCharactersInSetHeedingQuotes: (NSCharacterSet *) set;
- (BOOL) ensurePathExists;
- (BOOL) endsWith: (NSString *) suffix;
- (BOOL) endsWith: (NSString *) suffix options: (int) options;
- (NSRange) fullRange;
- (NSString *) stringByStrippingFirstNWords: (int) n;
- (NSString *) truncateToLength: (int) length;
- (NSInteger) numberOfOccurrencesOfString: (NSString *) string;
- (char *) UTF8StringCopy;
- (BOOL) isValidEmail;
- (BOOL) boolValue;

#if TARGET_OS_IPHONE
	- (NSString *) stringTruncatedToWidth: (float) width usingFont: (UIFont *) font addingElipsis: (BOOL) addingElipsis;
	- (CGSize) SA_sizeWithFont: (UIFont *) font;
	- (CGSize) SA_sizeWithFont: (UIFont *)font constrainedToSize: (CGSize) size lineBreakMode: (NSLineBreakMode) lineBreakMode;

	- (void) SA_drawAtPoint: (CGPoint) point withFont: (UIFont *) font color: (UIColor *) color;
	- (void) SA_drawInRect: (CGRect) rect withFont: (UIFont *) font color: (UIColor *) color;
	- (void) SA_drawInRect: (CGRect) rect withFont: (UIFont *) font lineBreakMode: (NSLineBreakMode) lineBreakMode alignment: (NSTextAlignment) alignment color: (UIColor *) color;

//	- (CGSize)drawAtPoint:(CGPoint)point forWidth:(CGFloat)width withFont:(UIFont *)font lineBreakMode:(NSLineBreakMode)lineBreakMode  NS_DEPRECATED_IOS(2_0, 7_0, "Use -drawInRect:withAttributes:") __TVOS_PROHIBITED;

#else
	- (CGSize) SA_sizeWithFont: (NSFont *) font;
	- (CGSize) SA_sizeWithFont: (NSFont *)font constrainedToSize: (CGSize) size lineBreakMode: (NSLineBreakMode) lineBreakMode;
	- (CGSize) sizeWithFont: (NSFont *) font;
#endif

- (NSString *) stringByConvertingXMLToUTF8;
- (NSString *) stringByConvertingUTF8ToXML;

- (BOOL) isEqualToName: (NSString *) name;
- (BOOL) containsCString: (const char *) string;
- (BOOL) startsWithCString: (const char *) string;
- (BOOL) containsNumber: (int) number;
- (BOOL) containsWord: (const char *) word;

- (NSString *) rot13;
- (NSString *) stringByStrippingTags;
- (NSString *) stringByStrippingHTMLTags;
- (id)objectAtIndexedSubscript:(NSUInteger)idx;

#if TARGET_OS_IPHONE
- (UIFont *) fontToFitInWidth: (CGFloat) width startingWith: (UIFont *) starting;
#endif
@end

#if TARGET_OS_IPHONE
@interface NSString (SA_NSStringDrawing)
- (CGSize) SA_sizeWithAttributes: (NSDictionary *) attrs;
- (void) SA_drawInRect: (CGRect) rect withAttributes: (NSDictionary *) attributes;
#if !OS_70_BUILD
- (void) drawAtPoint: (CGPoint) point withAttributes: (NSDictionary *) attrs;
- (void) drawInRect: (CGRect) rect withAttributes: (NSDictionary *) attrs;
- (CGRect) boundingRectWithSize: (CGSize) size options: (NSStringDrawingOptions) options attributes: (NSDictionary *) attributes context: (NSStringDrawingContext *) context;
#endif
@end
#endif


