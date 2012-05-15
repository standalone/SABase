//
//  UIImage+Additions.h
//
//  Created by Ben Gottlieb on 12/21/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIImage (UIImage_Additions)

+ (UIImage *) uncachedImageNamed: (NSString *) name;

- (UIImage *) scaledImageOfSize: (CGSize) newSize;
- (NSString *) description;
- (void) drawInRect: (CGRect) rect withContentMode: (UIViewContentMode) mode blendMode: (CGBlendMode) blendMode alpha: (CGFloat) alpha;
- (void) drawInRect: (CGRect) rect withContentMode: (UIViewContentMode) mode;

#if NS_BLOCKS_AVAILABLE

typedef void (^CGContextBlock)(CGContextRef ctx);

+ (UIImage *) imageOfSize: (CGSize) size scale: (CGFloat) scale withBlock: (CGContextBlock) block;
#endif

- (UIImage *) maskWithColor: (UIColor *) color;
@end
