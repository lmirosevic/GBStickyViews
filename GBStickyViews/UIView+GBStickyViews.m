//
//  UIView+GBStickyViews.m
//  GBStickyViews
//
//  Created by Luka Mirosevic on 31/01/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import "UIView+GBStickyViews.h"

#import <GBToolbox/GBToolbox.h>

@interface UIView ()

@property (strong, nonatomic) UIView                    *GBMasterView;
@property (assign, nonatomic) CGPoint                   GBOffset;
@property (assign, nonatomic) GBStickyViewsAnchor       GBMasterAnchor;
@property (assign, nonatomic) GBStickyViewsAnchor       GBSlaveAnchor;
@property (strong, nonatomic) NSArray                   *GBObservedViews;

@end

@implementation UIView (GBStickyViews)

#pragma mark - Memory

_associatedObject(strong, nonatomic, UIView *, GBMasterView, setGBMasterView)
_associatedObject(strong, nonatomic, NSValue *, GBOffsetValue, setGBOffsetValue)
_associatedObject(strong, nonatomic, NSNumber *, GBMasterAnchorNumber, setGBMasterAnchorNumber)
_associatedObject(strong, nonatomic, NSNumber *, GBSlaveAnchorNumber, setGBSlaveAnchorNumber)
_associatedObject(strong, nonatomic, NSArray *, GBObservedViews, setGBObservedViews)

-(CGPoint)GBOffset {
    return [[self GBOffsetValue] CGPointValue];
}
-(void)setGBOffset:(CGPoint)offset {
    [self setGBOffsetValue:[NSValue valueWithCGPoint:offset]];
}

-(GBStickyViewsAnchor)GBMasterAnchor {
    return (GBStickyViewsAnchor)[[self GBMasterAnchorNumber] intValue];
}
-(void)setGBMasterAnchor:(GBStickyViewsAnchor)masterAnchor {
    [self setGBMasterAnchorNumber:[NSNumber numberWithInt:masterAnchor]];
}

-(GBStickyViewsAnchor)GBSlaveAnchor {
    return (GBStickyViewsAnchor)[[self GBSlaveAnchorNumber] intValue];
}
-(void)setGBSlaveAnchor:(GBStickyViewsAnchor)slaveAnchor {
    [self setGBSlaveAnchorNumber:[NSNumber numberWithInt:slaveAnchor]];
}

#pragma mark - API

-(void)attachToView:(UIView *)masterView masterAnchor:(GBStickyViewsAnchor)masterAnchor slaveAnchor:(GBStickyViewsAnchor)slaveAnchor offset:(CGPoint)offset track:(BOOL)shouldTrack {
    //ensure we're attached to some view
    if (!self.superview) @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Must first add this view to a superview, and then call attachToView:masterAnchor:slaveAnchor:offset:track:" userInfo:nil];
    
    //ensure masterView is not nil
    if (!masterView) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"masterView must not be nil" userInfo:nil];
    
    //ensure master is attached to some view
    if (!masterView.superview) @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Must first add the masterView to a superview, and then call attachToView:masterAnchor:slaveAnchor:offset:track:" userInfo:nil];
    
    //ensure that we are not a parent of the masterView
    if ([self _isParentOfView:masterView]) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Tried to attach a view to a master view when the master view was a child view." userInfo:nil];
    
    //find the view which is the base common coordinate system
    UIView *lowestCommonAncestor = [self.class _lowestCommonAncestorBetweenView:self andView:masterView];
    
    //get the list of views whose change in position would affect it's relative position to self in the ancestry chain between [master, LCA[
    NSArray *volatileMasterChain = [masterView _ancestryChainUpToAndExcluding:lowestCommonAncestor];
    
    //get the list of views whose change in position would affect it's relative position to masterView in the ancestry chain between ]self, LCA[
    NSMutableArray *volatileSelfChain = [[self _ancestryChainUpToAndExcluding:lowestCommonAncestor] mutableCopy];
    [volatileSelfChain removeObjectAtIndex:0];//remove self
    
    //combine this list of views
    NSArray *volatileViews = [volatileMasterChain arrayByAddingObjectsFromArray:volatileSelfChain];
 
    //store all our properties
    self.GBMasterView = masterView;
    self.GBOffset = offset;
    self.GBMasterAnchor = masterAnchor;
    self.GBSlaveAnchor = slaveAnchor;
    
    //clear out the old list of attached views if there were any
    [self _removeFrameChangedListenersFromViews:self.GBObservedViews];
    
    if (shouldTrack) {
        //attach to this list of views
        [self _attachFrameChangedListenersToViews:volatileViews];
        
        //remember this list of views for later
        self.GBObservedViews = volatileViews;
    }
    
    //trigger the first realignment
    [self _realignViewToMasterView:masterView];
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == FrameChangedContext) {
        [self _realignViewToMasterView:self.GBMasterView];
    }
}

