//
//  SA_StackedScrollView.h
//
//  Created by Ben Gottlieb on 8/11/10.
//  Copyright 2010 Stand Alone, Inc. All rights reserved.
//

#import "SA_StackedScrollView.h"
#import "UIView+SA_Additions.h"

@interface SA_StackedScrollView ()

- (void) queueReload;
- (void) setup;

@end


@implementation SA_StackedScrollView
@synthesize componentViews, stackedScrollViewDelegate, indentationWidth;

- (id) initWithFrame: (CGRect) frame {
    if ((self = [super initWithFrame: frame])) [self setup];
    return self;
}

- (id) initWithCoder: (NSCoder *) coder {
    if ((self = [super initWithCoder: coder])) [self setup];
    return self;
}

- (void) setup {
	self.componentViews = [NSMutableArray array];
	self.dataSource = self;
	self.delegate = self;
	self.separatorStyle = UITableViewCellSeparatorStyleNone;	
}

//=============================================================================================================================
#pragma mark Inserting and removing
- (void) insertComponent: (UIView *) component atIndex: (NSUInteger) index animated: (BOOL) animated {
	index = MIN(index, self.componentViews.count);
	
	if (animated) [self beginUpdates];
	[self.componentViews insertObject: component atIndex: index];
	if (animated) {
		[self insertRowsAtIndexPaths: $A([NSIndexPath indexPathForRow: index inSection: 0]) withRowAnimation: UITableViewRowAnimationTop];
		[self endUpdates];
	} else {
		[self reloadData];
	}
}

- (void) replaceExistingComponent: (UIView *) oldComponent withComponent: (UIView *) newComponent animated: (BOOL) animated {
	NSUInteger				index = [self.componentViews indexOfObject: oldComponent];
	
	if (index != NSNotFound)
		[self replaceComponent: newComponent atIndex: index animated: animated];
	else
		[self addComponent: newComponent animated: animated];
}

- (void) replaceComponent: (UIView *) component atIndex: (NSUInteger) index animated: (BOOL) animated {
	index = MIN(index, self.componentViews.count);
	
	if ([self.componentViews objectAtIndex: index] == component) return;
	
	if (animated) [self beginUpdates];
	[self.componentViews replaceObjectAtIndex: index withObject: component];
	if (animated) {
		[self reloadRowsAtIndexPaths: $A([NSIndexPath indexPathForRow: index inSection: 0]) withRowAnimation: UITableViewRowAnimationFade];
		[self endUpdates];
	} else {
		[self reloadData];
	}
}

- (void) removeAllComponents {
	[self.componentViews removeAllObjects];
	[self reloadData];
}

- (void) removeComponent: (UIView *) component animated: (BOOL) animated { 
	NSUInteger			index = [self.componentViews indexOfObject: component];
	
	if (index != NSNotFound) [self removeComponentAtIndex: index animated: animated];
}

- (void) removeComponentAtIndex: (NSUInteger) index animated: (BOOL) animated {
	index = MIN(index, self.componentViews.count);
	
	if (animated) [self beginUpdates];
	[self.componentViews removeObjectAtIndex: index];
	if (animated) {
		[self deleteRowsAtIndexPaths: $A([NSIndexPath indexPathForRow: index inSection: 0]) withRowAnimation: UITableViewRowAnimationTop];
		[self endUpdates];
	} else {
		[self reloadData];
	}
	
}

- (void) addComponents: (UIView *) component, ... {
	va_list					marker;
	
	va_start(marker, component);
	while (component) {
		SA_AssertAndReturn(![self.componentViews containsObject: component], @"Trying to add a view to a StackedScrollView that's already been added");
		[self.componentViews addObject: component];
		component = va_arg(marker, UIView *);
	}
	va_end(marker);

	[self reloadData];
}

- (void) addComponent: (UIView *) component animated: (BOOL) animated {
	SA_AssertAndReturn(![self.componentViews containsObject: component], @"Trying to add a view to a StackedScrollView that's already been added");
	if (animated) [self beginUpdates];
	[self.componentViews addObject: component];
	if (animated) {
		[self insertRowsAtIndexPaths: $A([NSIndexPath indexPathForRow: self.componentViews.count - 1 inSection: 0]) withRowAnimation: UITableViewRowAnimationTop];
		[self endUpdates];
	} else {
		[self reloadData];
	}
}

- (BOOL) isComponentInStack: (UIView *) component {
	return [self.componentViews containsObject: component];
}

- (void) addSpacer: (CGFloat) spacerHeight {
	[self.componentViews addObject: $F(spacerHeight)];
}

//=============================================================================================================================
#pragma mark Private
- (void) queueReload {
	[NSObject cancelPreviousPerformRequestsWithTarget: self selector: @selector(reloadData) object: nil];
	[self performSelector: @selector(reloadData) withObject: nil afterDelay: 0.0];
}

//==========================================================================================
#pragma mark Table DataSource/Delegate
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath {
	NSString								*cellIdentifier = @"SA_stackedViewRowCell";
	UITableViewCell							*cell = nil;//[tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	UIView									*view = [self.componentViews objectAtIndex: indexPath.row];
	
	if ([view isKindOfClass: [UITableViewCell class]]) return (id) view;
	if ([view isKindOfClass: [NSNumber class]]) {
		cellIdentifier = @"spacer";
		cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
		}
		return cell;
	}
	
	cell = [tableView dequeueReusableCellWithIdentifier: cellIdentifier];
	[cell.contentView removeAllSubviews];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.clipsToBounds = YES;
	}
	
	CGRect					frame = cell.contentView.bounds;
	
	frame.origin.x += self.indentationWidth;
	frame.size.width -= self.indentationWidth * 2;
	view.normalizedFrame = frame;
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[cell.contentView addSubview: view];
	
	return cell;
}

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView {return 1;}
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section {return self.componentViews.count;}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath {
	UIView						*component = [self.componentViews objectAtIndex: indexPath.row];
	
	if ([component isKindOfClass: [NSNumber class]]) return [(id) component floatValue];
	
	float						height = component.bounds.size.height;
	
	return height;
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath {
	if ([[self.componentViews objectAtIndex: indexPath.row] isKindOfClass: [UITableViewCell class]]) {
		[self deselectRowAtIndexPath: indexPath animated: YES];
		if ([self.stackedScrollViewDelegate respondsToSelector: @selector(stackedScrollView:didSelectRowAtIndexPath:)]) {
			[self.stackedScrollViewDelegate stackedScrollView: self didSelectRowAtIndexPath: indexPath];
	
		}
	}
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	if ([self.stackedScrollViewDelegate respondsToSelector: @selector(scrollViewDidScroll:)]) {
		[self.stackedScrollViewDelegate scrollViewDidScroll: self];
		
	}
}

@end


@implementation UIView (SA_StackedScrollView)
- (SA_StackedScrollView *) stackedScrollView {
	UIView				*superview = [self superview];
	
	while (superview && ![superview isKindOfClass: [SA_StackedScrollView class]]) {
		superview = [superview superview];
	}
	
	return (id) superview;
}
@end
