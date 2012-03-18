//
//  UIBarButtonItem+Additions.m
//
//  Created by Ben Gottlieb on 3/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "UIBarButtonItem+Additions.h"
#import "NSObject+Additions.h"

@interface SA_BarButtonItem : UIBarButtonItem
@property (nonatomic, copy) idArgumentBlock block;
@end

@implementation UIBarButtonItem (Additions)
+ (id) borderlessItemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action {
	UIBarButtonItem				*barItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: item target: target action: action] autorelease];
	barItem.style = UIBarButtonItemStylePlain;
	return barItem;
}

+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action {
	UIBarButtonItem				*barItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem: item target: target action: action] autorelease];
	barItem.style = UIBarButtonItemStyleBordered;
	return barItem;
}

+ (id) borderlessItemWithTitle: (NSString *) title target: (id) target action: (SEL) action {
	return [[[UIBarButtonItem alloc] initWithTitle: title style: UIBarButtonItemStylePlain target: target action: action] autorelease];
}

+ (id) itemWithTitle: (NSString *) title target: (id) target action: (SEL) action {
	return [[[UIBarButtonItem alloc] initWithTitle: title style: UIBarButtonItemStyleBordered target: target action: action] autorelease];
}

+ (id) borderlessItemWithImage: (UIImage *) image target: (id) target action: (SEL) action {
	return [[[UIBarButtonItem alloc] initWithImage: image style: UIBarButtonItemStylePlain target: target action: action] autorelease];	
}

+ (id) itemWithImage: (UIImage *) image target: (id) target action: (SEL) action {
	return [[[UIBarButtonItem alloc] initWithImage: image style: UIBarButtonItemStyleBordered target: target action: action] autorelease];	
}

+ (id) flexibleSpacer {
	return [self itemWithSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil];
}

+ (id) spacer {
	return [self itemWithSystemItem: UIBarButtonSystemItemFixedSpace target: nil action: nil];
}

+ (id) spacerOfWidth: (float) width {
	UIBarButtonItem			*spacer = [self itemWithSystemItem: UIBarButtonSystemItemFixedSpace target: nil action: nil];
	spacer.width = width;
	return spacer;
}

+ (id) itemWithView: (UIView *) view {
	return [[[UIBarButtonItem alloc] initWithCustomView: view] autorelease];
}


+ (id) activityIndicatorItemWithStyle: (UIActivityIndicatorViewStyle) style forToolbar: (BOOL) forToolbar {
	UIActivityIndicatorView					*indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: style] autorelease];
	UIView									*holder = [[[UIView alloc] initWithFrame: CGRectMake(0, 0, 30, 30)] autorelease];
	
	holder.backgroundColor = [UIColor clearColor];
	indicator.center = forToolbar ? CGPointMake(holder.bounds.size.width / 2 - 5, holder.bounds.size.height / 2 + 1) : CGPointMake(holder.bounds.size.width / 2 + 4, holder.bounds.size.height / 2);
	[holder addSubview: indicator]; 
	[indicator startAnimating];
	return [UIBarButtonItem itemWithView: holder];	
}

+ (id) itemWithTitle: (NSString *) title block: (idArgumentBlock) block {
	SA_BarButtonItem				*barItem = [[[SA_BarButtonItem alloc] initWithTitle: title style: UIBarButtonItemStyleBordered target: nil action: @selector(__evaluateBlockAsAction)] autorelease];
	barItem.target = barItem;
	barItem.block = block;
	return barItem;
}

+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item block: (idArgumentBlock) block {
	SA_BarButtonItem				*barItem = [[[SA_BarButtonItem alloc] initWithBarButtonSystemItem: item target: nil action: @selector(__evaluateBlockAsAction)] autorelease];
	barItem.style = UIBarButtonItemStyleBordered;
	barItem.target = barItem;
	barItem.block = block;
	return barItem;
}

+ (id) itemWithImage: (UIImage *) image block: (idArgumentBlock) block {
	SA_BarButtonItem				*barItem = [[[SA_BarButtonItem alloc] initWithImage: image style: UIBarButtonItemStyleBordered target: nil action: @selector(__evaluateBlockAsAction)] autorelease];
	barItem.target = barItem;
	barItem.block = block;
	return barItem;
}


@end

@implementation SA_BarButtonItem
@synthesize block;
- (void) dealloc {
	self.block = nil;
	[super dealloc];
}

- (void) __evaluateBlockAsAction {
	self.block(self);
}
@end
