//
//  NSDate_Additions.m
//
//  Created by Ben Gottlieb on 3/28/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import "NSDate+Additions.h"
#import "NSString+Additions.h"
#include <time.h>

#define			THREAD_SAFE_STATIC(type, variable)		\
	type			*variable;\
	static type		*static_##variable = nil;\
	if ([NSThread isMainThread]) {\
		if (static_##variable == nil) static_##variable = [[type alloc] init];\
		variable = static_##variable;\
	} else {\
		variable = [[[NSThread currentThread] threadDictionary] objectForKey: @"type##variable"];\
		if (variable) {\
			variable = [[[type alloc] init] autorelease];\
			[[[NSThread currentThread] threadDictionary] setObject: variable forKey: @"type##variable"];\
		}\
	}

#define			THREAD_SAFE_STATIC_WTIH_INITIALIZER(type, variable, initializer, arg)		\
	type			*variable;\
	static type		*static_##variable = nil;\
	if ([NSThread isMainThread]) {\
		if (static_##variable == nil) static_##variable = [[type alloc] initializer: arg];\
		variable = static_##variable;\
	} else {\
		variable = [[[NSThread currentThread] threadDictionary] objectForKey: @"type##variable"];\
		if (variable) {\
			variable = [[[type alloc] initializer: arg] autorelease];\
			[[[NSThread currentThread] threadDictionary] setObject: variable forKey: @"type##variable"];\
		}\
	}

#define			CLEANUP_THREAD_SAFE_STATIC(variable)	if (variable != static_##variable) [variable release];

@implementation NSDate (NSDate_Additions)

- (NSDate *) dateByAddingTimeIntervalAmount: (NSTimeInterval) interval {
	#if (__IPHONE_OS_VERSION_MAX_ALLOWED < 40000 && TARGET_OS_IPHONE) || (!TARGET_OS_IPHONE && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_OS_X_VERSION_10_6)
		return [self addTimeInterval: interval];
	#else
		return [self dateByAddingTimeInterval: interval];
	#endif
}

+ (NSDateFormatter *) formatterForKey: (NSString *) key {
	NSMutableDictionary			*threadDict = [[NSThread currentThread] threadDictionary];
	NSDateFormatter				*threadFormatter = [threadDict objectForKey: key];
	
	if (threadFormatter) return threadFormatter;
	
	threadFormatter = [[NSDateFormatter alloc] init];
	[threadDict setObject: threadFormatter forKey: key];
	[threadFormatter release];
	return threadFormatter;
}

+ (NSDate *) SA_dateWithNaturalLanguageString: (NSString *) date {
	if (date == nil) return nil;
	return [NSDate dateWithNaturalLanguageString: date andFormatHint: nil];
} 

+ (NSDate *) dateWithNaturalLanguageString: (NSString *) date andFormatHint: (NSString *) formatHint {
	if (date.length < 5) return nil;
	NSString				*trimmedDate = [date substringFromIndex: 4];
	NSDateFormatter			*formatter = [NSDate formatterForKey: NSStringFromSelector(_cmd)];
	
	[formatter setDateFormat: formatHint ? formatHint : @"MMM dd HH:mm:ss zzzz yyyy"];
	[formatter setTimeZone: [NSTimeZone timeZoneWithName: @"GMT"]];
	
	NSDate					*result = [formatter dateFromString: trimmedDate];
	
	if (result == nil) {				//check for 2008-10-09, or 10-09-2009 or 10-09-09
		NSArray							*components = [date componentsSeparatedByString: @"-"];
		
		if (components.count != 3) components = [date componentsSeparatedByString: @"/"];
		if (components.count != 3) components = [date componentsSeparatedByString: @"."];
	
		if (components.count == 3) {
			NSInteger			values[3] = {[[components objectAtIndex: 0] intValue], [[components objectAtIndex: 1] intValue], [[components objectAtIndex: 2] intValue]};
			NSInteger			month, day, year;
			
			if (values[0] > 31) {			//year first
				if (values[1] > 12) {			//Y/D/M
					month = values[2]; day = values[1]; year = values[0];
				} else {						//Y/M/D
					month = values[1]; day = values[2]; year = values[0];
				}
			} else if (values[0] > 12) {	//day first, D/M/Y
				month = values[1]; day = values[0]; year = values[2];
			} else {						//month first, M/D/Y
				month = values[0]; day = values[1]; year = values[2];
			}
			
			if (month && day && year < 70) year += 2000;

			NSDateComponents	*components = [[[NSDateComponents alloc] init] autorelease];
			//BOOL				valid = NO;
			
			if (year && month && day) {
				components.year = year;
				components.month = month;
				components.day = day;
				//valid = YES;
				
				NSArray			*words = [date componentsSeparatedByString: @" "];
				
				if (words && words.count > 1) {
					char				*raw = (char *) [[words objectAtIndex: 1] UTF8String];
					NSInteger			hour = atoi(raw), minute = atoi(&raw[3]), second = atoi(&raw[6]);
					
					components.hour = hour;
					components.minute = minute;
					components.second = second;
				}
			}
			
			
			result = [[NSCalendar currentCalendar] dateFromComponents: components];
		}
	}

	return result;
}

+ (NSDate *) dateWithUNIXString: (NSString *) string {			//@"YYYY-mm-ddTHH:mm:ss zzzz"
	NSInteger		intComponents[7];						//month, day, year, hours, minutes, seconds, timezone
	char			*raw = (char *) [string UTF8String];
	
	if (string.length < 20) return nil;
	intComponents[0] = atoi(&raw[0]);
	intComponents[1] = atoi(&raw[5]);
	intComponents[2] = atoi(&raw[8]);
	intComponents[3] = atoi(&raw[11]);
	intComponents[4] = atoi(&raw[14]);
	intComponents[5] = atoi(&raw[17]);
	intComponents[6] = atoi(&raw[20]);
	
	NSDateComponents			*components = [[[NSDateComponents alloc] init] autorelease];
	
	components.year = intComponents[0];
	components.month = intComponents[1];
	components.day = intComponents[2];
	components.hour = intComponents[3];
	components.minute = intComponents[4];
	components.second = intComponents[5];
	
	NSCalendar		*calendar = [NSCalendar currentCalendar];
	NSTimeZone		*original = [calendar timeZone];
	
	[calendar setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
	NSDate			*date = [calendar dateFromComponents: components];
	[calendar setTimeZone: original];
	
	return date;
}

+ (NSDate *) dateWithXMLString: (NSString *) string {
	if (string.length == 0) return nil;
	THREAD_SAFE_STATIC_WTIH_INITIALIZER(NSLocale, enUSPOSIXLocale, initWithLocaleIdentifier, @"en_US_POSIX");
	THREAD_SAFE_STATIC(NSDateFormatter, rfc3339DateFormatter);
	NSDate						*date = nil;
	NSInteger					i;
//	BOOL						isMainThread = [NSThread isMainThread];
//	NSLocale					*enUSPOSIXLocale;
//	NSDateFormatter				*rfc3339DateFormatter;
	NSString					*offsetString = nil;
	char						*raw;
	NSTimeInterval				offsetAmount = 0;
	NSString					*formats[] = {@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'", @"yyyy'-'MM'-'dd'T'HH':'mm':'sszzz", @"yyyy'-'MM'-'dd'T'HH':'mm':'ss' 'zzz",
											  @"yyyy'-'MM'-'dd' 'HH':'mm':'ss'Z'", @"yyyy'-'MM'-'dd' 'HH':'mm':'sszzz", @"yyyy'-'MM'-'dd' 'HH':'mm':'ss' 'zzz",
											  @"yyyy'-'MM'-'dd"};
	
	
//	rfc3339DateFormatter = [[NSDateFormatter alloc] init];
//	enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier: @"en_US_POSIX"];
	
	if ([string containsCString: "Etc/"]) string = [string stringByReplacingOccurrencesOfString: @"Etc/" withString: @""];
	if (string.length >= 19 && ([string characterAtIndex: string.length - 6] == '+' || [string characterAtIndex: string.length - 6] == '-')) {		//ends with +00:00
		offsetString = [string substringFromIndex: string.length - 6];
		raw = (char *) [offsetString UTF8String];
		offsetAmount = (atoi(&raw[1]) * 3600 + atoi(&raw[4]) * 60) * ((raw[0] == '-') ? -1 : 1);
		string = [[string substringToIndex: 19] stringByAppendingString: @"Z"];
	}

	if (string.length >= 19 && ([string characterAtIndex: string.length - 5] == '+' || [string characterAtIndex: string.length - 5] == '-')) {		//ends with +0000
		offsetString = [string substringFromIndex: string.length - 6];
		raw = (char *) [offsetString UTF8String];
		offsetAmount = atoi(&raw[3]) * 60;
		[offsetString truncateToLength: 3];
		raw = (char *) [offsetString UTF8String];
		offsetAmount += atoi(&raw[1]) * 3600;
		offsetAmount *= ((raw[0] == '-') ? -1 : 1);
		string = [string substringToIndex: 19];
		string = [[string substringToIndex: 19] stringByAppendingString: @"Z"];
	}
	
	if (![enUSPOSIXLocale isEqual: [rfc3339DateFormatter locale]]) [rfc3339DateFormatter setLocale: enUSPOSIXLocale];
	[rfc3339DateFormatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];
	
	for (i = 0; i < sizeof(formats) / sizeof(formats[0]); i++) {
		NSString				*format = formats[i];
		
		[rfc3339DateFormatter setDateFormat: format];
		date = [rfc3339DateFormatter dateFromString: string];
		if (date) {
			if (![format containsCString: "HH"]) date = [date dateByAddingTimeIntervalAmount: (-1 * [[NSTimeZone localTimeZone] secondsFromGMTForDate: date]) + 3600 * 12];		//offset by the date and 12hr
			break;
		}
	}

	CLEANUP_THREAD_SAFE_STATIC(enUSPOSIXLocale);
	CLEANUP_THREAD_SAFE_STATIC(rfc3339DateFormatter);
	
	if (offsetAmount) date = [date dateByAddingTimeIntervalAmount: -1 * offsetAmount];
	return date;
}

- (NSInteger) timeZoneOffsetAmount {
	NSString					*raw = [self description];
	NSInteger					offset = [[[raw componentsSeparatedByString: @" "] lastObject] intValue];
	long							hours = (ABS(offset) / 100);
	long							minutes = (ABS(offset) % 100);
	
	return (offset < 0 ? -1 : 1) * (hours * 3600 + minutes * 60);
}

- (NSString *) internetFormattedDateTimeString {
	NSDateComponents		*myComponents = [[NSCalendar currentCalendar] components: NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit fromDate: self];
	NSInteger				secondsOff = [[NSTimeZone localTimeZone] secondsFromGMT];
	
	return [NSString stringWithFormat: @"%d-%02d-%02d %02d:%02d:%02d %c%02d%02d", myComponents.year, myComponents.month, myComponents.day, myComponents.hour, myComponents.minute, myComponents.second, secondsOff < 0 ? '-' : '+', ABS(secondsOff / 3600), ABS(secondsOff % 3600) / 60]; 
}

- (NSString *) internetFormattedTDateTimeString {
	NSDateComponents		*myComponents = [[NSCalendar currentCalendar] components: NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit | NSMonthCalendarUnit fromDate: self];
	NSInteger				secondsOff = [[NSTimeZone localTimeZone] secondsFromGMT];
	
	return [NSString stringWithFormat: @"%d-%02d-%02dT%02d:%02d:%02d%c%02d:%02d", myComponents.year, myComponents.month, myComponents.day, myComponents.hour, myComponents.minute, myComponents.second, secondsOff < 0 ? '-' : '+', ABS(secondsOff / 3600), ABS(secondsOff % 3600) / 60]; 
}

- (BOOL) isAfter: (NSDate *) date {
	return [self earlierDate: date] == date;
}
- (BOOL) isBefore: (NSDate *) date {
	return [self laterDate: date] == date;
}


- (NSString *) veryShortDateString {
	return [NSString stringWithFormat: @"%d/%d", self.month, self.day];
}

- (NSString *) veryShortTimeString {
	NSInteger				hour = self.hour;
	NSString				*pmSymbol = [[NSDate formatterForKey: NSStringFromSelector(_cmd)] PMSymbol];

	if (pmSymbol.length) {
		hour %= 12;
		if (hour == 0) hour = 12;
	}
	
	return [NSString stringWithFormat: @"%d:%02d", hour, self.minute];
}

- (NSString *) shortTimeString {
	NSDateComponents		*myComponents = [[NSCalendar currentCalendar] components: NSHourCalendarUnit | NSMinuteCalendarUnit fromDate: self];
	NSInteger				hour = [myComponents hour], minute = [myComponents minute];
	NSInteger				moddedHour = (hour == 0 || hour == 12) ? 12 : (hour % 12);
	NSDateFormatter			*formatter = [NSDate formatterForKey: NSStringFromSelector(_cmd)];
	NSString				*pmSymbol = [formatter PMSymbol];
	
	if (pmSymbol.length == 0) moddedHour = hour;
	
	if (minute == 0) {
		if (pmSymbol.length == 0) return [NSString stringWithFormat: @"%d", hour];
		
		return [NSString stringWithFormat: @"%d %@", moddedHour, (hour < 12) ? [formatter AMSymbol] : [formatter PMSymbol]];
	}
	
	return [NSString stringWithFormat: @"%d:%02d %@", moddedHour, minute, (hour < 12) ? [formatter AMSymbol] : [formatter PMSymbol]];
}

- (NSString *) dateStringWithFormat: (NSDateFormatterStyle) dateFormat timeFormat: (NSDateFormatterStyle) timeFormat {
	NSDateFormatter		*formatter = [NSDate formatterForKey: NSStringFromSelector(_cmd)];
	NSLocale				*locale = [NSLocale currentLocale];
	
	if (formatter.timeStyle != timeFormat) [formatter setTimeStyle: timeFormat];
	if (formatter.dateStyle != dateFormat) [formatter setDateStyle: dateFormat];
	
	if (formatter.locale != locale) [formatter setLocale: locale];
	
	NSString				*result = [formatter stringFromDate: self];
	return result;
}

- (NSString *) mediumTimeString {return [self dateStringWithFormat: NSDateFormatterNoStyle timeFormat: NSDateFormatterShortStyle];}

- (NSString *) shortDateString {return [self dateStringWithFormat: NSDateFormatterShortStyle timeFormat: NSDateFormatterNoStyle];}
- (NSString *) mediumDateString {return [self dateStringWithFormat: NSDateFormatterMediumStyle timeFormat: NSDateFormatterNoStyle];}
- (NSString *) longDateString {return [self dateStringWithFormat: NSDateFormatterLongStyle timeFormat: NSDateFormatterNoStyle];}

- (NSString *) dayMonthDateString {
	static NSString			*dateFormat = nil;
	NSDateFormatter			*formatter = [NSDate formatterForKey: NSStringFromSelector(_cmd)];
	
	if (dateFormat == nil) dateFormat = [[NSDateFormatter dateFormatFromTemplate: @"EEE d LLL" options: 0 locale: [NSLocale currentLocale]] retain];
	
	[formatter setDateFormat: dateFormat];
	return [formatter stringFromDate: self];
}

- (NSString *) UTCString {
	NSString				*format = @"yyyy'-'MM'-'dd' 'HH':'mm':'ss' GMT'";
	NSDateFormatter			*formatter = [NSDate formatterForKey: NSStringFromSelector(_cmd)];
	NSLocale				*locale = [[NSLocale alloc] initWithLocaleIdentifier: @"en_US_POSIX"];
	
	[formatter setDateFormat: format];
	[formatter setLocale: locale];
	[formatter setTimeZone: [NSTimeZone timeZoneForSecondsFromGMT: 0]];

	NSString				*dateString = [formatter stringFromDate: self];
	
	[locale release];
	return dateString;
	
	//[NSString stringWithFormat: @"%@", [self dateByAddingTimeIntervalAmount: -1 * [[NSTimeZone localTimeZone] secondsFromGMTForDate: self]]];
	
//	return [dateString substringToIndex: dateString.length - 6];
}

- (NSString *) descriptionWithoutOffset {
	NSString				*dateString = [self description];
	
	return [dateString substringToIndex: dateString.length - 6];
}

- (NSString *) dateTimeString {
	return [NSString stringWithFormat: @"%@ %@", [self shortDateString], [self mediumTimeString]];
}

- (NSString *) descriptionWithCalendarFormat: (NSString *) format {
	NSDateFormatter			*formatter = [NSDate formatterForKey: NSStringFromSelector(_cmd)];
	
	[formatter setDateFormat: format];

	NSString				*string = [formatter stringFromDate: self];

	return string;
}

- (int) daysAgo {
	NSDate				*midnight = [self midnight];
	NSDate				*todaysMidnight = [[NSDate date] midnight];
	
	return ([todaysMidnight timeIntervalSinceReferenceDate] - [midnight timeIntervalSinceReferenceDate]) / (60L * 60L * 24L);
}

- (BOOL) isPastDate {
	return [self timeIntervalSinceNow] < 0;
}

- (BOOL) isFutureDate {
	return [self timeIntervalSinceNow] > 0;
}

- (BOOL) isSameDayAs: (NSDate *) date {
	if (date == nil) return NO;
	
	time_t				mySeconds = [self timeIntervalSince1970], dateSeconds = [date timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds), dateInfo = *localtime(&dateSeconds);
	
	return (myInfo.tm_mday == dateInfo.tm_mday && myInfo.tm_mon == dateInfo.tm_mon && myInfo.tm_year == dateInfo.tm_year);
}

- (BOOL) isSameMonthAs: (NSDate *) date {
	if (date == nil) return NO;
	
	time_t				mySeconds = [self timeIntervalSince1970], dateSeconds = [date timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds), dateInfo = *localtime(&dateSeconds);
	
	return (myInfo.tm_mon == dateInfo.tm_mon && myInfo.tm_year == dateInfo.tm_year);
}

- (BOOL) isSameYearAs: (NSDate *) date {
	if (date == nil) return NO;
	
	time_t				mySeconds = [self timeIntervalSince1970], dateSeconds = [date timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds), dateInfo = *localtime(&dateSeconds);
	
	return (myInfo.tm_year == dateInfo.tm_year);
}

- (BOOL) isToday {
	return [self isSameDayAs: [NSDate date]];
}

- (BOOL) isTomorrow {
	return [self isSameDayAs: [NSDate dateWithTimeIntervalSinceNow: 24L * 60L * 60L]];
}

- (BOOL) isYesterday {
	return [self isSameDayAs: [NSDate dateWithTimeIntervalSinceNow: -24L * 60L * 60L]];
}

- (BOOL) isThisMonth {
	time_t				mySeconds = [self timeIntervalSince1970], dateSeconds = [[NSDate date] timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds), dateInfo = *localtime(&dateSeconds);
	
	return (myInfo.tm_mon == dateInfo.tm_mon && myInfo.tm_year == dateInfo.tm_year);
}

- (BOOL) isThisYear {
	time_t				mySeconds = [self timeIntervalSince1970], dateSeconds = [[NSDate date] timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds), dateInfo = *localtime(&dateSeconds);
	
	return (myInfo.tm_year == dateInfo.tm_year);
}

- (NSDate *) midnight {
	time_t				mySeconds = [self timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds);
	NSDate				*newDate = [NSDate dateWithTimeIntervalSinceReferenceDate: floor([self timeIntervalSinceReferenceDate]) -1 * (myInfo.tm_hour * 3600 + myInfo.tm_min * 60 + myInfo.tm_sec)];
	NSTimeZone			*localZone = [NSTimeZone localTimeZone];
	NSInteger			myOffset = [localZone secondsFromGMTForDate: self], newOffset = [localZone secondsFromGMTForDate: newDate];
	
	
	if (myOffset == newOffset) return newDate;
	
	newDate = [newDate dateByAddingTimeIntervalAmount: (myOffset - newOffset)];
	return newDate;
	
}

- (NSDate *) noon {
	time_t				mySeconds = [self timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds);
	NSDate				*newDate = [self dateByAddingTimeIntervalAmount: -1 * (myInfo.tm_hour * 3600 + myInfo.tm_min * 60 + myInfo.tm_sec) + 12 * 3600];
	NSTimeZone			*localZone = [NSTimeZone localTimeZone];
	NSInteger			myOffset = [localZone secondsFromGMTForDate: self], newOffset = [localZone secondsFromGMTForDate: newDate];
	
	
	if (myOffset == newOffset) return newDate;
	
	newDate = [newDate dateByAddingTimeIntervalAmount: (myOffset - newOffset)];
	return newDate;
}

- (NSDate *) lastSecond {
	time_t				mySeconds = [self timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds);
	NSDate				*newDate = [NSDate dateWithTimeIntervalSinceReferenceDate: ceil([self timeIntervalSinceReferenceDate]) + ((23 - myInfo.tm_hour) * 3600 + (59 - myInfo.tm_min) * 60 + (58 - myInfo.tm_sec))];
	NSTimeZone			*localZone = [NSTimeZone localTimeZone];
	NSInteger			myOffset = [localZone secondsFromGMTForDate: self], newOffset = [localZone secondsFromGMTForDate: newDate];
	
	
	if (myOffset == newOffset) return newDate;
	
	newDate = [newDate dateByAddingTimeIntervalAmount: (myOffset - newOffset)];
	return newDate;
	
//	return [NSDate dateWithTimeIntervalSinceReferenceDate: ceil([self timeIntervalSinceReferenceDate]) + ((23 - myInfo.tm_hour) * 3600 + (59 - myInfo.tm_min) * 60 + (58 - myInfo.tm_sec))];
//	return [self dateByAddingTimeIntervalAmount: -1 * (myInfo.tm_hour * 3600 + myInfo.tm_min * 60 + myInfo.tm_sec) + 24 * 3600 - 1];
}

- (NSDate *) firstDayOfMonth {
	time_t				mySeconds = [self timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds);
	
	myInfo.tm_mday = 1;
	mySeconds = mktime(&myInfo);
	
	return [NSDate dateWithTimeIntervalSince1970: mySeconds];
}

- (NSDate *) lastDayOfMonth {
	time_t				mySeconds = [self timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds);
	
	if (myInfo.tm_mon == 1) {			//special case feb
		myInfo.tm_mday = (myInfo.tm_year % 4 == 0 && (myInfo.tm_year % 100 || myInfo.tm_year % 400 == 0)) ? 29 : 28;
	} else {
		NSInteger		days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
		
		myInfo.tm_mday = (int) days[myInfo.tm_mon];		
	}
	mySeconds = mktime(&myInfo);
	return [NSDate dateWithTimeIntervalSince1970: mySeconds];
}

- (int) numberOfDaysInMonth {
	time_t				mySeconds = [self timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds);
	
	if (myInfo.tm_mon == 1) {			//special case feb
		return (myInfo.tm_year % 4 == 0 && (myInfo.tm_year % 100 || myInfo.tm_year % 400 == 0)) ? 29 : 28;
	}
	NSInteger		days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
	
	return (int) days[myInfo.tm_mon];		
}

- (NSDate *) previousDay {
	return [self dateByAddingTimeIntervalAmount: -1 * 60 * 60 * 24];
}

- (NSDate *) nextDay {
	return [self dateByAddingTimeIntervalAmount: 60 * 60 * 24];
}


//=============================================================================================================================
#pragma mark RelativeStrings
- (NSString *) shortRelativeString {
	NSInteger				delta = ABS([self timeIntervalSinceNow]);
	
	if (delta < 60) return NSLocalizedString(@"less than a minute ago", @"less than a minute ago");
	if (delta < 300) return NSLocalizedString(@"a few minutes ago", @"a few minutes ago");
	if (delta < 3600) return NSLocalizedString(@"within the last hour", @"within the last hour");
	if (delta < 3600 * 3) return NSLocalizedString(@"within the last few hours", @"within the last few hours");
	if (delta < 3600 * 24) return NSLocalizedString(@"within the last day", @"within the last day");
	if (delta < 3600 * 24 * 3) return NSLocalizedString(@"within the last few days", @"within the last few days");
	if (delta < 3600 * 24 * 7) return NSLocalizedString(@"within the last week", @"within the last week");
	if (delta < 3600 * 24 * 14) return NSLocalizedString(@"within the last few weeks", @"within the last few weeks");
	if (delta < 3600 * 24 * 30) return NSLocalizedString(@"within the last month", @"Within the last month");
	return NSLocalizedString(@"at some point", @"At some point");
}

- (NSString *) mediumRelativeString {
	NSInteger				delta = ABS([self timeIntervalSinceNow]);
	
	if (delta <= 3600) return [self shortRelativeString];
	if (delta < 3600 * 18) return [NSString stringWithFormat: NSLocalizedString(@"at %@", @"at time format string"), [self shortTimeString]];
	return [NSString stringWithFormat: NSLocalizedString(@"at %@, %@", @"at date and time format string"), [self shortDateString], [self shortTimeString]];
}

- (NSString *) exactRelativeStringWithDepth: (extactRelativeTimeDepth) depth  {
	extactRelativeTimeDepth	initialDepth = depth;
	NSInteger				delta = ABS([self timeIntervalSinceNow]);
	NSInteger				seconds = delta % 60;
	NSInteger				minutes = (delta / 60) % 60;
	NSInteger				hours = (delta / 3600) % 24;
	NSInteger				days = (delta / (24 * 3600));
	NSString				*base = @"";
	BOOL					contentFound = NO;
	
	if (days) {
		base = [base stringByAppendingFormat: @"%d %@ ", days, days == 1 ? NSLocalizedString(@"day", @"day") : NSLocalizedString(@"days", @"days")];
		contentFound = YES;
	}
	if (contentFound && depth) depth--;

	if (hours && depth > 0) {
		base = [base stringByAppendingFormat: @"%d %@ ", hours, hours == 1 ? NSLocalizedString(@"hr", @"hr") : NSLocalizedString(@"hrs", @"hrs")];
		contentFound = YES;
	}
	if (contentFound && depth) depth--;

	if (minutes && depth > 0) {
		base = [base stringByAppendingFormat: @"%d %@ ", minutes, minutes == 1 ? NSLocalizedString(@"min", @"min") : NSLocalizedString(@"mins", @"mins")];
		contentFound = YES;
	}
	if (contentFound && depth) depth--;
	if (seconds && depth > 0 && initialDepth >= extactRelativeTimeDepth_maximum) {
		base = [base stringByAppendingFormat: @"%d %@ ", seconds, seconds == 1 ? NSLocalizedString(@"sec", @"sec") : NSLocalizedString(@"secs", @"secs")];
	}
	
	return [base stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *) roughRelativeString  {
	NSInteger				delta = ABS([self timeIntervalSinceNow]);
	NSInteger				minutes = (delta / 60) % 60;
	NSInteger				hours = (delta / 3600) % 24;
	NSInteger				days = (delta / (24 * 3600));
	NSString				*base = @"";
	
	if (days) return [base stringByAppendingFormat: @"%d %@ ", days + 1, days == 0 ? NSLocalizedString(@"day", @"day") : NSLocalizedString(@"days", @"days")];
	if (hours) base = [base stringByAppendingFormat: @"%d %@ ", hours, hours == 1 ? NSLocalizedString(@"hr", @"hr") : NSLocalizedString(@"hrs", @"hrs")];
	if (minutes && hours < 3) base = [base stringByAppendingFormat: @"%d %@ ", minutes, minutes == 1 ? NSLocalizedString(@"min", @"min") : NSLocalizedString(@"mins", @"mins")];
	if (minutes == 0 && hours == 0 && days == 0) base = NSLocalizedString(@"< 1 min", @"less than 1 min");
	
	return [base stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
}

- (NSString *) futureRelativeDateString  {
	if ([self isToday]) return NSLocalizedString(@"Today", @"Today");
	if ([self isTomorrow]) return NSLocalizedString(@"Tomorrow", @"Tomorrow");
	
	NSInteger				delta = ABS([self timeIntervalSinceNow]);
	NSInteger				days = round(delta / (24.0 * 3600.0));
	NSInteger				weeks = days / 7;
	NSInteger				months = days / 30;
	
	if (months > 1) return [NSString stringWithFormat: @"%d %@", months, NSLocalizedString(@"months", @"months")];
	if (weeks > 1) return [NSString stringWithFormat: @"%d %@", weeks, NSLocalizedString(@"weeks", @"weeks")];
	return [NSString stringWithFormat: @"%d %@ ", days + 1, days == 0 ? NSLocalizedString(@"day", @"day") : NSLocalizedString(@"days", @"days")];
}

//=============================================================================================================================
#pragma mark Properties
- (int) year {time_t mySeconds = [self timeIntervalSince1970]; return localtime(&mySeconds)->tm_year + 1900;};
- (int) month {time_t mySeconds = [self timeIntervalSince1970]; return localtime(&mySeconds)->tm_mon + 1;}
- (int) day {time_t mySeconds = [self timeIntervalSince1970]; return localtime(&mySeconds)->tm_mday;}
- (int) hour {time_t mySeconds = [self timeIntervalSince1970]; return localtime(&mySeconds)->tm_hour;}
- (int) minute {time_t mySeconds = [self timeIntervalSince1970]; return localtime(&mySeconds)->tm_min;}
- (int) second {time_t mySeconds = [self timeIntervalSince1970]; return localtime(&mySeconds)->tm_sec;}
- (int) weekday {time_t mySeconds = [self timeIntervalSince1970]; return localtime(&mySeconds)->tm_wday + 1;}

- (NSString *) weekdayAsShortString {int weekday = self.weekday; if (weekday < 1 || weekday > 7) return @""; return [[[NSDate formatterForKey: NSStringFromSelector(_cmd)] veryShortWeekdaySymbols] objectAtIndex: weekday - 1];}
- (NSString *) weekdayAsMediumString {int weekday = self.weekday; if (weekday < 1 || weekday > 7) return @""; return [[[NSDate formatterForKey: NSStringFromSelector(_cmd)] shortWeekdaySymbols] objectAtIndex: weekday - 1];}
- (NSString *) weekdayAsLongString {int weekday = self.weekday; if (weekday < 1 || weekday > 7) return @""; return [[[NSDate formatterForKey: NSStringFromSelector(_cmd)] weekdaySymbols] objectAtIndex: weekday - 1];}
- (NSString *) monthName {int month = self.month; return [[[NSDate formatterForKey: NSStringFromSelector(_cmd)] monthSymbols] objectAtIndex: month - 1];}
- (NSString *) shortMonthName {int month = self.month; return [[[NSDate formatterForKey: NSStringFromSelector(_cmd)] shortMonthSymbols] objectAtIndex: month - 1];}

- (int) nextNearestHour {
	time_t				mySeconds = [self timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds);
	
	return (myInfo.tm_hour + 1) % 24;
}

- (int) nearestHour {
	time_t				mySeconds = [self timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds);

	if (myInfo.tm_min > 30) return (myInfo.tm_hour + 1) % 24;
	return myInfo.tm_hour;
}

- (NSDate *) dateWithHour: (int) hour {
	return [self dateWithHour: hour minute: 0 second: 0];
}

+ (NSDate *) dateWithNextNearestHour {
	NSDate				*date = [NSDate date];
	return [date dateWithHour: [date nextNearestHour] minute: 0 second: 0];
}

+ (NSDate *) dateWithNearestHour {
	NSDate				*date = [NSDate date];
	return [date dateWithHour: [date nearestHour] minute: 0 second: 0];
}

- (NSDate *) dateWithHour: (int) hour minute: (int) minute second: (int) second {
	NSCalendar							*calendar = [NSCalendar currentCalendar];
	NSDateComponents					*myComponents = [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate: self];
	
	[myComponents setHour: hour];
	[myComponents setMinute: minute];
	[myComponents setSecond: second];
	
	return [calendar dateFromComponents: myComponents];
}

- (NSDate *) furtureDateByAddingDays: (int) days months: (int) months years: (int) years {
	NSCalendar							*calendar = [NSCalendar currentCalendar];
	NSDateComponents					*myComponents = [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit fromDate: self];
	
	if (years) myComponents.year = myComponents.year + days;
	if (months) myComponents.month = myComponents.month + months;
	if (days) myComponents.day = myComponents.day + days;

	return [calendar dateFromComponents: myComponents];
}

- (NSString *) monthDayYearDateString: (BOOL) addLeadingZeroes {
	NSDateComponents	*components = [[NSCalendar currentCalendar] components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate: self];
	
	return [NSString stringWithFormat: addLeadingZeroes ? @"%02d/%02d/%d" : @"%d/%d/%d", [components month], [components day], [components year]];
}

- (NSString *) yearMonthDayDateString: (BOOL) addLeadingZeroes {
	NSDateComponents	*components = [[NSCalendar currentCalendar] components: NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate: self];
	
	return [NSString stringWithFormat: addLeadingZeroes ? @"%d/%02d/%02d" : @"%d/%d/%d", [components year], [components month], [components day]];
}

- (NSComparisonResult) compareTimes: (NSDate *) date {
	time_t				mySeconds = [self timeIntervalSince1970], dateSeconds = [[NSDate date] timeIntervalSince1970];
	struct tm			myInfo = *localtime(&mySeconds), dateInfo = *localtime(&dateSeconds);
		
	if (myInfo.tm_hour > dateInfo.tm_hour) return NSOrderedDescending;
	if (myInfo.tm_hour < dateInfo.tm_hour) return NSOrderedAscending;

	if (myInfo.tm_min > dateInfo.tm_min) return NSOrderedDescending;
	if (myInfo.tm_min < dateInfo.tm_min) return NSOrderedAscending;

	if (myInfo.tm_sec > dateInfo.tm_sec) return NSOrderedDescending;
	if (myInfo.tm_sec < dateInfo.tm_sec) return NSOrderedAscending;
	
	return NSOrderedSame;
}

- (NSInteger) monthsSinceDate: (NSDate *) date {
	NSInteger	count = (self.year - date.year) * 12;
	
	count += (self.month - date.month);
	return count;
}

- (NSTimeInterval) absoluteTimeIntervalFromNow {
	return ABS([self timeIntervalSinceNow]);
}

@end
