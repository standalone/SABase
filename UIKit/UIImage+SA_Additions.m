//
//  UIImage+Additions.m
//
//  Created by Ben Gottlieb on 12/21/08.
//  Copyright 2008 Stand Alone, Inc.. All rights reserved.
//

#import "UIImage+SA_Additions.h"


@implementation UIImage (UIImage_SA_Additions)

+ (UIImage *) uncachedImageNamed: (NSString *) name {
	NSString		*path = [[NSBundle mainBundle] pathForResource: name ofType: nil];
	
	if (path == nil) return nil;
	
	NSData			*data = [[NSData alloc] initWithContentsOfFile: path];
	UIImage			*image = [[[UIImage alloc] initWithData: data] autorelease];
	[data release];
	return image;
}

- (UIImage *) scaledImageOfSize: (CGSize) newSize {
	return [self scaledImageOfSize: newSize withBorderOfWidth: 0 andColor: nil];
}

- (UIImage *) scaledImageOfSize: (CGSize) newSize withBorderOfWidth: (CGFloat) borderWidth andColor: (UIColor *) borderColor {
	UIGraphicsBeginImageContext(newSize);
	CGContextRef					context = UIGraphicsGetCurrentContext();
	CGRect							rect = CGRectMake(0, 0, newSize.width, newSize.height);
	
	CGContextConcatCTM(context, CGAffineTransformMakeScale(1.0, -1.0));
	CGContextConcatCTM(context, CGAffineTransformMakeTranslation(0, -newSize.height));
	CGContextDrawImage(context, rect, self.CGImage);
	
	if (borderWidth) {
		CGRect		rect = CGRectMake(borderWidth / 2, borderWidth / 2, newSize.width - borderWidth, newSize.height - borderWidth);
		
		CGContextSetLineWidth(context, borderWidth);
		[borderColor setStroke];
		UIRectFrame(rect);
	}
	
	UIImage							*newImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	return newImage;
}

- (NSString *) description {
	return [NSString stringWithFormat: @"<%@: 0x%x, (%.0f, %.0f)>", [self class], (int) self, self.size.width, self.size.height];
}

- (void) drawInRect: (CGRect) rect withContentMode: (UIViewContentMode) mode {
	[self drawInRect: rect withContentMode: mode  blendMode: kCGBlendModeNormal alpha: 1.0];
}

- (void) drawInRect: (CGRect) rect withContentMode: (UIViewContentMode) mode blendMode: (CGBlendMode) blendMode alpha: (CGFloat) alpha {
//	CGSize					newSize = self.size;
	CGRect					imageRect = rect;
//	CGFloat					delta = 0.0;
	CGContextRef			ctx = UIGraphicsGetCurrentContext();
	
	CGContextSaveGState(ctx);
	CGContextClipToRect(ctx, rect);
	imageRect = CGRectPlacedInRectWithContentMode(CGRectFromSize(self.size), rect, mode);
	
//	switch (mode) {
//		case UIViewContentModeScaleToFill: newSize = rect.size; break;			//just draw the image in the rect. done.
//		case UIViewContentModeScaleAspectFill:     // contents scaled to fill with fixed aspect. some portion of content may be clipped.
//			newSize = CGSizeScaledWithinLimitSize(self.size, rect.size);
//			if (newSize.height < imageRect.size.height) {			//image is too short to fit. 
//				delta = newSize.width * (imageRect.size.height / newSize.height) - newSize.width;
//				newSize.width = imageRect.size.width + delta;
//				newSize.height = imageRect.size.height;
//				imageRect.origin.x -= delta / 2;
//			} else if (newSize.width < imageRect.size.width) {
//				delta = newSize.height * (imageRect.size.width / newSize.width) - newSize.height;
//				newSize.height = imageRect.size.height + delta;
//				newSize.width = imageRect.size.width;
//				imageRect.origin.y -= delta / 2;
//			}
//			break;
//			
//		case UIViewContentModeScaleAspectFit:     // contents scaled to fit with fixed aspect. remainder is transparent.
//			newSize = CGSizeScaledWithinLimitSize(self.size, rect.size);
//			if (newSize.height < imageRect.size.height) {			//image is too short to fit. 
//				delta = imageRect.size.height - newSize.height;
//				imageRect.origin.y += delta / 2;
//			} else if (newSize.width < imageRect.size.width) {
//				delta = imageRect.size.width - newSize.width;
//				imageRect.origin.x += delta / 2;
//			}
//			break;
//			
//		case UIViewContentModeRedraw: SA_Assert(NO, @"Can't draw an image with mode UIViewContentModeRedraw"); break;              // redraw on bounds change (calls -setNeedsDisplay)
//		case UIViewContentModeCenter:
//			imageRect.origin.x += (imageRect.size.width - newSize.width) / 2;
//			imageRect.origin.y += (imageRect.size.height - newSize.height) / 2;
//			break;
//			
//		case UIViewContentModeTop: 
//			imageRect.origin.x += (imageRect.size.width - newSize.width) / 2;
//			break;
//			
//		case UIViewContentModeBottom:
//			imageRect.origin.x += (imageRect.size.width - newSize.width) / 2;
//			imageRect.origin.y += (imageRect.size.height - newSize.height);
//			break;
//			
//		case UIViewContentModeLeft:
//			imageRect.origin.y += (imageRect.size.height - newSize.height) / 2;
//			break;
//			
//		case UIViewContentModeRight:
//			imageRect.origin.x += (imageRect.size.width - newSize.width);
//			imageRect.origin.y += (imageRect.size.height - newSize.height) / 2;
//			break;
//			
//		case UIViewContentModeTopLeft:
//			break;
//			
//		case UIViewContentModeTopRight:
//			imageRect.origin.x += (imageRect.size.width - newSize.width);
//			break;
//			
//		case UIViewContentModeBottomLeft:
//			imageRect.origin.y += (imageRect.size.height - newSize.height);
//			break;
//			
//		case UIViewContentModeBottomRight:
//			imageRect.origin.x += (imageRect.size.width - newSize.width);
//			imageRect.origin.y += (imageRect.size.height - newSize.height);
//			break;
//			
//	}
//	
//	imageRect.size = newSize;
	[self drawInRect: imageRect blendMode: blendMode alpha: alpha];
	
	CGContextRestoreGState(ctx);
}

#if NS_BLOCKS_AVAILABLE
+ (UIImage *) imageOfSize: (CGSize) size scale: (CGFloat) scale withBlock: (CGContextBlock) block {
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    
    if (block) block(UIGraphicsGetCurrentContext());
    
    UIImage						*createdImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
	
    return createdImage;
}
#endif

- (UIImage *) maskWithColor: (UIColor *) color {
	UIGraphicsBeginImageContext(self.size);
	
	CGContextRef				ctx = UIGraphicsGetCurrentContext();
	
	[self drawAtPoint: CGPointZero];
	CGContextSetBlendMode(ctx,  kCGBlendModeSourceAtop);
	CGContextBeginPath(ctx);
	CGContextAddRect(ctx, CGRectMake(0, 0, self.size.width, self.size.height));
	CGContextClosePath(ctx);
	CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite: 0.75 alpha: 1.0].CGColor);
	CGContextFillPath(ctx);
	
	UIImage				*image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return image;
}

- (instancetype) tintedImageWithColor: (UIColor *) tintColor {
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    CGRect		rect = CGRectFromSize(self.size);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    [self drawInRect: rect];
	
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    [tintColor setFill];
    CGContextFillRect(context, rect);
	
    UIImage *image  = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


@end
