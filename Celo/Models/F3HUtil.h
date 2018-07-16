//
//  F3HUtil.h
//  Celo
//
//  Created by Santanu Karar on 14/05/18.
//  Copyright © 2018 Santanu Karar. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface F3HUtil : NSObject

+ (void)attachGameController:(UIViewController *)view;
+ (void)addRemoveGestureControls:(BOOL)isRemove;
+ (void)attachCeloHelpController:(UIViewController *)view;

@end
