//
//  MFMailComposeViewController+SA_Additions.m
//  Crosswords iOS
//
//  Created by Ben Gottlieb on 8/15/12.
//
//

#import "MFMailComposeViewController+SA_Additions.h"
#import "NSObject+Additions.h"


#define COMPLETION_BLOCK_KEY			@"COMPLETION_BLOCK_KEY"

@implementation MFMailComposeViewController (SA_Additions)
- (void) setCompletionBlock: (mailComposeCompletionBlock) completionBlock {
	if (completionBlock) self.mailComposeDelegate = self;
	[self associateValue: (id) Block_copy(completionBlock) forKey: COMPLETION_BLOCK_KEY];
}

- (mailComposeCompletionBlock) completionBlock {
	return [self associatedValueForKey: COMPLETION_BLOCK_KEY];
}

- (void) mailComposeController: (MFMailComposeViewController *) controller didFinishWithResult: (MFMailComposeResult) result error: (NSError *) error {
	if (error) LOG(@"Error while composing message: %@", error);
	
	if (self.completionBlock) self.completionBlock(result);
	[controller dismissModalViewControllerAnimated: YES];
}

@end