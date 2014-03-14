//
//  BookmarkFolderFormController.m
//
//  Created by Alexandru Catighera on 8/10/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "BookmarkFolderFormController.h"
#import "BookmarksController.h"
#import "BrowserDelegate.h"

@implementation BookmarkFolderFormController

@synthesize nameField, folder, managedObjectContext, mode, bookmarksController;

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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	//set up DB
	if (managedObjectContext == nil) 
	{ 
        managedObjectContext = [(BrowserDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSLog(@"After managedObjectContext: %@",  managedObjectContext);
	}
	
	if (!mode) {
		mode = 'A';
	}
	
	[nameField becomeFirstResponder];
	
	self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	if (mode == 'A') {
		folder = nil;
		self.navigationItem.title = @"New Bookmark Folder";
		[nameField setText:@""];
	} else if (mode == 'E') {
		self.navigationItem.title = @"Edit Bookmark Folder";
		[nameField setText:[folder valueForKey:@"name"]];
	}
}

- (IBAction)saveFolder:(id)sender {
    NSArray *controllers = [self.navigationController viewControllers];
	BookmarksController *newBookmarksController = (BookmarksController *)[controllers objectAtIndex:[controllers count] - 2];
	if (mode == 'A') {
		folder = [NSEntityDescription insertNewObjectForEntityForName:@"Folder" inManagedObjectContext:managedObjectContext];
        // check for parent folder
        if ([controllers count] > 2) {
            BookmarksController *parentBookmarksController = (BookmarksController *)[controllers objectAtIndex:[controllers count] - 3];
            NSMutableArray *folders = (NSMutableArray *)[parentBookmarksController bookmarks];
            NSIndexPath *selectedIndexPath = [[parentBookmarksController tableView] indexPathForSelectedRow];
            NSManagedObject *parentFolder = [folders objectAtIndex:[selectedIndexPath row]];
            [folder setValue:parentFolder forKey:@"Parent"];
        }
	} else if (mode == 'E') {
		NSMutableArray *folders = (NSMutableArray *)[newBookmarksController bookmarks];
		NSIndexPath *selectedIndexPath = [[newBookmarksController tableView] indexPathForSelectedRow];
		folder = [folders objectAtIndex:[selectedIndexPath row]];
	}
	
	[folder setValue:nameField.text forKey:@"name"];
	
	[managedObjectContext save:nil];
	
	[bookmarksController reloadBookmarks];
	[[bookmarksController tableView] reloadData];
	[self.navigationController popViewControllerAnimated:YES];
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
