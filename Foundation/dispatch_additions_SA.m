//
//  dispatch_additions.c
//  SABase
//
//  Created by Ben Gottlieb on 2/26/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "dispatch_additions_SA.h"

void	dispatch_sync_main_queue(dispatch_block_t block) {
	if (block == nil) return;
	if ([NSThread isMainThread])
		block();
	else
		dispatch_sync(dispatch_get_main_queue(), block);
	
}

void	dispatch_async_main_queue(dispatch_block_t block) {
	if (block == nil) return;
	dispatch_async(dispatch_get_main_queue(), block);
}

void	dispatch_on_main_queue(dispatch_block_t block) {
	if (block == nil) return;
	
	if ([NSThread isMainThread])
		block();
	else
		dispatch_async(dispatch_get_main_queue(), block);
}

void	dispatch_after_main_queue(NSTimeInterval delay, dispatch_block_t block) {
	if (block) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)( delay * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}