//
//  NSAttributedString+SA_Additions.m
//  SABase
//
//  Created by Ben Gottlieb on 3/14/14.
//
//

#import "NSAttributedString+SA_Additions.h"
#import "NSString+SA_Additions.h"

@implementation NSAttributedString (SA_Additions)

+ (id) stringWithString: (NSString *) string { return [self stringWithString: string attributes: @{  }]; }
+ (id) stringWithString: (NSString *) string attributes: (NSDictionary *) attr {
	return [[self alloc] initWithString: string ?: @"" attributes: attr ?: @{}];
}

- (id) stringByAppendingAttributedString: (NSAttributedString *) string {
	if (string.length == 0) return self;
	
	NSMutableAttributedString				*base = [[NSMutableAttributedString alloc] init];
	
	[base appendAttributedString: self];
	[base appendAttributedString: string];
	return base;
}

- (NSRange) fullRange { return NSMakeRange(0, self.length); }
@end


@implementation NSMutableAttributedString (SA_Additions)

- (void) appendString: (NSString *) string {
	[self appendAttributedString: [NSAttributedString stringWithString: string ?: @""]];
}

- (void) appendString: (NSString *) string attributes: (NSDictionary *) attr {
	[self appendAttributedString: [NSAttributedString stringWithString: string ?: @"" attributes: attr ?: @{}]];
}

- (void) setFont: (UIFont *) font {
	[self setAttributes: @{ NSFontAttributeName: font } range: self.fullRange];
}
- (void) setColor: (UIColor *) color {
	[self setAttributes: @{ NSForegroundColorAttributeName: color } range: self.fullRange];
}

@end