//
//  BookmarksFormController.h
//
//  Created by Alexandru Catighera on 6/14/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface BookmarksFormController : UIViewController {
	IBOutlet UIButton *parentField;
	IBOutlet UITextField *nameField;
	IBOutlet UITextField *urlField;
	UIBarButtonItem *cancelButton;
	UIBarButtonItem *doneButton;
	
	NSManagedObject *selectedFolder;
    
    NSString *defaultUrlFieldText;
	
	char mode;
	
	NSManagedObjectContext *managedObjectContext;
}
@property(nonatomic, strong) UIButton *parentField;
@property(nonatomic, strong) UITextField *nameField;
@property(nonatomic, strong) UITextField *urlField;
@property(nonatomic, strong) UIBarButtonItem *cancelButton;
@property(nonatomic, strong) UIBarButtonItem *doneButton;

@property(nonatomic, strong) NSManagedObject *selectedFolder;

@property(nonatomic,strong) NSString *defaultUrlFieldText;

@property(nonatomic, assign) char mode;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;

-(IBAction) switchToBrowser:(id)sender;
-(IBAction) folderSelect:(id)sender;
-(IBAction) saveBookmark:(id)sender;

@end
