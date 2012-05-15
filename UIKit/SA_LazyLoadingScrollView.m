//
//  SA_LazyLoadingScrollView.m
//
//  Created by Ben Gottlieb on 5/25/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import "SA_LazyLoadingScrollView.h"

@interface SA_LazyLoadingScrollView ()

@property (nonatomic, readwrite) int numberOfPageViews;
@property (nonatomic, assign) id <UIScrollViewDelegate> exteriorDelegate;
@property (nonatomic) BOOL customPageWidth;

- (BOOL) isDisplayingPageForIndex: (int) index;
- (CGRect) frameForViewAtIndex: (NSUInteger) index;
- (void) resetVisiblePageViews;
- (void) setupPages;
- (SA_LazyLoadingScrollViewPage *) dequeuePageViewAtIndex: (int) index;
- (void) configurePageView: (SA_LazyLoadingScrollViewPage *) view forIndex: (int) index;
@end


@implementation SA_LazyLoadingScrollView
@synthesize unusedPageViews, visiblePageViews, mainPageIndex, dataSource = _dataSource, numberOfPageViews, exteriorDelegate;
@synthesize interPageSpacing, pageWidth = _pageWidth, customPageWidth;

- (void) dealloc {
	self.visiblePageViews = nil;
	self.unusedPageViews = nil;
	self.dataSource = nil;
    [super dealloc];
}

- (void) reloadData {
	if (self.visiblePageViews == nil) self.visiblePageViews = [NSMutableSet set];
	if (self.unusedPageViews == nil) self.unusedPageViews = [NSMutableSet set];
	
	self.numberOfPageViews = [self.dataSource numberOfPagesInScrollView: self];
	[self resetVisiblePageViews];
	[self setNeedsLayout];
}

- (id) dequeueReusablePageViewWithClass:(Class) pageViewClass {
    for (SA_LazyLoadingScrollViewPage *page in self.unusedPageViews) {
        if ([page isMemberOfClass:pageViewClass]) {
            [[page retain] autorelease];
            [self.unusedPageViews removeObject: page];
            return page;
        }
    }
    
    return nil;
}

- (void) didMoveToSuperview {
	if (self.delegate == self) return;		//already set up
	self.mainPageIndex = 0;
	self.delegate = self;
	[self reloadData];
}

//=============================================================================================================================
#pragma mark Layout
- (void) setFrame: (CGRect) frame {
	NSInteger				firstIndex = self.mainPageIndex;
	[super setFrame: frame];
	self.visiblePageViews = nil;
	self.unusedPageViews = nil;
	if (!self.customPageWidth) _pageWidth = 0;
	[self reloadData];
	
	[self setMainPageIndex: firstIndex animated: NO];
}
- (void) layoutSubviews {
	[super layoutSubviews];
	[self setupPages];
}

- (void) updateContentOffset {
	CGPoint adjustedContentOffset = CGPointZero;
    
    [self setupPages];
    
	SA_LazyLoadingScrollViewPage *curPageView = [self dequeuePageViewAtIndex: self.mainPageIndex];
	if (curPageView) {
		adjustedContentOffset = curPageView.frame.origin;
	}
    
	[self setContentOffset: adjustedContentOffset animated:YES];
}

- (void) hideOffscreenPagesForRotation {
	for (UIView *view in self.visiblePageViews) {
		if (view == self.mainPageView) continue;
		
		[self.unusedPageViews addObject: view];
		[view removeFromSuperview];
	}
	self.contentSize = self.bounds.size;
	self.contentOffset = CGPointZero;
	self.mainPageView.frame = self.bounds;
}

#pragma mark private methods
- (SA_LazyLoadingScrollViewPage *) visiblePageViewAtIndex: (int) index {
    for (SA_LazyLoadingScrollViewPage *page in self.visiblePageViews) { if (page.pageIndex == index) return page; }
	return nil;
}

- (SA_LazyLoadingScrollViewPage *) mainPageView {
	return [self visiblePageViewAtIndex: self.mainPageIndex];
}

- (void) setupPages {	
	if (self.pageWidth == 0) _pageWidth = self.bounds.size.width;
	self.contentSize = CGSizeMake(self.pageWidth * self.numberOfPageViews, self.bounds.size.height);
	
	int		firstNeededItemIndex = MAX(self.mainPageIndex - 1, 0);
	int		lastNeededItemIndex  = MIN(firstNeededItemIndex + self.numberOfVisiblePageViews + 1, self.numberOfPageViews - 1);

	// Recycle no-longer-visible pages 
	for (SA_LazyLoadingScrollViewPage *view in self.visiblePageViews) {
		if (view.pageIndex < firstNeededItemIndex || view.pageIndex > lastNeededItemIndex) {
			[self.unusedPageViews addObject: view];
			[view removeFromSuperview];
		} else {
			// Update frame of visible pages in case view has been rotated.
			[self configurePageView: view forIndex: view.pageIndex];
		}

	}
	[self.visiblePageViews minusSet: self.unusedPageViews];
	
	// add missing pages. We do this twice, first to pull out any previously loaded page views
	for (int index = firstNeededItemIndex; index <= lastNeededItemIndex; index++) {
		if ( ![self isDisplayingPageForIndex: index] && index < self.numberOfPageViews) {
			SA_LazyLoadingScrollViewPage			*view = [self dequeuePageViewAtIndex: index];
			
			if (view == nil) view = [self.dataSource pageViewAtIndex: index];
			if (view == nil) continue;
            
			[self configurePageView: view forIndex: index];
			[self addSubview: view];
			[self.visiblePageViews addObject: view];
		}
	}    
}

- (void) resetVisiblePageViews {
	for (SA_LazyLoadingScrollViewPage *view in self.visiblePageViews) {
		[self.unusedPageViews addObject: view];
		[view removeFromSuperview];
	}
	[self.visiblePageViews removeAllObjects];	
}

