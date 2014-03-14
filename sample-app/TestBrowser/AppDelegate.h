//
//  AppDelegate.h
//  TestBrowser
//
//  Created by Alexandru Catighera on 3/14/13.
//  Copyright (c) 2013 Alexandru Catighera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowserDelegate.h"

@class BrowserViewController;

@interface AppDelegate : BrowserDelegate <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) BrowserViewController *viewController;



@end