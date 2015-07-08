//
//  UIView+GBStickyViews.m
//  GBStickyViews
//
//  Created by Luka Mirosevic on 31/01/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import "UIView+GBStickyViews.h"


typedef struct {
    NSLayoutAttribute horizontal;
    NSLayoutAttribute vertical;
} GBStickyViewAutolayoutAttributePair;

static inline GBStickyViewAutolayoutAttributePair GBStickyViewAutolayoutAttributePairMake(NSLayoutAttribute horizontal, NSLayoutAttribute vertical) {
    return (GBStickyViewAutolayoutAttributePair){horizontal, vertical};
}


@implementation UIView (GBStickyViews)

#pragma mark - API

- (void)attachToView:(UIView *)masterView masterAnchor:(GBStickyViewsAnchor)masterAnchor slaveAnchor:(GBStickyViewsAnchor)slaveAnchor offset:(CGPoint)offset {
    //ensure we're attached to some view
    if (!self.superview) @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Must first add this view to a superview, and then call attachToView:masterAnchor:slaveAnchor:offset:track:" userInfo:nil];
    //ensure masterView is not nil
    if (!masterView) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"masterView must not be nil" userInfo:nil];
    //ensure master is attached to some view
    if (!masterView.superview) @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Must first add the masterView to a superview, and then call attachToView:masterAnchor:slaveAnchor:offset:track:" userInfo:nil];
    //ensure that we are not a parent of the masterView
    if ([self _isParentOfView:masterView]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Tried to attach a view to a master view when the master view was a child view." userInfo:nil];
    
    // make sure that we are enabled for autolayout
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    // find the lowest common ancestor to which to add the layout constraint
    UIView *lowestCommonAncestor = [self _lowestCommonAncestorWithView:masterView];
    
    // prepare the constraints as they are called in the autolayout world
    GBStickyViewAutolayoutAttributePair autolayoutAttributePairMaster = [self.class _autolayoutAttributePairForAnchor:masterAnchor];
    GBStickyViewAutolayoutAttributePair autolayoutAttributePairSlave = [self.class _autolayoutAttributePairForAnchor:slaveAnchor];
    
    
    // use autolayout to set up the constraints
    [lowestCommonAncestor addConstraints:@[
        // horizontal
        [NSLayoutConstraint constraintWithItem:self attribute:autolayoutAttributePairSlave.horizontal relatedBy:NSLayoutRelationEqual toItem:masterView attribute:autolayoutAttributePairMaster.horizontal multiplier:1.0 constant:offset.x],
        
        // vertical
        [NSLayoutConstraint constraintWithItem:self attribute:autolayoutAttributePairSlave.vertical relatedBy:NSLayoutRelationEqual toItem:masterView attribute:autolayoutAttributePairMaster.vertical multiplier:1.0 constant:offset.y]
    ]];
    
    // that's it we're done, with autolayout it's super simple :)
}

#pragma mark - Util

+ (NSLayoutAttribute)_autolayoutHorizontalAttributeForAnchor:(GBStickyViewsAnchor)anchor {
    switch (anchor) {
        case GBStickyViewsAnchorLeftTop:
        case GBStickyViewsAnchorLeftCenter:
        case GBStickyViewsAnchorLeftBottom:
            return NSLayoutAttributeLeft;
            
            
        case GBStickyViewsAnchorCenterTop:
        case GBStickyViewsAnchorCenterCenter:
        case GBStickyViewsAnchorCenterBottom:
            return NSLayoutAttributeCenterX;
            
        case GBStickyViewsAnchorRightTop:
        case GBStickyViewsAnchorRightCenter:
        case GBStickyViewsAnchorRightBottom:
            return NSLayoutAttributeRight;
    }
}