#pragma mark - util

static void * const FrameChangedContext = (void *)&FrameChangedContext;

-(void)_attachFrameChangedListenersToViews:(NSArray *)views {
    for (UIView *view in views) {
        [self _attachFrameChangedListenerToView:view];
    }
}

-(void)_attachFrameChangedListenerToView:(UIView *)view {
    [view addObserver:self forKeyPath:@"frame" options:0 context:FrameChangedContext];
    [view.layer addObserver:self forKeyPath:@"bounds" options:0 context:FrameChangedContext];
    [view.layer addObserver:self forKeyPath:@"transform" options:0 context:FrameChangedContext];
    [view.layer addObserver:self forKeyPath:@"position" options:0 context:FrameChangedContext];
    [view.layer addObserver:self forKeyPath:@"zPosition" options:0 context:FrameChangedContext];
    [view.layer addObserver:self forKeyPath:@"anchorPoint" options:0 context:FrameChangedContext];
    [view.layer addObserver:self forKeyPath:@"anchorPointZ" options:0 context:FrameChangedContext];
    [view.layer addObserver:self forKeyPath:@"zPosition" options:0 context:FrameChangedContext];
    [view.layer addObserver:self forKeyPath:@"frame" options:0 context:FrameChangedContext];
    [view.layer addObserver:self forKeyPath:@"transform" options:0 context:FrameChangedContext];
}

-(void)_removeFrameChangedListenersFromViews:(NSArray *)views {
    for (UIView *view in views) {
        [self _removeFrameChangedListenerFromView:view];
    }
}

-(void)_removeFrameChangedListenerFromView:(UIView *)view {
    [view removeObserver:self forKeyPath:@"frame" context:FrameChangedContext];
    [view.layer removeObserver:self forKeyPath:@"bounds" context:FrameChangedContext];
    [view.layer removeObserver:self forKeyPath:@"transform" context:FrameChangedContext];
    [view.layer removeObserver:self forKeyPath:@"position" context:FrameChangedContext];
    [view.layer removeObserver:self forKeyPath:@"zPosition" context:FrameChangedContext];
    [view.layer removeObserver:self forKeyPath:@"anchorPoint" context:FrameChangedContext];
    [view.layer removeObserver:self forKeyPath:@"anchorPointZ" context:FrameChangedContext];
    [view.layer removeObserver:self forKeyPath:@"zPosition" context:FrameChangedContext];
    [view.layer removeObserver:self forKeyPath:@"frame" context:FrameChangedContext];
    [view.layer removeObserver:self forKeyPath:@"transform" context:FrameChangedContext];
}