- (SA_LazyLoadingScrollViewPage *) dequeuePageViewAtIndex: (int) index {
	SA_LazyLoadingScrollViewPage *foundPage = nil;
		
    for (SA_LazyLoadingScrollViewPage *page in self.visiblePageViews) {
        if (page.pageIndex == index) {
            foundPage = page;
            break;
        }
    }
	
	if (foundPage == nil) foundPage = [self.unusedPageViews anyObject];
    
	if (foundPage) {
        [[foundPage retain] autorelease];
        [self.unusedPageViews removeObject: foundPage];
    }

    return foundPage;
}

- (void) configurePageView: (SA_LazyLoadingScrollViewPage *) view forIndex: (int) index {
    view.frame = [self frameForViewAtIndex: index];
	
	if ([self.dataSource respondsToSelector: @selector(configurePageView:forIndex:)]) {
		[self.dataSource configurePageView: view forIndex: index];
	}
	view.pageIndex = index;
    
    // Let the page view know if it has focus or not.
    view.isMainPageView = (view.pageIndex == self.mainPageIndex);
}

- (BOOL) isDisplayingPageForIndex: (int) index {
    for (SA_LazyLoadingScrollViewPage *view in self.visiblePageViews) {
        if (view.pageIndex == index) {
            return YES;
        }
    }
    return NO;
}

- (CGRect) frameForViewAtIndex: (NSUInteger) index {
	float			width = self.pageWidth ?: self.bounds.size.width;
    CGRect			bounds = self.bounds;
    CGRect			pageFrame = bounds;
    pageFrame.size.width = width - (2 * self.interPageSpacing);
    pageFrame.origin.x = (width + self.interPageSpacing) * index;
    return pageFrame;
}

- (void) setMainPageIndex: (NSInteger) index {
	[self setMainPageIndex: index animated: YES];
}

- (void) setMainPageIndex: (NSInteger) index animated:(BOOL) animated {
	mainPageIndex = index;
	CGRect destFrame = [self frameForViewAtIndex: index];
	[self setContentOffset:destFrame.origin animated: animated];
}

- (int) mainPageIndex {
	if (self.pageWidth == 0) return 0;
	int		index = ((int) self.contentOffset.x) / (int) self.pageWidth;
	
	return index;
}

- (int) numberOfVisiblePageViews {
	return ceil(self.bounds.size.width / self.pageWidth);
}

//- (void) setScrollEnabled:(BOOL)scrollEnabled {
//    [super setScrollEnabled:scrollEnabled];
//    
//    for (SA_LazyLoadingScrollViewPage *view in self.visiblePageViews) {
//		if (view.pageIndex == self.mainPageIndex) {
//			view.scrollEnabled = scrollEnabled;
//		}         
//	}
//}

//=============================================================================================================================
#pragma mark Properties
- (void) setDataSource: (id <SA_LazyLoadingScrollViewDataSource>) newDataSource {
    if (_dataSource != newDataSource) {
        _dataSource = newDataSource;
        [self reloadData];
    }
}

- (void) setDelegate: (id <UIScrollViewDelegate>) newDelegate {
	if (newDelegate == self) {
		[super setDelegate: newDelegate];
	} else {
		self.exteriorDelegate = newDelegate;
	}
}

- (void) setPageWidth: (CGFloat) pageWidth {
	_pageWidth = pageWidth;
	self.customPageWidth = YES;
}

//=============================================================================================================================
#pragma mark Delegate Methods
- (void) scrollViewDidScroll: (UIScrollView *) scrollView {
	[self setupPages];
	if ([self.exteriorDelegate respondsToSelector: @selector(scrollViewDidScroll:)]) [self.exteriorDelegate scrollViewDidScroll: self];
}

//- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
//    for (SA_LazyLoadingScrollViewPage *page in self.visiblePageViews) {
//        if (page.pageIndex == self.mainPageIndex) {
//            [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_PageViewScrollBegan object: page userInfo:nil];
//            break;
//        }
//    }
//	if ([self.exteriorDelegate respondsToSelector: @selector(scrollViewWillBeginDragging:)]) [self.exteriorDelegate scrollViewWillBeginDragging: self];
//}

- (void) scrollViewDidEndDecelerating: (UIScrollView *) scrollView {
	if (self.pagingEnabled) {
		self.mainPageIndex = ((int) self.contentOffset.x) / (int) self.pageWidth;
		if ([self.dataSource respondsToSelector: @selector(scrollView:didChangeMainIndexTo:)]) [self.dataSource scrollView: self didChangeMainIndexTo: self.mainPageIndex];
	}
	[self setupPages];

	if ([self.exteriorDelegate respondsToSelector: @selector(scrollViewDidEndDecelerating:)]) [self.exteriorDelegate scrollViewDidEndDecelerating: self];
    
//    for (SA_LazyLoadingScrollViewPage *page in self.visiblePageViews) {
//        if (page.pageIndex == self.mainPageIndex) {
//            [[NSNotificationCenter defaultCenter] postNotificationName: kNotification_PageViewScrollFinished object: page userInfo:nil];
//            break;
//        }
//    }
}


@end

@implementation SA_LazyLoadingScrollViewPage
@synthesize representedObject, pageIndex, isMainPageView;

- (void)dealloc {
	self.representedObject = nil;
    [super dealloc];
}

//=============================================================================================================================
#pragma mark Properties

- (CGRect) contentFrame {
	CGRect					bounds = self.bounds;
	return bounds;
}

- (CGRect) visibleBounds {
	return self.contentFrame;
}

- (NSString *) description {
	return $S(@"%@; index: %d", [super description], self.pageIndex);
}

@end
