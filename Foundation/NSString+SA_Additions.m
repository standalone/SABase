//
//  NSString+Additions.m
//
//  Created by Ben Gottlieb on 7/28/06.
//  Copyright 2006 Stand Alone, Inc.. All rights reserved.
//

#import "NSString+SA_Additions.h"
#import <CommonCrypto/CommonDigest.h>

@interface NSString_HTMLStringDelegate : NSObject<NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableArray* strings;

- (NSString *) getCharsFound;
@end

#if !OS_70_BUILD
#if !TARGET_OS_MAC
@interface NSString(NSStringDrawing)
- (CGSize) sizeWithAttributes: (NSDictionary *) attrs;
- (void) drawAtPoint: (CGPoint) point withAttributes: (NSDictionary *) attrs;
- (void) drawInRect: (CGRect) rect withAttributes: (NSDictionary *) attrs;
- (CGRect) boundingRectWithSize: (CGSize) size options: (NSStringDrawingOptions) options attributes: (NSDictionary *) attributes context: (NSStringDrawingContext *) context;
@end
#endif
#endif


@implementation NSString (SA_Additions)
@dynamic characters;

+ (NSString *) tempFileNameWithSeed: (NSString *) seed ofType: (NSString *) type {
    NSString *name = [NSString stringWithFormat:@"%d-%d",(int) [NSDate timeIntervalSinceReferenceDate], ((int) rand()) % 10000];
    if (seed && ![seed isEqualToString:@""]) {
        name = [NSString stringWithFormat:@"%@-%@", name, seed];
    }
    if (type && ![type isEqualToString:@""]) {
        name = [name stringByAppendingPathExtension:type];
    }
	return [NSTemporaryDirectory() stringByAppendingPathComponent: name];
}

+ (NSString *) stringWithData: (NSData *) data {
	return [[NSString alloc] initWithBytes: [data bytes] length: [data length] encoding: NSASCIIStringEncoding];
}

+ (NSString *) stringWithDuration: (float) fullSeconds showingHours: (BOOL) showHours {
	return [self stringWithDuration: fullSeconds showingHours: showHours showMinutes: YES andSeconds: YES];
}

+ (NSString *) stringWithDuration: (float) fullSeconds showingHours: (BOOL) showHours showMinutes: (BOOL) showMinutes andSeconds: (BOOL) showSeconds {
	int						seconds = fullSeconds;
	int						minutes = (seconds / 60);
	int						hours = (minutes / 60);
	
	minutes %= 60;
	seconds %= 60;
	
	NSString				*timeString = nil;
	
	if (showHours || hours > 0) {
		timeString = [NSString stringWithFormat: @"%02d:%02d", hours, minutes];
	} else if (showMinutes || minutes > 0) {
		timeString = [NSString stringWithFormat: @"%d", minutes];
	}
	
	if (showSeconds) return [timeString stringByAppendingFormat: @":%02d", seconds];
	return timeString;
}

+ (NSString *) stringWithCGSize: (CGSize) size {
	return [NSString stringWithFormat: @"%.10f,%.10f", size.width, size.height];
}

- (CGSize) CGSizeValue {
	NSArray				*components = [self componentsSeparatedByString: @","];
	
	if (components.count == 2) {
		float				width = [[components objectAtIndex: 0] floatValue];
		float				height = [[components objectAtIndex: 1] floatValue];
		
		return CGSizeMake(width, height);
	}
	return CGSizeZero;
}

