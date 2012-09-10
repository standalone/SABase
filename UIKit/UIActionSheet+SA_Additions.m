//
//  UIActionSheet+Additions.m
//
//  Created by Ben Gottlieb on 11/25/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "UIActionSheet+SA_Additions.h"
#import "NSObject+SA_Additions.h"

#define					kButtonTagsKey			@"buttonTags:SAI"
#define					kButtonBlockKey			@"ClickedButtonAtIndex:SAI"

@implementation UIActionSheet (SA_AdditionsForButtons)

- (void) addButtonWithTitle: (NSString *) title andTag: (int) tag {
	NSMutableDictionary				*dictionary = [self associatedValueForKey: kButtonTagsKey];
	
	if (dictionary == nil) {
		dictionary = [NSMutableDictionary dictionary];
		[self associateValue: dictionary forKey: kButtonTagsKey];
	}
	
	[dictionary setObject: $I(tag) forKey: title];
	[self addButtonWithTitle: title];
}

- (int) tagForButtonAtIndex: (NSUInteger) index {
	if (index >= self.numberOfButtons) return 0;
	NSMutableDictionary				*dictionary = [self associatedValueForKey: kButtonTagsKey];
	
	return [[dictionary objectForKey: [self buttonTitleAtIndex: index]] intValue];
}

- (void) clearButtonTags {
	[self associateValue: nil forKey: kButtonTagsKey];
}

#if NS_BLOCKS_AVAILABLE
- (void) actionSheet: (UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex {
	intArgumentBlock			block = [self associatedValueForKey: kButtonBlockKey];
	block(buttonIndex);
	Block_release(block);
	[self associateValue: nil forKey: kButtonBlockKey];
}

- (void) showFromView: (UIView *) view withButtonSelectedBlock: (intArgumentBlock) block {
	self.delegate = (id <UIActionSheetDelegate>) self;
	[self associateValue: Block_copy(block) forKey: kButtonBlockKey];
	[self showFromView: view];
}

- (void) showFromBarButtonItem: (UIBarButtonItem *) item withButtonSelectedBlock: (intArgumentBlock) block {
	self.delegate = (id <UIActionSheetDelegate>) self;
	[self associateValue: Block_copy(block) forKey: kButtonBlockKey];
	[self showFromBarButtonItem: item animated: YES];
}
#endif

- (void) showFromView: (UIView *) view {
	if ([view isKindOfClass: [UIControl class]] && RUNNING_ON_IPAD) {
		[self showFromRect: [view bounds] inView: view animated: YES];
	} else if ([view isKindOfClass: [UITabBar class]]) {
		[self showFromTabBar: (UITabBar *) view];
	} else if ([view isKindOfClass: [UIToolbar class]]) {
		[self showFromToolbar: (UIToolbar *) view];
	} else if (view.bounds.size.width < 300) {
		[self showFromRect: [view bounds] inView: view animated: YES];
	} else {
		[self showInView: view];
	}
}



@end
