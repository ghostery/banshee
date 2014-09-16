//
//  BookmarkFolderFormController.m
//
//  Created by Alexandru Catighera on 8/10/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "BookmarkFolderFormController.h"
#import "BookmarksController.h"
#import "BookmarksFormController.h"
#import "BrowserViewController.h"

@implementation BookmarkFolderFormController

@synthesize nameField, folderIndex, mode, bookmarksController;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	if (!mode) {
		mode = 'A';
	}
	
	[nameField becomeFirstResponder];
	
    if ([self respondsToSelector:@selector(setPreferredContentSize:)]) {
        self.preferredContentSize = CGSizeMake(320.0, 480.0);
    } else {
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    }
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    //Set the folder index to the bookmarkcontroller folder index
    self.folderIndex = bookmarksController.folderIndex;
    //Reset the folder index back to the bookmarks root, since we're navigating back to the folder root
    bookmarksController.folderIndex = BOOKMARKS_ROOT;
    //Disable edit mode in the bookmarks controller
    [bookmarksController finishEditMode:self];
	if (mode == 'A') {
		self.navigationItem.title = @"New Bookmark Folder";
		[nameField setText:@""];
	} else if (mode == 'E') {
		self.navigationItem.title = @"Edit Bookmark Folder";
        NSDictionary* folderDict = (NSDictionary*)[bookmarksController.folders objectAtIndex:self.folderIndex];
        NSString* folderTitle = (NSString*)[folderDict objectForKey:@"title"];
        [nameField setText:folderTitle];
	}
}

- (IBAction)saveFolder:(id)sender {
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* foldersArray = (NSMutableArray*)[[defaults objectForKey:FOLDERS_KEY] mutableCopy];
    NSMutableDictionary* folderDict = nil;
    
    if([[nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] length] == 0)
    {
        [nameField setText:@"New Folder"];
    }
    
	if (mode == 'A') {
        // check for parent folder
            NSMutableArray* bookmarksArray = [[NSMutableArray alloc] init];
            folderDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:nameField.text,@"title",bookmarksArray,@"bookmarks", nil];
            [foldersArray addObject:folderDict];
	} else if (mode == 'E') {
        folderDict = (NSMutableDictionary*)[[bookmarksController.folders objectAtIndex:self.folderIndex] mutableCopy];
        [folderDict setObject:nameField.text forKey:@"title"];
        [foldersArray setObject:folderDict atIndexedSubscript:self.folderIndex];
        self.folderIndex = [foldersArray count] - 1;
	}
    
    [defaults setObject:foldersArray forKey:FOLDERS_KEY];
    [defaults synchronize];
    
    //Reset the folder index back to the bookmarks root, since we're navigating back to the folder root
    bookmarksController.folderIndex = BOOKMARKS_ROOT;
	//Reload all bC controllers on the navigation stack
    BookmarksFormController *formController;
    for (UIViewController* bC in self.navigationController.viewControllers)
    {
        if([bC isKindOfClass:[BookmarksController class]])
        {
            [(BookmarksController *) bC setFolderIndex:folderIndex];
            [(BookmarksController *) bC loadBookmarks];
            [((BookmarksController *) bC).tableView reloadData];
        }
    }
    
    [self.navigationController popViewControllerAnimated:YES];
    [[[self.navigationController viewControllers] lastObject] setMode:'P'];

}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}




@end
