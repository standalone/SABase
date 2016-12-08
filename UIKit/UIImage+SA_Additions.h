//
//  UIImage+SA_Additions.h
//
//  Created by Ben Gottlieb on 12/21/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^gcContextBlock)(CGContextRef ctx);



@interface UIImage (UIImage_SA_Additions)

+ (UIImage *) imageOfSize: (CGSize) size fromBlock: (gcContextBlock) block;
+ (UIImage *) uncachedImageNamed: (NSString *) name;

- (UIImage *) scaledImageOfSize: (CGSize) newSize;
- (UIImage *) scaledImageOfSize: (CGSize) newSize withBorderOfWidth: (CGFloat) borderWidth andColor: (UIColor *) color;
- (NSString *) description;
- (void) drawInRect: (CGRect) rect withContentMode: (UIViewContentMode) mode blendMode: (CGBlendMode) blendMode alpha: (CGFloat) alpha;
- (void) drawInRect: (CGRect) rect withContentMode: (UIViewContentMode) mode;

#if NS_BLOCKS_AVAILABLE

typedef void (^CGContextBlock)(CGContextRef ctx);

#endif

- (UIImage *) maskWithColor: (UIColor *) color;
- (instancetype) tintedImageWithColor: (UIColor *) tintColor;
+ (UIImage *) imageNamed: (NSString *) name inBundle: (NSBundle *) bundle;
@end
