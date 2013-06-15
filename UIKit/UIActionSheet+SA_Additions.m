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
@dynamic SA_buttonSelectBlock;
- (void) addButtonWithTitle: (NSString *) title andSA_Tag: (int) tag {
	NSMutableDictionary				*dictionary = [self associatedValueForKey: kButtonTagsKey];
	
	if (dictionary == nil) {
		dictionary = [NSMutableDictionary dictionary];
		[self associateValue: dictionary forKey: kButtonTagsKey];
	}
	
	[dictionary setObject: $I(tag) forKey: title];
	[self addButtonWithTitle: title];
}

- (int) SA_TagForButtonAtIndex: (NSUInteger) index {
	if (index >= self.numberOfButtons) return 0;
	NSMutableDictionary				*dictionary = [self associatedValueForKey: kButtonTagsKey];
	
	return [[dictionary objectForKey: [self buttonTitleAtIndex: index]] intValue];
}

- (void) clearSA_Tags {
	[self associateValue: nil forKey: kButtonTagsKey];
}

- (void) actionSheet: (UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex {
	intArgumentBlock			block = [self associatedValueForKey: kButtonBlockKey];
	block(buttonIndex);
	Block_release(block);
	[self associateValue: nil forKey: kButtonBlockKey];
}

- (void) showFromView: (UIView *) view withSA_ButtonSelectedBlock: (intArgumentBlock) block {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self showFromView: view withSA_ButtonSelectedBlock: block]; });
		return;
	}

	self.SA_buttonSelectBlock = block;
	[self SA_showFromView: view];
}

- (void) showFromBarButtonItem: (UIBarButtonItem *) item withSA_ButtonSelectedBlock: (intArgumentBlock) block {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self showFromBarButtonItem: item withSA_ButtonSelectedBlock: block]; });
		return;
	}
	
	self.SA_buttonSelectBlock = block;
	[self showFromBarButtonItem: item animated: YES];
}

- (void) setSA_ButtonSelectBlock: (intArgumentBlock) block {
	self.delegate = (id <UIActionSheetDelegate>) self;
	[self associateValue: Block_copy(block) forKey: kButtonBlockKey];
}

- (intArgumentBlock) SA_buttonSelectBlock {
	intArgumentBlock			block = [self associatedValueForKey: kButtonBlockKey];
	return block ? Block_copy(block) : nil;
}

- (void) SA_showFromView: (UIView *) view {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread: @selector(showFromView:) withObject: view waitUntilDone: NO];
		return;
	}
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
