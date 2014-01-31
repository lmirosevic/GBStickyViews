//
//  UIView+GBStickyViews.h
//  GBStickyViews
//
//  Created by Luka Mirosevic on 31/01/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    GBStickyViewsAnchorTopLeft,
    GBStickyViewsAnchorTopCenter,
    GBStickyViewsAnchorTopRight,
    GBStickyViewsAnchorCenterLeft,
    GBStickyViewsAnchorCenterCenter,
    GBStickyViewsAnchorCenterRight,
    GBStickyViewsAnchorBottomLeft,
    GBStickyViewsAnchorBottomCenter,
    GBStickyViewsAnchorBottomRight
} GBStickyViewsAnchor;

@interface UIView (GBStickyViews)

-(void)attachToView:(UIView *)masterView masterAnchor:(GBStickyViewsAnchor)masterAnchor slaveAnchor:(GBStickyViewsAnchor)slaveAnchor track:(BOOL)shouldTrack;

@end