+ (NSLayoutAttribute)_autolayoutVerticalAttributeForAnchor:(GBStickyViewsAnchor)anchor {
    switch (anchor) {
        case GBStickyViewsAnchorLeftTop:
        case GBStickyViewsAnchorCenterTop:
        case GBStickyViewsAnchorRightTop:
            return NSLayoutAttributeTop;
            
        case GBStickyViewsAnchorLeftCenter:
        case GBStickyViewsAnchorCenterCenter:
        case GBStickyViewsAnchorRightCenter:
            return NSLayoutAttributeCenterY;
            
        case GBStickyViewsAnchorLeftBottom:
        case GBStickyViewsAnchorCenterBottom:
        case GBStickyViewsAnchorRightBottom:
            return NSLayoutAttributeBottom;
    }
}

+ (GBStickyViewAutolayoutAttributePair)_autolayoutAttributePairForAnchor:(GBStickyViewsAnchor)anchor {
    return GBStickyViewAutolayoutAttributePairMake([self _autolayoutHorizontalAttributeForAnchor:anchor], [self _autolayoutVerticalAttributeForAnchor:anchor]);
}

- (UIView *)_lowestCommonAncestorWithView:(UIView *)view {
    return [self.class _lowestCommonAncestorBetweenView:view andView:self];
}

+ (UIView *)_lowestCommonAncestorBetweenView:(UIView *)view1 andView:(UIView *)view2 {
    NSArray *chain1 = [self _ancestryChainOfView:view1];
    NSArray *chain2 = [self _ancestryChainOfView:view2];
    
    if (!(chain1.count >= 1)) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"view1 has no ancestors" userInfo:nil];
    if (!(chain2.count >= 1)) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"view2 has no ancestors" userInfo:nil];
    
    NSArray *shorterArray = chain1.count <= chain2.count ? chain1 : chain2;
    NSArray *longerArray = chain1.count <= chain2.count ? chain2 : chain1;
    
    NSInteger lastCommonInShort = NSNotFound;
    NSInteger shorterIndex = shorterArray.count - 1;
    NSInteger longerIndex = longerArray.count - 1;
    
    while (shorterIndex >= 0) {
        if (shorterArray[shorterIndex] == longerArray[longerIndex]) {
            lastCommonInShort = shorterIndex;
        }
        else {
            break;
        }
        
        shorterIndex--;
        longerIndex--;
    }
    
    if (lastCommonInShort != NSNotFound) {
        return shorterArray[lastCommonInShort];
    }
    else {
        return nil;
    }
}

- (NSArray *)_ancestryChainUpToAndExcluding:(UIView *)ancestor {
    NSArray *ancestryChain = [self _ancestryChain];
    NSMutableArray *prunedAncestryChain = [NSMutableArray new];
    
    for (UIView *view in ancestryChain) {
        if (view != ancestor) {
            [prunedAncestryChain addObject:view];
        }
        else {
            break;
        }
    }
    
    return [prunedAncestryChain copy];
}

- (NSArray *)_ancestryChain {
    return [self.class _ancestryChainOfView:self];
}

+ (NSArray *)_ancestryChainOfView:(UIView *)view {
    if (!view) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"view must not be nil" userInfo:nil];
    
    NSMutableArray *ancestryChain = [NSMutableArray new];
    
    //add ourselves in on first spot
    [ancestryChain addObject:view];
    
    //traverse up until we reach the end of the chain
    UIView *head = view.superview;
    while (head) {
        [ancestryChain addObject:head];
        head = head.superview;
    }
    
    return ancestryChain;
}

- (BOOL)_isParentOfView:(UIView *)view {
    return [self.class _isViewParent:self ofView:view];
}

+ (BOOL)_isViewParent:(UIView *)parentView ofView:(UIView *)childView {
    // fail scenario
    if (!parentView) {
        return NO;
    }
    // fail scenario
    else if (!childView) {
        return NO;
    }
    // exhausted search
    else if (!childView.superview) {
        return NO;
    }
    // parentView is superview of childView
    else if (childView.superview == parentView) {
        return YES;
    }
    // recurse
    else {
        return [self _isViewParent:parentView ofView:childView.superview];
    }
}

@end