-(void)_realignViewToMasterView:(UIView *)masterView {
    //convert masterView coordinates to screen coordinates
    CGRect masterFrame = [self.GBMasterView convertRect:self.GBMasterView.bounds toView:nil];
    
    //get own size
    CGSize selfSize = self.bounds.size;
    CGPoint offset = self.GBOffset;
    
    //calculate own coordinates in global space
    CGPoint selfCoordinatesInGlobalSpace;
    
    //move origin according to master anchor
    switch (self.GBMasterAnchor) {
        case GBStickyViewsAnchorLeftTop: {
            selfCoordinatesInGlobalSpace = CGPointMake(masterFrame.origin.x + masterFrame.size.width * 0,
                                                       masterFrame.origin.y + masterFrame.size.height * 0);
        } break;
            
        case GBStickyViewsAnchorCenterTop: {
            selfCoordinatesInGlobalSpace = CGPointMake(masterFrame.origin.x + masterFrame.size.width * 0.5,
                                                       masterFrame.origin.y + masterFrame.size.height * 0);
        } break;
            
        case GBStickyViewsAnchorRightTop: {
            selfCoordinatesInGlobalSpace = CGPointMake(masterFrame.origin.x + masterFrame.size.width * 1.,
                                                       masterFrame.origin.y + masterFrame.size.height * 0);
        } break;
            
        case GBStickyViewsAnchorLeftCenter: {
            selfCoordinatesInGlobalSpace = CGPointMake(masterFrame.origin.x + masterFrame.size.width * 0,
                                                       masterFrame.origin.y + masterFrame.size.height * 0.5);
        } break;
            
        case GBStickyViewsAnchorCenterCenter: {
            selfCoordinatesInGlobalSpace = CGPointMake(masterFrame.origin.x + masterFrame.size.width * 0.5,
                                                       masterFrame.origin.y + masterFrame.size.height * 0.5);
        } break;
            
        case GBStickyViewsAnchorRightCenter: {
            selfCoordinatesInGlobalSpace = CGPointMake(masterFrame.origin.x + masterFrame.size.width * 1.,
                                                       masterFrame.origin.y + masterFrame.size.height * 0.5);
        } break;
            
        case GBStickyViewsAnchorLeftBottom: {
            selfCoordinatesInGlobalSpace = CGPointMake(masterFrame.origin.x + masterFrame.size.width * 0,
                                                       masterFrame.origin.y + masterFrame.size.height * 1.);
        } break;
            
        case GBStickyViewsAnchorCenterBottom: {
            selfCoordinatesInGlobalSpace = CGPointMake(masterFrame.origin.x + masterFrame.size.width * 0.5,
                                                       masterFrame.origin.y + masterFrame.size.height * 1.);
        } break;
            
        case GBStickyViewsAnchorRightBottom: {
            selfCoordinatesInGlobalSpace = CGPointMake(masterFrame.origin.x + masterFrame.size.width * 1.,
                                                       masterFrame.origin.y + masterFrame.size.height * 1.);
        } break;
    }
    
    //move origin according to slave anchor
    switch (self.GBSlaveAnchor) {
        case GBStickyViewsAnchorLeftTop: {
            selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x - selfSize.width * 0,
                                                       selfCoordinatesInGlobalSpace.y - selfSize.height * 0);
        } break;
            
        case GBStickyViewsAnchorCenterTop: {
            selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x - selfSize.width * 0.5,
                                                       selfCoordinatesInGlobalSpace.y - selfSize.height * 0);
        } break;
            
        case GBStickyViewsAnchorRightTop: {
            selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x - selfSize.width * 1.,
                                                       selfCoordinatesInGlobalSpace.y - selfSize.height * 0);
        } break;
            
        case GBStickyViewsAnchorLeftCenter: {
            selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x - selfSize.width * 0,
                                                       selfCoordinatesInGlobalSpace.y - selfSize.height * 0.5);
        } break;
            
        case GBStickyViewsAnchorCenterCenter: {
            selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x - selfSize.width * 0.5,
                                                       selfCoordinatesInGlobalSpace.y - selfSize.height * 0.5);
        } break;
            
        case GBStickyViewsAnchorRightCenter: {
            selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x - selfSize.width * 1.,
                                                       selfCoordinatesInGlobalSpace.y - selfSize.height * 0.5);
        } break;
            
        case GBStickyViewsAnchorLeftBottom: {
            selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x - selfSize.width * 0,
                                                       selfCoordinatesInGlobalSpace.y - selfSize.height * 1.);
        } break;
            
        case GBStickyViewsAnchorCenterBottom: {
            selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x - selfSize.width * 0.5,
                                                       selfCoordinatesInGlobalSpace.y - selfSize.height * 1.);
        } break;
            
        case GBStickyViewsAnchorRightBottom: {
            selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x - selfSize.width * 1.,
                                                       selfCoordinatesInGlobalSpace.y - selfSize.height * 1.);
        } break;
    }
    
    //apply offset as a delta
    selfCoordinatesInGlobalSpace = CGPointMake(selfCoordinatesInGlobalSpace.x + offset.x,
                                   selfCoordinatesInGlobalSpace.y + offset.y);
    
    //convert own coordinates from global space to parent view space
    CGPoint selfCoordinatesInParentSpace = [self.superview convertPoint:selfCoordinatesInGlobalSpace fromView:nil];
    
    //calculate self frame
    CGRect selfFrame = CGRectMake(selfCoordinatesInParentSpace.x,
                                  selfCoordinatesInParentSpace.y,
                                  self.frame.size.width,
                                  self.frame.size.height);
    
    //move self
    self.frame = selfFrame;
}

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

-(NSArray *)_ancestryChainUpToAndExcluding:(UIView *)ancestor {
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

-(NSArray *)_ancestryChain {
    return [self.class _ancestryChainOfView:self];
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

//lm might be a good idea to detach the listeners when the view hierarchy of the observed views changes