- (BOOL) ensurePathExists {
	
#if (TARGET_OS_IPHONE) || (TARGET_OS_MAC && MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5) 
	NSError		*error = nil;
	BOOL		result = [[NSFileManager defaultManager] createDirectoryAtPath: self withIntermediateDirectories: YES attributes: nil error: &error];
	
	if (error) SA_BASE_LOG(@"Error while trying to create directory at \"%@\": %@", self, error);
	return result;
#else
	NSArray				*pathComponents;
	NSEnumerator		*iter;
	NSString			*component, *partialPath, *fileType, *path;
	NSFileManager		*fileMgr = [NSFileManager defaultManager];
	BOOL				isDirectory;
	NSDictionary		*attr;
	
	path = [self stringByStandardizingPath];
	
	pathComponents = [path pathComponents];
	iter = [pathComponents objectEnumerator];
	partialPath = [iter nextObject];
	
	while (component = [iter nextObject]) {
		partialPath = [partialPath stringByAppendingPathComponent: component];
		
		if (![fileMgr fileExistsAtPath: partialPath isDirectory: &isDirectory]) {		//create this path component
			[fileMgr createDirectoryAtPath: partialPath attributes: nil];
		} else
			if (!isDirectory) {
				attr = [fileMgr fileAttributesAtPath: partialPath traverseLink: YES];
				fileType = [attr objectForKey: NSFileType];
				if ([fileType isEqualToString: NSFileTypeSymbolicLink] || [fileType isEqualToString: NSFileTypeDirectory]) continue; 
				return NO;
			}
	}
#endif
	
	return YES;
}

- (char *) UTF8StringCopy {
	const char *utf8 = [self UTF8String];
	char *copy = calloc(strlen(utf8) + 1, 1);
	
	strcpy(copy, utf8);
	return copy;
}

- (BOOL) endsWith: (NSString *) suffix {
	return [self endsWith: suffix options: 0];
}

- (BOOL) endsWith: (NSString *) suffix options: (int) options {
	NSRange			range = [self rangeOfString: suffix options: options];
	
	if (range.location == NSNotFound) return NO;
	return ((range.location + range.length) == [self length]);
}

- (NSArray *) componentsSeparatedByStringHeedingQuotes: (NSString *) string {
	NSMutableArray			*results = [NSMutableArray array];
	NSInteger				position = 0, i, len = self.length;
	char					*raw = (char *) [self UTF8String];
	BOOL					inQuote = NO, inApos = NO;
	
	for (i = 0; i < len; i++) {
		if (raw[i] == '\'') inApos = !inApos;
		else if (raw[i] == '\"') inQuote = !inQuote;
		else if (!inApos && !inQuote && raw[i] == [string characterAtIndex: 0] && memcmp(&raw[i], [string UTF8String], string.length) == 0) {
			if (i > position) [results addObject: [self substringWithRange: NSMakeRange(position, i - position)]];
			position = i + string.length;
			i += string.length - 1;
		}
	}
	
	if (i > position) [results addObject: [self substringWithRange: NSMakeRange(position, i - position)]];
	return results;
}

- (NSArray *) componentsSeparatedByCharactersInSetHeedingQuotes: (NSCharacterSet *) set {
	NSMutableArray			*results = [NSMutableArray array];
	NSInteger				position = 0, i, len = self.length;
	char					*raw = (char *) [self UTF8String];
	BOOL					inQuote = NO, inApos = NO;
	
	for (i = 0; i < len; i++) {
		if (raw[i] == '\'') inApos = !inApos;
		else if (raw[i] == '\"') inQuote = !inQuote;
		else if (!inApos && !inQuote && [set characterIsMember: raw[i]]) {
			if (i > position) [results addObject: [self substringWithRange: NSMakeRange(position, i - position)]];
			position = i + 1;
		}
	}
	
	if (i > position) [results addObject: [self substringWithRange: NSMakeRange(position, i - position)]];
	return results;
}

