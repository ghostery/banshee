//
//  UIStatusBarView.h
//
//  Created by Alexandru Catighera on 10/17/13.
//
//

#import <UIKit/UIKit.h>
@class BrowserViewController;

@interface UIMainView : UIView

@property(nonatomic, strong) IBOutlet UIView *statusBarView;
@property(nonatomic, strong) IBOutlet BrowserViewController *controller;
@property(nonatomic, strong) IBOutlet NSLayoutConstraint *statusViewHeightConstraint;

- (void) sizeStatusBar;

@end
