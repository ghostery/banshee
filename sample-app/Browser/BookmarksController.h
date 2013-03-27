//
//  BookmarksController.h
//
//  Created by Alexandru Catighera on 6/14/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class BookmarksFormController;
@class BookmarkFolderFormController;
@class BrowserViewController;
@class BookmarkItem;

@interface BookmarksController : UIViewController {
	BrowserViewController *browserController;
	BookmarksFormController *formController;
	BookmarkFolderFormController *folderController;
	
	NSManagedObjectContext *managedObjectContext;
	NSManagedObject *currentFolder;
	char mode;
	
	NSMutableArray *bookmarks;
	
	IBOutlet UITableView *tableView;
	
	UIImage *bookmarkImage;
	UIImage *folderImage;
	IBOutlet UIToolbar *toolbar;
	IBOutlet UIToolbar *editToolbar;
}

@property(nonatomic, strong) BrowserViewController *browserController;
@property(nonatomic, strong) BookmarksFormController *formController;
@property(nonatomic, strong) BookmarkFolderFormController *folderController;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSManagedObject *currentFolder;

@property(nonatomic, assign) char mode;

@property(nonatomic, strong) NSMutableArray *bookmarks;

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) UIImage *bookmarkImage;
@property(nonatomic, strong) UIImage *folderImage;
@property(nonatomic, strong) UIToolbar *toolbar;
@property(nonatomic, strong) UIToolbar *editToolbar;

-(IBAction) switchToBrowser:(id)sender;
-(IBAction) enableEditMode:(id)sender;
-(IBAction) finishEditMode:(id)sender;
-(IBAction) addFolder:(id)sender;

-(NSMutableArray *) reloadBookmarks;
-(void) openBookmark:(NSIndexPath *) indexPath;

@end
