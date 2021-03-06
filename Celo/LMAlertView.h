//
//  LMAlertView.h
//  LMAlertViewDemo
//
//  Created by Lee McDermott on 11/11/2013.
//  Copyright (c) 2013 Bestir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMModalItemTableViewCell.h"

@interface LMAlertView : UIView <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic) BOOL keepTopAlignment;
@property (unsafe_unretained) id<UIAlertViewDelegate> delegate;

@property(nonatomic) NSInteger cancelButtonIndex;
@property(nonatomic, readonly) NSInteger firstOtherButtonIndex;
@property(nonatomic, copy) NSString *message;
@property(nonatomic, readonly) NSInteger numberOfButtons;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, readonly, getter=isVisible) BOOL visible;
@property(nonatomic) BOOL buttonsShouldStack;
@property(nonatomic) BOOL autoRotate;

- (id)initWithSize:(CGSize)size;
- (id)initWithViewController:(UIViewController *)viewController;
- (id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

- (void)setSize:(CGSize)size animated:(BOOL)animated;
- (void)setSize:(CGSize)size;
- (CGSize)size;

- (void)show;
- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated;
- (NSInteger)addButtonWithTitle:(NSString *)title;
- (NSString *)buttonTitleAtIndex:(NSInteger)buttonIndex;

- (LMModalItemTableViewCell *)buttonCellForIndex:(NSInteger)buttonIndex;

@end