//
//  GBStickyViewsTests.m
//  GBStickyViewsTests
//
//  Created by Luka Mirosevic on 31/01/2014.
//  Copyright (c) 2014 Goonbee. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "GBStickyViews.h"

@interface UIView (Tests)

+(BOOL)_isViewParent:(UIView *)parentView ofView:(UIView *)childView;
+(UIView *)_lowestCommonAncestorBetweenView:(UIView *)view1 andView:(UIView *)view2;

@end

@interface GBStickyViewsTests : XCTestCase

@end

@implementation GBStickyViewsTests {
    UIView *r;
    UIView *r1;
    UIView *r2;
    UIView *r21;
    UIView *r22;
    UIView *r221;
}

-(void)setUp {
    [super setUp];
    
    // set up a view hierarchy
    r = [UIView new];
    r1 = [UIView new];
    r2 = [UIView new];
    r21 = [UIView new];
    r22 = [UIView new];
    r221 = [UIView new];
    [r addSubview:r1];
    [r addSubview:r2];
    [r2 addSubview:r21];
    [r2 addSubview:r22];
    [r22 addSubview:r221];
}

-(void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testParentChecking {
    UIView *parent, *child;
    
    parent = r;
    child = r221;
    XCTAssertTrue([UIView _isViewParent:parent ofView:child], @"parent is root, child is somehwere down there");
    
    parent = r1;
    child = r2;
    XCTAssertFalse([UIView _isViewParent:parent ofView:child], @"parent is sibling to child");
    
    parent = r1;
    child = r21;
    XCTAssertFalse([UIView _isViewParent:parent ofView:child], @"parent superview is in child's superview chain, but is not a parent");
    
    parent = r;
    child = nil;
    XCTAssertFalse([UIView _isViewParent:parent ofView:child], @"child is nil");
    
    parent = nil;
    child = r1;
    XCTAssertFalse([UIView _isViewParent:parent ofView:child], @"parent is nil");
}

-(void)testAncestryChecking {
    XCTAssertEqualObjects([UIView _lowestCommonAncestorBetweenView:r221 andView:r21], r2, @"check1");
}

@end
