//
//  AppDelegate.h
//  TestBrowser
//
//  Created by Alexandru Catighera on 3/14/13.
//  Copyright (c) 2013 Alexandru Catighera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class BrowserViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
@private
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) BrowserViewController *viewController;

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end