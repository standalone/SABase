//
//  UIBarButtonItem+Additions.m
//
//  Created by Ben Gottlieb on 3/18/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "UIBarButtonItem+SA_Additions.h"
#import "NSObject+SA_Additions.h"

@interface SA_BarButtonItem : UIBarButtonItem
@property (nonatomic, copy) barButtonItemArgumentBlock block;
@end

@implementation UIBarButtonItem (SA_SA_Additions)

//standard items
+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action { return [UIBarButtonItem itemWithSystemItem: item target: target action: action block: nil style: UIBarButtonItemStyleBordered]; }
+ (id) itemWithTitle: (NSString *) title target: (id) target action: (SEL) action { return [UIBarButtonItem itemWithTitle: title target: target action: action block: nil style: UIBarButtonItemStyleBordered]; }
+ (id) itemWithImage: (UIImage *) image target: (id) target action: (SEL) action { return [UIBarButtonItem itemWithImage: image target: target action: action block: nil style: UIBarButtonItemStyleBordered]; }

+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item block: (barButtonItemArgumentBlock) block { return [UIBarButtonItem itemWithSystemItem: item target: nil action: nil block: block style: UIBarButtonItemStyleBordered]; }
+ (id) itemWithTitle: (NSString *) title block: (barButtonItemArgumentBlock) block { return [UIBarButtonItem itemWithTitle: title target: nil action: nil block: block style: UIBarButtonItemStyleBordered]; }
+ (id) itemWithImage: (UIImage *) image block: (barButtonItemArgumentBlock) block { return [UIBarButtonItem itemWithImage: image target: nil action: nil block: block style: UIBarButtonItemStyleBordered]; }

//borderless items
+ (id) borderlessItemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action { return [UIBarButtonItem itemWithSystemItem: item target: target action: action block: nil style: UIBarButtonItemStylePlain]; }
+ (id) borderlessItemWithTitle: (NSString *) title target: (id) target action: (SEL) action { return [UIBarButtonItem itemWithTitle: title target: target action: action block: nil style: UIBarButtonItemStylePlain]; }
+ (id) borderlessItemWithImage: (UIImage *) image target: (id) target action: (SEL) action { return [UIBarButtonItem itemWithImage: image target: target action: action block: nil style: UIBarButtonItemStylePlain]; }


//done items
+ (id) doneItemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action { return [UIBarButtonItem itemWithSystemItem: item target: target action: action block: nil style: UIBarButtonItemStyleDone]; }
+ (id) doneItemWithTitle: (NSString *) title target: (id) target action: (SEL) action { return [UIBarButtonItem itemWithTitle: title target: target action: action block: nil style: UIBarButtonItemStyleDone]; }
+ (id) doneItemWithImage: (UIImage *) image target: (id) target action: (SEL) action { return [UIBarButtonItem itemWithImage: image target: target action: action block: nil style: UIBarButtonItemStyleDone]; }

+ (id) doneItemWithSystemItem: (UIBarButtonSystemItem) item block: (barButtonItemArgumentBlock) block { return [UIBarButtonItem itemWithSystemItem: item target: nil action: nil block: block style: UIBarButtonItemStyleDone]; }
+ (id) doneItemWithTitle: (NSString *) title block: (barButtonItemArgumentBlock) block { return [UIBarButtonItem itemWithTitle: title target: nil action: nil block: block style: UIBarButtonItemStyleDone]; }
+ (id) doneItemWithImage: (UIImage *) image block: (barButtonItemArgumentBlock) block { return [UIBarButtonItem itemWithImage: image target: nil action: nil block: block style: UIBarButtonItemStyleDone]; }



//actual creators
+ (id) itemWithTitle: (NSString *) title target: (id) target action: (SEL) action block: (barButtonItemArgumentBlock) block style: (UIBarButtonItemStyle) style {
	Class						factory = block ? [SA_BarButtonItem class] : [UIBarButtonItem class];
	SA_BarButtonItem			*barItem = [[[factory alloc] initWithTitle: title style: style target: target action: action] autorelease];

	if (block) {
		barItem.target = barItem;
		barItem.block = block;
		barItem.action = @selector(__evaluateBlockAsAction);
	}
	return barItem;
}

+ (id) itemWithSystemItem: (UIBarButtonSystemItem) item target: (id) target action: (SEL) action block: (barButtonItemArgumentBlock) block style: (UIBarButtonItemStyle) style {
	Class						factory = block ? [SA_BarButtonItem class] : [UIBarButtonItem class];
	SA_BarButtonItem				*barItem = [[[factory alloc] initWithBarButtonSystemItem: item target: target action: action] autorelease];
	barItem.style = style;

	if (block) {
		barItem.target = barItem;
		barItem.block = block;
		barItem.action = @selector(__evaluateBlockAsAction);
	}
	return barItem;
}

+ (id) itemWithImage: (UIImage *) image target: (id) target action: (SEL) action block: (barButtonItemArgumentBlock) block style: (UIBarButtonItemStyle) style {
	Class						factory = block ? [SA_BarButtonItem class] : [UIBarButtonItem class];
	SA_BarButtonItem				*barItem = [[[factory alloc] initWithImage: image style: style target: target action: action] autorelease];

	if (block) {
		barItem.target = barItem;
		barItem.block = block;
		barItem.action = @selector(__evaluateBlockAsAction);
	}
	return barItem;
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
