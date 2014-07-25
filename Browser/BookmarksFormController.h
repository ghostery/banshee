//
//  BookmarksFormController.h
//
//  Created by Alexandru Catighera on 6/14/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import <UIKit/UIKit.h>
//Core Data Fix
//#import <CoreData/CoreData.h>

@interface BookmarksFormController : UIViewController {
	IBOutlet UIButton *parentField;
	IBOutlet UITextField *nameField;
	IBOutlet UITextField *urlField;
    IBOutlet UILabel *arrowLabel;
	UIBarButtonItem *cancelButton;
	UIBarButtonItem *doneButton;
	
    //Core Data Fix
	//NSManagedObject *selectedFolder;
    //NSManagedObjectContext *managedObjectContext;
    
    NSString *defaultUrlFieldText;
	
	char mode;
	
}
@property(nonatomic, strong) UIButton *parentField;
@property(nonatomic, strong) UITextField *nameField;
@property(nonatomic, strong) UITextField *urlField;
@property(nonatomic, strong) IBOutlet UILabel *arrowLabel;
@property(nonatomic, strong) UIBarButtonItem *cancelButton;
@property(nonatomic, strong) UIBarButtonItem *doneButton;

//Core Data Fix
//@property(nonatomic, strong) NSManagedObject *selectedFolder;
//@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property(nonatomic,strong) NSString *defaultUrlFieldText;

@property(nonatomic, assign) char mode;


-(IBAction) switchToBrowser:(id)sender;
-(IBAction) folderSelect:(id)sender;
-(IBAction) saveBookmark:(id)sender;

@end
