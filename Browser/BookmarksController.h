//
//  BookmarksController.h
//
//  Created by Alexandru Catighera on 6/14/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import <UIKit/UIKit.h>

#define FOLDERS_KEY @"BookmarksFolders"
#define BOOKMARKS_ROOT -1
#define MAX_BOOKMARKS 1000

@class BookmarksFormController;
@class BookmarkFolderFormController;
@class BrowserViewController;
@class BookmarkItem;

@interface BookmarksController : UIViewController {
	BrowserViewController *browserController;
	BookmarksFormController *formController;
	BookmarkFolderFormController *folderController;

	char mode;
    NSInteger folderIndex;
    NSInteger bookmarkIndex;
	
	NSMutableArray *bookmarks;
    NSMutableArray *folders;
	
	IBOutlet UITableView *tableView;
	
	UIImage *bookmarkImage;
	UIImage *folderImage;
	IBOutlet UIToolbar *toolbar;
	IBOutlet UIToolbar *editToolbar;
}

@property(nonatomic, strong) BrowserViewController *browserController;
@property(nonatomic, strong) BookmarksFormController *formController;
@property(nonatomic, strong) BookmarkFolderFormController *folderController;

@property(nonatomic, assign) char mode;
@property(nonatomic, assign) NSInteger folderIndex;
@property(nonatomic, assign) NSInteger bookmarkIndex;

@property(nonatomic, strong) NSMutableArray *bookmarks;
@property(nonatomic, strong) NSMutableArray *folders;

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) UIImage *bookmarkImage;
@property(nonatomic, strong) UIImage *folderImage;
@property(nonatomic, strong) UIToolbar *toolbar;
@property(nonatomic, strong) UIToolbar *editToolbar;

-(IBAction) switchToBrowser:(id)sender;
-(IBAction) enableEditMode:(id)sender;
-(IBAction) finishEditMode:(id)sender;
-(IBAction) addFolder:(id)sender;

-(void)reloadData;
-(void) openBookmark:(NSIndexPath *) indexPath;

@end