#if TARGET_OS_IPHONE
- (NSString *) stringTruncatedToWidth: (float) width usingFont: (UIFont *) font addingElipsis: (BOOL) addingElipsis {
	NSMutableString						*copy = self.mutableCopy;
	float								elipsisWidth = addingElipsis ? [@"…" SA_sizeWithFont: font].width : 0;
	BOOL								reduced = NO;
	
	while (true) {
		if ([copy SA_sizeWithFont: font].width <= (width - (reduced ? elipsisWidth : 0))) {
			if (reduced) return [NSString stringWithFormat: @"%@…", [copy stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			return copy;
		}
		
		reduced = YES;
		if (copy.length == 0) return @"";
		[copy deleteCharactersInRange: NSMakeRange(copy.length - 1, 1)];
	}
	return copy;
}

- (CGSize) SA_sizeWithFont: (UIFont *) font {
	if (RUNNING_ON_70) {
		return [self sizeWithAttributes: @{ NSFontAttributeName: font }];
	}
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self sizeWithFont: font];
#pragma clang diagnostic pop
}
- (CGSize) SA_sizeWithFont: (UIFont *)font constrainedToSize: (CGSize) size lineBreakMode: (NSLineBreakMode) lineBreakMode {
	if (RUNNING_ON_70) {
		NSDictionary				*attr = @{ NSFontAttributeName: font };
		
		return [self boundingRectWithSize: size options: NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesLineFragmentOrigin attributes: attr context: nil].size;
	}
	
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	return [self sizeWithFont: font constrainedToSize: size lineBreakMode: lineBreakMode];
#pragma clang diagnostic pop
}
#else
- (CGSize) sizeWithFont:(NSFont *)font {
	NSSize				size = [self sizeWithAttributes: @{NSFontAttributeName: font} ];
	
	return NSSizeToCGSize(size);
}
#endif

- (NSString *) truncateToLength: (int) length {
	if (self.length < length) return self;
	return [NSString stringWithFormat: @"%@…", [self substringToIndex: length]];
}



- (NSString *) stringByStrippingCharactersInSet: (NSCharacterSet *) set options: (int) options {
	NSMutableString				*copy = self.mutableCopy;
	
	while (true) {
		NSRange					range = [copy rangeOfCharacterFromSet: set options: options range: NSMakeRange(0, [copy length])];
		
		if (range.location == NSNotFound) break;
		[copy replaceCharactersInRange: range withString: @""];
	}
	return copy;
}

- (NSString *) stringByConvertingXMLToUTF8 {
	if ([self rangeOfString: @"&"].location == NSNotFound) return self;
	
	unsigned char				*output = (unsigned char *) calloc(1, [self length] + 1), skipToChar = 0;
	NSInteger					length = [self length], count = 0, i;
	const unsigned char			*raw = (unsigned char *) [self UTF8String];
	
	for (i = 0; i < length; i++) {
		unsigned char			c = raw[i];
		
		if (skipToChar) {
			if (c == skipToChar) skipToChar = 0;
			continue;
		}
		if (c == '&') {
			if (memcmp(&raw[i + 1], "gt;", 3) == 0) {
				output[count++] = '>';
				i += 3;
			} else if (memcmp(&raw[i + 1], "lt;", 3) == 0) {
				output[count++] = '<';
				i += 3;
			} else if (memcmp(&raw[i + 1], "amp;", 4) == 0) {
				output[count++] = '&';
				i += 4;
			} else if (memcmp(&raw[i + 1], "quot;", 5) == 0) {
				output[count++] = '\"';
				i += 5;
			} else if (memcmp(&raw[i + 1], "apos;", 5) == 0) {
				output[count++] = '\'';
				i += 5;
			} else if (raw[i + 1] == '#') {		//non ASCII char
				NSInteger			value = atoi((char *) &raw[i + 2]);
				
				skipToChar = ';';
				if (value < 0x7F) {					//1 byte sequence
					output[count++] = (char) value;
				} else if (value < 0x07FF) {		//2 byte sequence
					output[count++] = (unsigned char) (0xE0 | ((value >> 6) & 0x1F));
					output[count++] = (unsigned char) (0x80 | ((value) & 0x3F));
				} else if (value < 0x07FFFF) {		//3 byte sequence
					output[count++] = (unsigned char) (0xE0 | ((value >> 12) & 0x1F));
					output[count++] = (unsigned char) (0x80 | ((value >> 6) & 0x3F));
					output[count++] = (unsigned char) (0x80 | ((value) & 0x3F));
				} else {							//4 byte sequence
					output[count++] = (unsigned char) (0xE0 | ((value >> 18) & 0x1F));
					output[count++] = (unsigned char) (0x80 | ((value >> 12) & 0x3F));
					output[count++] = (unsigned char) (0x80 | ((value >> 6) & 0x3F));
					output[count++] = (unsigned char) (0x80 | ((value) & 0x3F));
				}
			}
		} else
			output[count++] = c;
	}
	
	NSString			*result = [NSString stringWithUTF8String: (char *) output];
	free(output);
	return result;
}

- (NSString *) stringByConvertingUTF8ToXML {
	//	NSCharacterSet			*set = [NSCharacterSet alphanumericCharacterSet];		//illegalCharacterSet
	NSMutableString				*result = [NSMutableString stringWithCapacity: [self length]];
	NSInteger					length = [self length], i;
	const char					*raw = [self UTF8String];
	uint32_t					utfLong, l1, l2, l3, l4;
	
	for (i = 0; i < length; i++) {
		unsigned char			c = raw[i];
		
		if (c == '&') [result appendString: @"&amp;"];
		else if (c == '<') [result appendString: @"&lt;"];
		else if (c == '>') [result appendString: @"&gt;"];
		else if (c == '\"') [result appendString: @"&quot;"];
		else if ((c & 0xF0) == 0xF0) {											//start of a 4 byte sequence
			l1 = c, l2 = (unsigned char) raw[i + 1], l3 = (unsigned char) raw[i + 2], l4 = (unsigned char) raw[i + 3];
			utfLong = ((l1 & 0x0F) << 18) | ((l2 & 0x3F) << 12) | ((l3 & 0x3F) << 6) | ((l4 & 0x3F));
			[result appendFormat: @"&#%d;", utfLong];
			i += 3;
			length += 3;
		} else if ((c & 0xE0) == 0xE0) {										//start of a 3 byte sequence
			l1 = c, l2 = (unsigned char) raw[i + 1], l3 = (unsigned char) raw[i + 2];
			utfLong = ((l1 & 0x1F) << 12) | ((l2 & 0x3F) << 6) | (l3 & 0x3F);
			[result appendFormat: @"&#%d;", utfLong];
			i += 2;
			length += 2;
		} else if ((c & 0xC0) == 0xC0) {
			l1 = c, l2 = (unsigned char) raw[i + 1];
			utfLong = ((l1 & 0x1F) << 6) | (l2 & 0x3F);
			[result appendFormat: @"&#%d;", utfLong];
			i += 1;
			length += 1;
		} else [result appendFormat: @"%c", c];
	}
	
	return result;
}

- (NSString *) stringByPrettyingForURL {
	
	NSString *string = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8));
	return string;
}

