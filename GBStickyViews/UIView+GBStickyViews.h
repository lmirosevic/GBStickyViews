//
//  UIView+GBStickyViews.h
//  GBStickyViews
//
//  Created by Luka Mirosevic on 31/01/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    GBStickyViewsAnchorLeftTop,
    GBStickyViewsAnchorCenterTop,
    GBStickyViewsAnchorRightTop,
    GBStickyViewsAnchorLeftCenter,
    GBStickyViewsAnchorCenterCenter,
    GBStickyViewsAnchorRightCenter,
    GBStickyViewsAnchorLeftBottom,
    GBStickyViewsAnchorCenterBottom,
    GBStickyViewsAnchorRightBottom
} GBStickyViewsAnchor;

@interface UIView (GBStickyViews)

/**
 Attaches the slave view to the master view so that it follows it around at all times according to the anchor config and offset
 */
- (void)attachToView:(UIView *)masterView masterAnchor:(GBStickyViewsAnchor)masterAnchor slaveAnchor:(GBStickyViewsAnchor)slaveAnchor offset:(CGPoint)offset;

@end
