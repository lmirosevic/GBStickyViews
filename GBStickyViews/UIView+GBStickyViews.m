//
//  UIView+GBStickyViews.m
//  GBStickyViews
//
//  Created by Luka Mirosevic on 31/01/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import "UIView+GBStickyViews.h"

@implementation UIView (GBStickyViews)

-(void)attachToView:(UIView *)masterView masterAnchor:(GBStickyViewsAnchor)masterAnchor slaveAnchor:(GBStickyViewsAnchor)slaveAnchor track:(BOOL)shouldTrack {
    // ensure that we are not a parent of the masterView
    if ([self _isParentOfView:masterView]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Tried to attach a view to a master view when the master view was a child view." userInfo:nil];
}

#pragma mark - util

-(UIView *)_lowestCommonAncestorWithView:(UIView *)view {
    return [self.class _lowestCommonAncestorBetweenView:view andView:self];
}

+(UIView *)_lowestCommonAncestorBetweenView:(UIView *)view1 andView:(UIView *)view2 {
    NSArray *chain1 = [self _ancestryChainOfView:view1];
    NSArray *chain2 = [self _ancestryChainOfView:view2];
    
    if (!(chain1.count >= 1)) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"view1 has no ancestors" userInfo:nil];
    if (!(chain2.count >= 1)) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"view2 has no ancestors" userInfo:nil];
    
    NSArray *shorterArray = chain1.count <= chain2.count ? chain1 : chain2;
    NSArray *longerArray = chain1.count <= chain2.count ? chain2 : chain1;
    
    NSInteger lastCommon;
    for (NSInteger i=shorterArray.count-1; i>=0; i--) {
        if (shorterArray[i] == longerArray[i]) {
            lastCommon = i;
        }
        else {
            break;
        }
    }
    
    return shorterArray[lastCommon];
}

+(NSArray *)_ancestryChainOfView:(UIView *)view {
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

-(BOOL)_isParentOfView:(UIView *)view {
    return [self.class _isViewParent:self ofView:view];
}

+(BOOL)_isViewParent:(UIView *)parentView ofView:(UIView *)childView {
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