- (NSString *) stringByPrettyingForPOSTBody {
	
	NSString *string = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("&="), kCFStringEncodingUTF8));
	return string;
}

- (NSRange) fullRange {return NSMakeRange(0, [self length]);}

- (NSString *) stringByStrippingFirstNWords: (int) n {
	const char					*raw = [self UTF8String];
	NSInteger					count = 0, max = [self length];
	
	while (count < max) {
		while (count < max && raw[count] == ' ') {count++;}
		if (n-- == 0) break;
		while (count < max && raw[count] != ' ') {count++;}
	}
	while (count < max && raw[count] == ' ') {count++;}
	
	return [self substringFromIndex: count];
}

- (BOOL) isEqualToName: (NSString *) name {
	NSString								*myName = [self lowercaseString], *theirName = [name lowercaseString];
	
	if ([myName length] == 0 || [theirName length] == 0) return NO;
	
	if ([theirName isEqualToString: myName]) return YES;
	
	NSCharacterSet				*removables = [[NSCharacterSet characterSetWithCharactersInString: @"abcdefghijklmnopqrstuvwxyz0123456789"] invertedSet];
	
	myName = [myName stringByStrippingCharactersInSet: removables options: 0]; 
	theirName = [theirName stringByStrippingCharactersInSet: removables options: 0]; 
	
	if ([myName length] == 0 || [theirName length] == 0) return NO;
	return ([myName isEqualToString: theirName]);
}

