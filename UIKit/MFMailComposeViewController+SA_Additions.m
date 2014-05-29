//
//  MFMailComposeViewController+SA_Additions.m
//  Crosswords iOS
//
//  Created by Ben Gottlieb on 8/15/12.
//
//

#import "MFMailComposeViewController+SA_Additions.h"
#import "NSObject+SA_Additions.h"


#define COMPLETION_BLOCK_KEY			@"COMPLETION_BLOCK_KEY"

@implementation MFMailComposeViewController (SA_Additions)
@dynamic SA_CompletionBlock;
- (void) setSA_CompletionBlock: (mailComposeCompletionBlock) completionBlock {
	if (completionBlock) self.mailComposeDelegate = self;
	[self associateValue: [completionBlock copy] forKey: COMPLETION_BLOCK_KEY];
}

- (mailComposeCompletionBlock) completionBlock {
	return [self associatedValueForKey: COMPLETION_BLOCK_KEY];
}

- (void) mailComposeController: (MFMailComposeViewController *) controller didFinishWithResult: (MFMailComposeResult) result error: (NSError *) error {
	if (error) SA_BASE_LOG(@"Error while composing message: %@", error);
	
	if (self.completionBlock) self.completionBlock(result);
	[controller dismissViewControllerAnimated: YES completion: nil];
}

@end
