//
//  SA_ProgressView.m
//  RESTFramework Harness
//
//  Created by Ben Gottlieb on 5/30/14.
//  Copyright (c) 2014 Stand Alone, Inc. All rights reserved.
//

#import "SA_ProgressView.h"

@implementation SA_ProgressView

DEFAULT_VIEW_INIT_METHODS;

- (id) postInitSetup {
	self.foregroundColor = [UIColor whiteColor];
	self.backgroundColor = [UIColor clearColor];
	
	self.type = SA_ProgressView_radial;
	return self;
}

- (void) setProgress: (CGFloat) progress {
	if (progress < 0) progress = 0.0;
	if (progress > 1.0) progress = 1.0;
	
	if (_progress == progress) return;
	_progress = progress;
	[self setNeedsDisplay];
}

- (void) setType: (SA_ProgressView_type) type {
	if (_type == type) return;
	
	_type = type;
	[self setNeedsDisplay];
}

- (void) drawRect: (CGRect) rect {
	CGRect					frame = self.bounds;
		
	if (self.type == SA_ProgressView_linear) {
		CGFloat					lineWidth = floorf(frame.size.height / 7);
		
		if (lineWidth < 1) lineWidth = 1;
		
		frame = CGRectInset(frame, lineWidth / 2, lineWidth / 2);
		UIBezierPath				*path = [UIBezierPath bezierPathWithRoundedRect: frame byRoundingCorners: UIRectCornerAllCorners cornerRadii: CGSizeMake(frame.size.height / 2, frame.size.height / 2)];
		
		path.lineWidth = lineWidth;
		[self.foregroundColor setStroke];
		[path stroke];
		
		frame = CGRectInset(frame, lineWidth * 1.75, lineWidth * 1.75);
		path = [UIBezierPath bezierPathWithRoundedRect: frame byRoundingCorners: UIRectCornerAllCorners cornerRadii: CGSizeMake(frame.size.height / 2, frame.size.height / 2)];
				
		frame.size.width *= self.progress;
		UIRectClip(frame);
		[self.foregroundColor setFill];
		[path fill];
	} else {
		CGFloat					minSide = MIN(frame.size.width, frame.size.height);
		
		if (minSide < self.bounds.size.width) {
			frame.origin.x += (frame.size.width - minSide) / 2;
		} else
			frame.origin.y += (frame.size.height - minSide) / 2;
		
		frame.size.width = minSide;
		frame.size.height = minSide;
		
		CGFloat					lineWidth = floorf(frame.size.height / 10);
		frame = CGRectInset(frame, lineWidth / 2, lineWidth / 2);

		UIBezierPath			*border = [UIBezierPath bezierPathWithOvalInRect: frame];
		
		border.lineWidth = lineWidth;
		[self.foregroundColor setStroke];
		[border stroke];

		frame = CGRectInset(frame, lineWidth, lineWidth);

		CGFloat					percentage = self.progress;
		UIBezierPath			*path = [UIBezierPath bezierPath];
		
		[path moveToPoint: CGRectCenter(frame)];
		[path addArcWithCenter: CGRectCenter(frame) radius: frame.size.width / 2 startAngle: -M_PI / 2 endAngle: (2 * M_PI * percentage) - (M_PI / 2) clockwise: YES];
		[self.foregroundColor setFill];
		[path fill];
	}
}

@end