- (BOOL) containsCString: (const char *) string {
	if (self.length == 0) return NO;
	
	return strstr((char *) [self UTF8String], string) != NULL;
}

- (BOOL) startsWithCString: (const char *) string {
	return memcmp((char *) [self UTF8String], string, strlen(string)) == 0;
}


- (BOOL) containsNumber: (int) number {
	static char			buffer[20];
	sprintf(buffer, "%d", number);
	
	return [self containsWord: buffer];
}

- (BOOL) containsWord: (const char *) word {
	const char			*raw = (const char *) [self UTF8String];
	NSInteger			wordLen = strlen(word);
	NSInteger			length = self.length - (wordLen - 1), i;
	
	for (i = 0; i < length; i++) {	
		if (raw[i] == word[0] && (wordLen == 1 || memcmp(&word[1], &raw[i + 1], wordLen - 1) == 0) && (i == (length - 1) || CHAR_IS_NONALPHANUMERIC(raw[i + wordLen])) && (i == 0 || CHAR_IS_NONALPHANUMERIC(raw[i - 1]))) return YES;
	}
	
	return NO;
}

- (NSString *) rot13 {
	NSMutableString			*result = [NSMutableString string];
	NSInteger				i;
	
	for (i = 0; i < self.length; i++) {
		char			c = [self characterAtIndex: i];
		
		if (c >= 'a' && c <= 'z') c = 'a' + ((c - 'a') + 13) % 26;
		if (c >= 'A' && c <= 'Z') c = 'A' +((c - 'A') + 13) % 26;
		
		[result appendFormat: @"%c", c];
	}
	return result;
}

- (NSString *) valueForKey: (NSString *) key {
	NSArray					*pairs = [self componentsSeparatedByString: @"&"];
	NSInteger				i, count = [pairs count];
	
	for (i = 0; i < count; i++) {
		NSArray					*keyValueArray = [[pairs objectAtIndex: i] componentsSeparatedByString: @"="];
		
		if ([keyValueArray count] > 0 && [[keyValueArray objectAtIndex: 0] isEqual: key]) return [keyValueArray count] > 1 ? [keyValueArray objectAtIndex: 1] : @"";
	}
	return nil;
}

- (NSInteger) numberOfOccurrencesOfString: (NSString *) string {
	NSRange					range = self.fullRange;
	NSInteger				count = 0;
	
	while (true) {
		NSRange					pos = [self rangeOfString: string options: 0 range: range];
		
		if (pos.location == NSNotFound) break;
		range.location = pos.location + string.length;
		range.length = self.length - range.location;
		count++;
	}
	
	return count;
}

- (BOOL) boolValue {
	NSString			*down = self.lowercaseString;
	
	return [down isEqual: @"true"] || [down isEqual: @"yes"]  || [down isEqual: @"y"] || [down isEqual: @"1"];
}

- (NSString *) stringByStrippingTags {
	NSRange				r;
	NSString			*result = self.copy;
	
	while ((r = [result rangeOfString: @"<[^>]+>" options: NSRegularExpressionSearch]).location != NSNotFound)
		result = [result stringByReplacingCharactersInRange:r withString: @""];
	return result; 
}

//+ (NSString *) stringWithFormat: (NSString *) format array: (NSArray *) arguments {
//    __strong id *argList = (id *) malloc(sizeof(id) * [arguments count]);
//    [arguments getObjects: argList range: NSMakeRange(0, arguments.count)];
//    NSString* result = [[NSString alloc] initWithFormat: format arguments: (void *) argList];
//    free(argList);
//    return result;
//}

//- (NSString *) md5HashString {
//	if (self.length == 0) return nil;
//
//    const char *value = [self UTF8String];
//    
//    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
//    CC_MD5(value, (CC_LONG) strlen(value), outputBuffer);
//    
//    NSMutableString			*outputString = [[[NSMutableString alloc] initWithCapacity: CC_MD5_DIGEST_LENGTH * 2] ;
//    for(NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; count++){
//        [outputString appendFormat:@"%02x",outputBuffer[count]];
//    }
//    
//    return outputString;
//}

