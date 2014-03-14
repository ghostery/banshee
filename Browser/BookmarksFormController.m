    //
//  BookmarksFormController.m
//
//  Created by Alexandru Catighera on 6/14/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "BookmarksController.h"
#import "BookmarksFormController.h"
#import "BrowserDelegate.h"
#import "BrowserViewController.h"

@class BrowserViewController;
@class BookmarksController;

@implementation BookmarksFormController

@synthesize parentField, nameField, urlField, cancelButton, doneButton, managedObjectContext, mode, selectedFolder, defaultUrlFieldText;

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
	//set up DB
	if (managedObjectContext == nil) 
	{ 
        managedObjectContext = [(BrowserDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSLog(@"After managedObjectContext: %@",  managedObjectContext);
	}
	
	if (!mode) {
		mode = 'A';
	}
	
	doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveBookmark:)];
	cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(switchToBrowser:)];
	
	self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
	[super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated {
	NSArray *vControllers = [self.navigationController viewControllers];
	BookmarksController *bookmarksController = [vControllers objectAtIndex:([vControllers count] - 2)];
	BrowserViewController *browserController = [bookmarksController browserController];

	if (mode == 'E') {
		// adjust nav
		self.navigationItem.title = @"Edit Bookmark";
		[self.navigationItem setRightBarButtonItem:doneButton];
		[self.navigationItem setLeftBarButtonItem:nil];
		
		// load name and url
        [bookmarksController reloadBookmarks];
		NSMutableArray *bookmarks = [bookmarksController bookmarks];
		NSIndexPath *selectedIndexPath = [[bookmarksController tableView] indexPathForSelectedRow];
		NSManagedObject *bookmark = [bookmarks objectAtIndex:[selectedIndexPath row]];
		[urlField setText:[bookmark valueForKey:@"url"]];
		[nameField setText:[bookmark valueForKey:@"name"]];
        if (selectedFolder == nil) {
            selectedFolder = [bookmark valueForKey:@"Folder"];
        }
        
		
	} else if (mode == 'A') {
		// adjust nav
		self.navigationItem.title = @"Add Bookmark";
		[self.navigationItem setRightBarButtonItem:doneButton];
		[self.navigationItem setLeftBarButtonItem:cancelButton];
		
        if (defaultUrlFieldText != nil) {
            [urlField setText:defaultUrlFieldText];
            [nameField setText:@"Untitled"];
            [self setDefaultUrlFieldText:nil];
        } else {
            NSString *name = [[browserController webView] stringByEvaluatingJavaScriptFromString:@"document.title"];
            NSString *url = [[browserController webView] stringByEvaluatingJavaScriptFromString:@"window.location.href"];
            if (![url isEqualToString:@"about:blank"]) {
                [urlField setText:url];
                [nameField setText:name];
            }
        }
		
	}
	if (selectedFolder != nil && ![selectedFolder isEqual:@"Bookmarks"]) {
		[parentField setTitle:[selectedFolder valueForKey:@"name"] forState:UIControlStateNormal];
	} else {
        [parentField setTitle:@"Bookmarks" forState:UIControlStateNormal];
    }
	[nameField becomeFirstResponder];
}

- (NSUInteger) supportedInterfaceOrientations {
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskPortrait;
    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    // Return the orientation you'd prefer - this is what it launches to. The
    // user can still rotate. You don't have to implement this method, in which
    // case it launches in the current orientation
    return UIDeviceOrientationPortrait;
}

- (IBAction) switchToBrowser:(id)sender {
	[[[self.navigationController viewControllers] objectAtIndex:0] switchToBrowser:sender];
}

- (IBAction) folderSelect:(id)sender {
	BookmarksController *nextBookmarkController = [[BookmarksController alloc] init];
    [[NSBundle mainBundle] loadNibNamed:@"Bookmarks" owner:nextBookmarkController options:nil];
	[nextBookmarkController setMode:'P'];
	[nextBookmarkController setManagedObjectContext:managedObjectContext];
	[self.navigationController pushViewController:nextBookmarkController animated:YES];
}

- (IBAction) saveBookmark:(id)sender {
	NSArray *vControllers = [self.navigationController viewControllers];
	BookmarksController *bookmarksController = [vControllers objectAtIndex:([vControllers count] - 2)];
	NSManagedObject *bookmark = nil;
	if (mode == 'A') {
		 bookmark = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:managedObjectContext];
	} else if (mode == 'E') {
		NSMutableArray *bookmarks = [bookmarksController bookmarks];
		NSIndexPath *selectedIndexPath = [[bookmarksController tableView] indexPathForSelectedRow];
		bookmark = [bookmarks objectAtIndex:[selectedIndexPath row]];
	}
	
	[bookmark setValue:nameField.text forKey:@"name"];
	[bookmark setValue:urlField.text forKey:@"url"];
	[bookmark setValue:([selectedFolder isEqual:@"Bookmarks"] ? nil : selectedFolder) forKey:@"Folder"];

	[managedObjectContext save:nil];

	[bookmarksController reloadBookmarks];
	[[bookmarksController tableView] reloadData];
	[bookmarksController switchToBrowser:sender];
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
