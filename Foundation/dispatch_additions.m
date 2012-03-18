//
//  dispatch_additions.c
//  SABase
//
//  Created by Ben Gottlieb on 2/26/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "dispatch_additions.h"

void	dispatch_on_main_queue(dispatch_block_t block) {
	if (dispatch_get_current_queue() == dispatch_get_main_queue())
		block();
	else
		dispatch_sync(dispatch_get_main_queue(), block);

}