- (BOOL) isValidEmail {
	NSString *emailRegex =  @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
							@"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
							@"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
							@"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
							@"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
							@"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
							@"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
	
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
	
    return [emailTest evaluateWithObject: self];

//	if ([self rangeOfCharacterFromSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) return NO;
//	if (![self containsCString: "@"]) return NO;
//	if (![self containsCString: "."]) return NO;
//	if (self.length < 5) return NO;
//	
//	NSArray				*majors = [self componentsSeparatedByString: @"@"];
//	
//	if (majors.count != 2) return NO;
//	
//	NSArray				*domain = [[majors objectAtIndex: 1] componentsSeparatedByString: @"."];
//	
//	if (domain.count < 2) return NO;
//	
//	NSString			*tld = domain.lastObject;
//	
//	if (tld.length < 2) return NO;
//	return YES;
}

- (NSArray *) characters {
	NSUInteger					count = self.length;
	NSMutableArray				*chars = [NSMutableArray arrayWithCapacity: count];
	
	for (NSUInteger i = 0; i < count; i++) {
		[chars addObject: [self substringWithRange: NSMakeRange(i, 1)]];
	}
	return chars;
}

- (NSString *) stringByStrippingHTMLTags {
    // take this string obj and wrap it in a root element to ensure only a single root element exists
    NSString* string = [NSString stringWithFormat:@"<root>%@</root>", self];
    
    // add the string to the xml parser
    NSStringEncoding			encoding = string.fastestEncoding;
    NSData						*data = [string dataUsingEncoding:encoding];
    NSXMLParser* parser = [[NSXMLParser alloc] initWithData:data];
    
    // parse the content keeping track of any chars found outside tags (this will be the stripped content)
    NSString_HTMLStringDelegate* parsee = [[NSString_HTMLStringDelegate alloc] init];
    parser.delegate = parsee;
    [parser parse];

    NSString* strippedString = [parsee getCharsFound];
    
    // get the raw text out of the parsee after parsing, and return it
    return strippedString;
}

- (NSArray *) URLsContainedWithin {
	NSError				*error = nil;
	NSDataDetector		*linkDetector = [NSDataDetector dataDetectorWithTypes: NSTextCheckingTypeLink error: &error];
	NSArray				*matches = [linkDetector matchesInString: self options: NSMatchingWithoutAnchoringBounds range: NSMakeRange(0, self.length)];

	return [matches valueForKey: @"URL"];
}

- (id) objectAtIndexedSubscript: (NSUInteger) idx {
	if (idx >= self.length) return @"";
	return [self substringWithRange: NSMakeRange(idx, 1)];
}

#if TARGET_OS_IPHONE
- (UIFont *) fontToFitInWidth: (CGFloat) width startingWith: (UIFont *) starting {
	UIFont			*font = starting;
	CGFloat			maxSize = starting.pointSize;
	CGFloat			currentSize = maxSize, halfSize = floorf(maxSize * 0.5);
	
	while (halfSize > 1) {
		CGFloat						textWidth = [self sizeWithAttributes: @{ NSFontAttributeName: font }].width;
		
		
		if (textWidth < width) {
			currentSize += halfSize;
		} else if (textWidth > width) {
			currentSize -= halfSize;
		} else {
			break;
		}
		
		halfSize = roundf(halfSize / 2);
		
		font = [UIFont fontWithName: font.familyName size: currentSize];
	}
	
	if (currentSize > maxSize) return starting;
	return font;
}
#endif



@end
//=============================================================================================================================
#pragma mark
@implementation NSString_HTMLStringDelegate
- (id)init {
    if((self = [super init])) {
        self.strings = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string {
    [self.strings addObject:string];
}
- (NSString*)getCharsFound {
    return [self.strings componentsJoinedByString:@""];
}

@end

