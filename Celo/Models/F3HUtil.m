//
//  F3HUtil.m
//  Celo
//
//  Created by Santanu Karar on 14/05/18.
//  Copyright © 2018 Santanu Karar. All rights reserved.
//

#import "F3HUtil.h"
#import "F3HNumberTileGameViewController.h"

@implementation F3HUtil

static F3HNumberTileGameViewController *gameView;

+ (void)attachGameController:(UIViewController *)view
{
    F3HNumberTileGameViewController *c = [F3HNumberTileGameViewController numberTileGameWithDimension:4
                                                                                         winThreshold:2048
                                                                                      backgroundColor:[UIColor whiteColor]
                                                                                          scoreModule:YES
                                                                                       buttonControls:NO
                                                                                        swipeControls:YES];
    [view addChildViewController:c];
    [view.view addSubview:c.view];
    [c didMoveToParentViewController:view];
    
    // configure the view
    c.view.translatesAutoresizingMaskIntoConstraints = NO;
    [c.view.topAnchor constraintEqualToAnchor:view.view.topAnchor].active = YES;
    [c.view.leftAnchor constraintEqualToAnchor:view.view.leftAnchor].active = YES;
    [c.view.widthAnchor constraintEqualToAnchor:view.view.widthAnchor].active = YES;
    [c.view.heightAnchor constraintEqualToAnchor:view.view.heightAnchor].active = YES;
    //c.view.backgroundColor = [UIColor colorWithRed:0.8685249686 green:0.7908762693 blue:0.7333008647 alpha:1];
    
    gameView = c;
}

+ (void)addRemoveGestureControls:(BOOL)isRemove
{
    [gameView addRemoveSwipeControls:isRemove];
}

+ (void)attachCeloHelpController:(UIViewController *)view
{
    [gameView addChildViewController:view];
    [gameView.view addSubview:view.view];
    [view didMoveToParentViewController:gameView];
}

@end
