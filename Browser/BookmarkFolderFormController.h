//
//  BookmarkFolderFormController.h
//
//  Created by Alexandru Catighera on 8/10/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BookmarksController;

@interface BookmarkFolderFormController : UIViewController {
	BookmarksController *bookmarksController;
	
	IBOutlet UITextField *nameField;
    
    NSInteger folderIndex;
	
	char mode;
}
@property(nonatomic,strong) BookmarksController *bookmarksController;

@property(nonatomic,strong) UITextField *nameField;

@property(nonatomic,assign) NSInteger folderIndex;

@property(nonatomic,assign) char mode;

-(IBAction) saveFolder:(id)sender;

@end
