//
//  SA_LazyLoadingScrollView.m
//
//  Created by Ben Gottlieb on 5/25/11.
//  Copyright 2011 Stand Alone, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SA_LazyLoadingScrollView, SA_LazyLoadingScrollViewPage;

@protocol SA_LazyLoadingScrollViewDataSource <NSObject>
- (int) numberOfPagesInScrollView: (SA_LazyLoadingScrollView *) lazyLoadingScrollView;
- (SA_LazyLoadingScrollViewPage *) pageViewAtIndex: (int) index;
@optional
- (void) configurePageView: (SA_LazyLoadingScrollViewPage *) pageView forIndex: (int) index;
- (void) scrollView: (SA_LazyLoadingScrollView *) scrollView didChangeMainIndexTo: (int) index;
@end



@interface SA_LazyLoadingScrollView : UIScrollView <UIScrollViewDelegate> {
}

@property (nonatomic, readwrite, assign) IBOutlet id <SA_LazyLoadingScrollViewDataSource> dataSource;
@property (nonatomic, readwrite, retain) NSMutableSet *unusedPageViews, *visiblePageViews;
@property (nonatomic, readwrite) int mainPageIndex;
@property (nonatomic, readonly) SA_LazyLoadingScrollViewPage *mainPageView;
@property (nonatomic) CGFloat interPageSpacing, pageWidth;
@property (nonatomic, readonly) int numberOfVisiblePageViews;

- (id) dequeueReusablePageViewWithClass:(Class) pageViewClass;

- (void) reloadData;
- (void) updateContentOffset;
- (SA_LazyLoadingScrollViewPage *) visiblePageViewAtIndex: (int) index;
- (void) setMainPageIndex: (NSInteger) index animated:(BOOL) animated;
- (void) hideOffscreenPagesForRotation;
- (void) scrollViewDidScroll: (UIScrollView *) scrollView;
@end



@interface SA_LazyLoadingScrollViewPage : UIView {
}

@property (nonatomic, readwrite, retain) id representedObject;
@property (nonatomic, readwrite) int pageIndex;
@property (nonatomic, readwrite) BOOL isMainPageView;
@property (nonatomic, readonly) CGRect contentFrame, visibleBounds;

@end
