//
//  CAAnimation+SA_Blocks.m
//
//  Created by Ben Gottlieb on 9/9/12.
//  Copyright (c) 2012 Stand Alone, Inc. All rights reserved.
//

#import "CAAnimation+SA_Blocks.h"

#define ANIMATION_DID_START_BLOCK_KEY				@"ANIMATION_DID_START_BLOCK_KEY:SA"
#define ANIMATION_DID_STOP_BLOCK_KEY				@"ANIMATION_DID_STOP_BLOCK_KEY:SA"

@implementation CAAnimation (SA_Blocks)
@dynamic SA_animationDidStartBlock, SA_animationDidStopBlock;

- (void) setSA_AnimationDidStartBlock:(animationDidStartBlock)animationDidStartBlock {
	[self setValue: Block_copy(animationDidStartBlock) forKey: ANIMATION_DID_START_BLOCK_KEY];
	self.delegate = self;
	
}

- (void) setSA_AnimationDidStopBlock: (animationDidStopBlock) animationDidStopBlock {
	[self setValue: Block_copy(animationDidStopBlock) forKey: ANIMATION_DID_STOP_BLOCK_KEY];
	self.delegate = self;
}

- (animationDidStartBlock) SA_animationDidStartBlock { return [self valueForKey: ANIMATION_DID_START_BLOCK_KEY]; }
- (animationDidStopBlock) SA_animationDidStopBlock { return [self valueForKey: ANIMATION_DID_STOP_BLOCK_KEY]; }

- (void) animationDidStop: (CAAnimation *) anim finished: (BOOL) flag {
	animationDidStopBlock			block = self.SA_animationDidStopBlock;
	
	if (block) block(anim, flag);
}

- (void) animationDidStart: (CAAnimation *) anim {
	animationDidStartBlock			block = self.SA_animationDidStartBlock;
	
	if (block) block(anim);	
}

@end
