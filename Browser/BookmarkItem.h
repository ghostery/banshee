//
//  BookmarkItem.h
//
//  Created by Alexandru Catighera on 6/17/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BookmarksController;

@interface BookmarkItem : UITableViewCell {
	BookmarksController *bookmarksController;
	
	UITableView *tableView;
	NSIndexPath *indexPath;
	
	IBOutlet UILabel *cellLabel;
	IBOutlet UIImageView *cellImage;
	
	IBOutlet UIButton *deleteCircle;
	IBOutlet UIButton *deleteConfirmation;
}
@property(nonatomic, strong) BookmarksController *bookmarksController;

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSIndexPath *indexPath;

@property(nonatomic, strong) UILabel *cellLabel;
@property(nonatomic, strong) UIImageView *cellImage;

@property(nonatomic, strong) UIButton *deleteCircle;
@property(nonatomic, strong) UIButton *deleteConfirmation;

-(void) enableEdit;
-(void) disableEdit;
-(void) enableDelete;
-(void) disableDelete;

-(IBAction) deleteCircleClick:(id)sender;
-(IBAction) deleteItem:(id)sender;

@end
