//
//  dispatch_additions.c
//  SABase
//
//  Created by Ben Gottlieb on 2/26/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "dispatch_additions_SA.h"

void	dispatch_sync_main_queue(dispatch_block_t block) {
	if ([NSThread isMainThread])
		block();
	else
		dispatch_sync(dispatch_get_main_queue(), block);
	
}

void	dispatch_async_main_queue_async(dispatch_block_t block) {
	dispatch_async(dispatch_get_main_queue(), block);
}
