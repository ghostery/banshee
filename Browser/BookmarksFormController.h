//
//  BookmarksFormController.h
//
//  Created by Alexandru Catighera on 6/14/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BrowserViewController;

@interface BookmarksFormController : UIViewController {
    BrowserViewController *browserController;
	IBOutlet UIButton *parentField;
	IBOutlet UITextField *nameField;
	IBOutlet UITextField *urlField;
    IBOutlet UILabel *arrowLabel;
	UIBarButtonItem *cancelButton;
	UIBarButtonItem *doneButton;
    NSString *defaultUrlFieldText;
	char mode;
}

@property(nonatomic, strong) BrowserViewController *browserController;
@property(nonatomic, strong) UIButton *parentField;
@property(nonatomic, strong) UITextField *nameField;
@property(nonatomic, strong) UITextField *urlField;
@property(nonatomic, strong) IBOutlet UILabel *arrowLabel;
@property(nonatomic, strong) UIBarButtonItem *cancelButton;
@property(nonatomic, strong) UIBarButtonItem *doneButton;
@property(nonatomic,strong) NSString *defaultUrlFieldText;
@property(nonatomic, assign) char mode;


-(IBAction) switchToBrowser:(id)sender;
-(IBAction) folderSelect:(id)sender;
-(IBAction) saveBookmark:(id)sender;

@end
