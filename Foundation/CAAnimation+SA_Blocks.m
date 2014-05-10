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
	[self setValue: [animationDidStartBlock copy] forKey: ANIMATION_DID_START_BLOCK_KEY];
	self.delegate = self;			//danger! possible retain cycle.
	
}

- (void) setSA_AnimationDidStopBlock: (animationDidStopBlock) animationDidStopBlock {
	[self setValue: [animationDidStopBlock copy] forKey: ANIMATION_DID_STOP_BLOCK_KEY];
	self.delegate = self;
}

- (animationDidStartBlock) SA_animationDidStartBlock { return [self valueForKey: ANIMATION_DID_START_BLOCK_KEY]; }
- (animationDidStopBlock) SA_animationDidStopBlock { return [self valueForKey: ANIMATION_DID_STOP_BLOCK_KEY]; }

- (void) animationDidStop: (CAAnimation *) anim finished: (BOOL) flag {
	animationDidStopBlock			block = self.SA_animationDidStopBlock;
	
	if (block) block(anim, flag);
	self.delegate = nil;			//otherwise we get a retain cycle
}

- (void) animationDidStart: (CAAnimation *) anim {
	animationDidStartBlock			block = self.SA_animationDidStartBlock;
	
	if (block) block(anim);
	if (self.SA_animationDidStopBlock == nil) self.delegate = nil;	//prevent retain cycles
}

@end
