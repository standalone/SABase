//
//  UIGestureRecognizer+Additions.h
//  SABase
//
//  Created by Ben Gottlieb on 7/17/12.
//
//

#import <UIKit/UIKit.h>

typedef void (^gestureArgumentBlock)(UIGestureRecognizer *recog);


@interface UIGestureRecognizer (SA_Additions)

- (id) initWithBlock: (gestureArgumentBlock) block;

@end
