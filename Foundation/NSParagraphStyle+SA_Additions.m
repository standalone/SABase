//
//  NSParagraphStyle+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 5/29/14.
//
//

#import "NSParagraphStyle+SA_Additions.h"

@implementation NSParagraphStyle (SA_Additions)

+ (NSMutableParagraphStyle *) rightAlignedStyle {
	NSMutableParagraphStyle			*style = [NSMutableParagraphStyle new];
	
	style.alignment = NSTextAlignmentRight;
	style.lineBreakMode = NSLineBreakByWordWrapping;

	return style;
}

+ (NSMutableParagraphStyle *) centeredStyle {
	NSMutableParagraphStyle			*style = [NSMutableParagraphStyle new];
	
	style.alignment = NSTextAlignmentCenter;
	style.lineBreakMode = NSLineBreakByWordWrapping;
	
	return style;
}


@end
