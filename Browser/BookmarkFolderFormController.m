//
//  BookmarkFolderFormController.m
//
//  Created by Alexandru Catighera on 8/10/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "BookmarkFolderFormController.h"
#import "BookmarksController.h"
#import "BrowserViewController.h"

@implementation BookmarkFolderFormController

//Core Data Fix
@synthesize nameField, /*folder, managedObjectContext,*/ mode, bookmarksController;

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

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
	if (mode == 'A') {
		self.navigationItem.title = @"New Bookmark Folder";
		[nameField setText:@""];
	} else if (mode == 'E') {
		self.navigationItem.title = @"Edit Bookmark Folder";
        NSDictionary* folderDict = (NSDictionary*)[bookmarksController.folders objectAtIndex:bookmarksController.folderIndex];
        NSString* folderTitle = (NSString*)[folderDict objectForKey:@"title"];
        [nameField setText:folderTitle];
	}
}

- (IBAction)saveFolder:(id)sender {
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* foldersArray = (NSMutableArray*)[[defaults objectForKey:FOLDERS_KEY] mutableCopy];
    NSArray *controllers = [self.navigationController viewControllers];
    NSMutableDictionary* folderDict = nil;
    
    if([[nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] length] == 0)
    {
        [nameField setText:@"New Folder"];
    }
    
	if (mode == 'A') {
        //Core Data Fix
		//folder = [NSEntityDescription insertNewObjectForEntityForName:@"Folder" inManagedObjectContext:managedObjectContext];
        // check for parent folder
            NSMutableArray* bookmarksArray = [[NSMutableArray alloc] init];
            folderDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:nameField.text,@"title",bookmarksArray,@"bookmarks", nil];
            [foldersArray addObject:folderDict];
            //Core Data Fix
            /*
            BookmarksController *parentBookmarksController = (BookmarksController *)[controllers objectAtIndex:[controllers count] - 3];
            NSMutableArray *folders = (NSMutableArray *)[parentBookmarksController bookmarks];
            NSIndexPath *selectedIndexPath = [[parentBookmarksController tableView] indexPathForSelectedRow];
            NSManagedObject *parentFolder = [folders objectAtIndex:[selectedIndexPath row]];
            [folder setValue:parentFolder forKey:@"Parent"];
            */
	} else if (mode == 'E') {
        folderDict = (NSMutableDictionary*)[[bookmarksController.folders objectAtIndex:bookmarksController.folderIndex] mutableCopy];
        [folderDict setObject:nameField.text forKey:@"title"];
        [foldersArray setObject:folderDict atIndexedSubscript:bookmarksController.folderIndex];
        //Core Data Fix
		//NSIndexPath *selectedIndexPath = [[newBookmarksController tableView] indexPathForSelectedRow];
		//folder = [folders objectAtIndex:[selectedIndexPath row]];
	}
    
    [defaults setObject:foldersArray forKey:FOLDERS_KEY];
    [defaults synchronize];
    
    //Core Data Fix
    /*
	[folder setValue:nameField.text forKey:@"name"];
	
	[managedObjectContext save:nil];
	*/
    
    //Reset the folder index back to the bookmarks root, since we're navigating back to the folder root
    bookmarksController.folderIndex = BOOKMARKS_ROOT;
	//Reload all bC controllers on the navigation stack
    for (BookmarksController* bC in self.navigationController.viewControllers)
    {
        if([bC isKindOfClass:[BookmarksController class]])
        {
            [bC reloadData];
            [bC.tableView reloadData];
        }
    }
	[self.navigationController popViewControllerAnimated:YES];
    [bookmarksController.browserController dismissPopups];
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
