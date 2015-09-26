//
//  UIActionSheet+Additions.m
//
//  Created by Ben Gottlieb on 11/25/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//


#import "NSObject+SA_Additions.h"
#import "dispatch_additions_SA.h"
#import "UIViewController+SA_Additions.h"

static UIColor			*s_actionSheetTintColor = nil;
static UIColor			*s_actionSheetBackgroundColor = nil;

@interface SA_ActionSheetViewController: UIAlertController
@property (nonatomic, strong) UIColor *originalTintColor;
@end

@implementation SA_ActionSheetViewController
- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	self.originalTintColor = self.view.window.tintColor;
	self.view.window.tintColor = s_actionSheetTintColor ?: [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear: animated];
	self.view.window.tintColor = self.originalTintColor;
}
@end

#define					kButtonTagsKey				@"buttonTags:SAI"
#define					kButtonBlockKey				@"ClickedButtonAtIndex:SAI"
#define					kRunBlockAfterDismissKey	@"RunBlockAfterDismissAtIndex:SAI"

@implementation UIActionSheet (SA_AdditionsForButtons)

+ (void) setActionSheetTintColor: (UIColor *) color { s_actionSheetTintColor = color; }
+ (void) setActionSheetBackgroundColor: (UIColor *) color { s_actionSheetBackgroundColor = color; }

- (void) addButtonWithTitle: (NSString *) title andSA_Tag: (NSInteger) tag {
	NSMutableDictionary				*dictionary = [self associatedValueForKey: kButtonTagsKey];
	
	if (dictionary == nil) {
		dictionary = [NSMutableDictionary dictionary];
		[self associateValue: dictionary forKey: kButtonTagsKey];
	}
	
	[dictionary setObject: @(tag) forKey: title];
	[self addButtonWithTitle: title];
}

- (void) setShouldRunBlockAfterDismissal: (BOOL) runAfter {
	if (runAfter) {
		[self associateValue: @true forKey: kRunBlockAfterDismissKey];
	} else {
		[self removeAssociateValueForKey: kRunBlockAfterDismissKey];
	}
}

- (BOOL) shouldRunBlockAfterDismissal { return [[self associatedValueForKey: kRunBlockAfterDismissKey] boolValue]; }

- (NSInteger) SA_TagForButtonAtIndex: (NSUInteger) index {
	if (index >= self.numberOfButtons) return 0;
	NSMutableDictionary				*dictionary = [self associatedValueForKey: kButtonTagsKey];
	
	return [[dictionary objectForKey: [self buttonTitleAtIndex: index]] intValue];
}

- (void) clearSA_Tags {
	[self associateValue: nil forKey: kButtonTagsKey];
}

- (UIAlertController *) composedAlertController {
	UIAlertController			*composed = [SA_ActionSheetViewController alertControllerWithTitle: self.title message: nil preferredStyle: UIAlertControllerStyleActionSheet];
	
	for (NSInteger index = 0; index < self.numberOfButtons; index++) {
		if (index != self.cancelButtonIndex && index != self.destructiveButtonIndex)
			[composed addAction: [NSClassFromString(@"UIAlertAction") actionWithTitle: [self buttonTitleAtIndex: index] style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
				[self actionSheet: self clickedButtonAtIndex: index];
				[self actionSheet: self didDismissWithButtonIndex: index];
			}]];
	}
	
	if (self.cancelButtonIndex != -1) {
		[composed addAction: [NSClassFromString(@"UIAlertAction") actionWithTitle: [self buttonTitleAtIndex: self.cancelButtonIndex] style: UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
			[self actionSheet: self clickedButtonAtIndex: self.cancelButtonIndex];
			[self actionSheet: self didDismissWithButtonIndex: self.cancelButtonIndex];
		}]];
	}
	
	if (self.destructiveButtonIndex != -1) {
		[composed addAction: [NSClassFromString(@"UIAlertAction") actionWithTitle: [self buttonTitleAtIndex: self.destructiveButtonIndex] style: UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
			[self actionSheet: self clickedButtonAtIndex: self.destructiveButtonIndex];
			[self actionSheet: self didDismissWithButtonIndex: self.destructiveButtonIndex];
		}]];
	}
	
	if (s_actionSheetTintColor) composed.view.tintColor = s_actionSheetTintColor;
	if (s_actionSheetBackgroundColor) composed.view.backgroundColor = s_actionSheetBackgroundColor;
	return composed;
}

- (void) presentComposedControllerFromView: (UIView *) view {
	UIAlertController			*controller = self.composedAlertController;
	
	controller.popoverPresentationController.sourceView = view;
	controller.popoverPresentationController.sourceRect = [view bounds];
	
	[view.viewController presentViewController: controller animated: YES completion: nil];
}

- (void) presentComposedControllerFromBarButtonItem: (UIBarButtonItem *) item {
	UIAlertController			*controller = self.composedAlertController;
	
	controller.popoverPresentationController.barButtonItem = item;
	
	UIViewController			*presenter = [UIApplication sharedApplication].keyWindow.rootViewController;
	
	while (presenter.presentedViewController) { presenter = presenter.presentedViewController; }
	
	[presenter presentViewController: controller animated: YES completion: nil];
}

- (void) actionSheet: (UIActionSheet *) actionSheet clickedButtonAtIndex: (NSInteger) buttonIndex {
	if (!self.shouldRunBlockAfterDismissal) {
		actionSheetButtonSelectedBlock			block = [self associatedValueForKey: kButtonBlockKey];
		[self associateValue: nil forKey: kButtonBlockKey];
		if (block) block(buttonIndex);
	}
}

- (void)actionSheet: (UIActionSheet *) actionSheet didDismissWithButtonIndex: (NSInteger) buttonIndex {
	if (self.shouldRunBlockAfterDismissal) {
		actionSheetButtonSelectedBlock			block = [self associatedValueForKey: kButtonBlockKey];
		[self associateValue: nil forKey: kButtonBlockKey];
		if (block) dispatch_async_main_queue(^{
			block(buttonIndex);
		});
	}
}

//================================================================================================================
#pragma mark Presentation methods

- (void) showFromView: (UIView *) view withSA_ButtonSelectedBlock: (actionSheetButtonSelectedBlock) block {
	if (view.window == nil) return;		//no window
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self showFromView: view withSA_ButtonSelectedBlock: block]; });
		return;
	}

	if (view.window == nil) view = [[UIApplication sharedApplication] keyWindow];
	
	self.SA_buttonSelectBlock = block;
	
	if (RUNNING_ON_80)
		[self presentComposedControllerFromView: view];
	else
		[self SA_showFromView: view];
}

- (void) showFromBarButtonItem: (UIBarButtonItem *) item withSA_ButtonSelectedBlock: (actionSheetButtonSelectedBlock) block {
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^{ [self showFromBarButtonItem: item withSA_ButtonSelectedBlock: block]; });
		return;
	}
	
	self.SA_buttonSelectBlock = block;
	if (RUNNING_ON_80)
		[self presentComposedControllerFromBarButtonItem: item];
	else
		[self showFromBarButtonItem: item animated: YES];
}

- (void) setSA_buttonSelectBlock: (actionSheetButtonSelectedBlock) block {
	self.delegate = (id <UIActionSheetDelegate>) self;
	[self associateValue: [block copy] forKey: kButtonBlockKey];
}

- (actionSheetButtonSelectedBlock) SA_buttonSelectBlock {
	actionSheetButtonSelectedBlock			block = [self associatedValueForKey: kButtonBlockKey];
	return [block copy];
}

- (void) SA_showFromView: (UIView *) view {
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread: @selector(showFromView:) withObject: view waitUntilDone: NO];
		return;
	}

	if (RUNNING_ON_80) {
		[self presentComposedControllerFromView: view];
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
