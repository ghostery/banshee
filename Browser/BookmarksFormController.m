    //
//  BookmarksFormController.m
//
//  Created by Alexandru Catighera on 6/14/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "BookmarksController.h"
#import "BookmarksFormController.h"
#import "BrowserViewController.h"

@class BrowserViewController;
@class BookmarksController;

@implementation BookmarksFormController

@synthesize parentField, nameField, urlField, arrowLabel, cancelButton, doneButton, mode, defaultUrlFieldText, browserController;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	if (!mode) {
		mode = 'A';
	}
	
	doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveBookmark:)];
	cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(switchToBrowser:)];
	
	if ([self respondsToSelector:@selector(setPreferredContentSize:)]) {
        self.preferredContentSize = CGSizeMake(320.0, 480.0);
    } else {
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    }
	[super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated {
	NSArray *vControllers = [self.navigationController viewControllers];
	BookmarksController *bookmarksController = [vControllers objectAtIndex:([vControllers count] - 2)];
    
    //Edit mode
	if (mode == 'E') {
		// adjust nav
		self.navigationItem.title = @"Edit Bookmark";
		[self.navigationItem setRightBarButtonItem:doneButton];
		[self.navigationItem setLeftBarButtonItem:nil];
		
		// load name and url
        [bookmarksController loadBookmarks];
        [urlField setText:[[bookmarksController.bookmarks objectAtIndex:bookmarksController.bookmarkIndex] valueForKey:@"URL"]];
		[nameField setText:[[bookmarksController.bookmarks objectAtIndex:bookmarksController.bookmarkIndex] valueForKey:@"title"]];
        [parentField setHidden:YES];
        [arrowLabel setHidden:YES];
		
	} else if (mode == 'A') { //Add Bookmark mode
		// adjust nav
		self.navigationItem.title = @"Add Bookmark";
		[self.navigationItem setRightBarButtonItem:doneButton];
		[self.navigationItem setLeftBarButtonItem:cancelButton];
        [parentField setHidden:NO];
        [arrowLabel setHidden:NO];
		
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

    if (bookmarksController.folders != nil && [bookmarksController.folders count] > 0) {
        NSDictionary* folderDict = nil;
        NSString* title;
        
        if(bookmarksController.folderIndex != BOOKMARKS_ROOT)
        {
            folderDict = [bookmarksController.folders objectAtIndex:bookmarksController.folderIndex];
            title = [folderDict objectForKey:@"title"];
        }
        else
        {
            folderDict = [bookmarksController.folders objectAtIndex:0];
            title = [folderDict objectForKey:@"title"];
        }
        
        [parentField setTitle:title forState:UIControlStateNormal];
        [parentField setTitle:title forState:UIControlStateSelected];
        [parentField setTitle:title forState:UIControlStateHighlighted];
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
    return UIInterfaceOrientationPortrait;
}

- (IBAction) switchToBrowser:(id)sender {
	[[[self.navigationController viewControllers] objectAtIndex:0] switchToBrowser:sender];
}

- (IBAction) folderSelect:(id)sender {
    NSArray *vControllers = [self.navigationController viewControllers];
	BookmarksController *bookmarksController = [vControllers objectAtIndex:([vControllers count] - 2)];
    
	BookmarksController *nextBookmarkController = [[BookmarksController alloc] init];
    [[NSBundle mainBundle] loadNibNamed:@"Bookmarks" owner:nextBookmarkController options:nil];
    [nextBookmarkController setBrowserController:self.browserController];
    [nextBookmarkController setMode:'P'];
    [nextBookmarkController setFolderController:[bookmarksController folderController]];
    [nextBookmarkController setFolderIndex:BOOKMARKS_ROOT];
	[self.navigationController pushViewController:nextBookmarkController animated:YES];
}

- (IBAction) saveBookmark:(id)sender {
    
    NSArray *vControllers = [self.navigationController viewControllers];
	BookmarksController *bookmarksController = [vControllers objectAtIndex:([vControllers count] - 2)];
    
    //New Code to save bookmark - NSUserDefaults
    
    //Load the Folders dictionary from the key in user defaults storage.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* foldersArray = [[defaults objectForKey:FOLDERS_KEY] mutableCopy];
    
    //Create a bookmarks Dictionary
    NSMutableDictionary* bookmarkDict = [[NSMutableDictionary alloc] init];
    [bookmarkDict setObject:nameField.text forKey:@"title"];
    [bookmarkDict setObject:[urlField.text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding] forKey:@"URL"];
    
    //Loop to check if the bookmarks have reached the max capacity and check if the bookmark exists
    NSUInteger totalBookmarks = 0;
    if(self.mode != 'E')
    {
        for (NSDictionary* folderDict in foldersArray)
        {
            //increment bookmarks counter
            NSArray* bookmarkArray = (NSArray*)[folderDict objectForKey:@"bookmarks"];
            totalBookmarks += [bookmarkArray count];
            
            //Return after proper alert message if the bookmark exists
            for (NSDictionary* bookmarkDict in bookmarkArray)
            {
                if([[urlField.text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]
                    isEqualToString:[bookmarkDict objectForKey:@"URL"]])
                {
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Duplicate Bookmark"
                                                                    message:[NSString stringWithFormat:@"This is in bookmark from folder  \"%@\"",[folderDict objectForKey:@"title"]]
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                    [alert show];
                    return;
                }
            }
        }
    }
    
    //Show alert if at max capacity and return
    if(totalBookmarks >= MAX_BOOKMARKS)
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Unable to Add Bookmark"
                                                        message:@"Bookmarks have reached max. capacity"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    //Add the bookmark dictionary to the current folder's bookmark array
    if(bookmarksController.folderIndex == BOOKMARKS_ROOT) bookmarksController.folderIndex = 0;
    NSMutableDictionary* folderDict = (NSMutableDictionary*)[[foldersArray objectAtIndex:bookmarksController.folderIndex] mutableCopy];
    NSMutableArray* bookmarksArray = [[folderDict objectForKey:@"bookmarks"] mutableCopy];
    if(self.mode == 'E')
    {
        [bookmarksArray setObject:bookmarkDict atIndexedSubscript:bookmarksController.bookmarkIndex];
    }
    else
    {
        [bookmarksArray addObject:bookmarkDict];
    }
    [folderDict setObject:bookmarksArray forKey:@"bookmarks"];
    [foldersArray setObject:folderDict atIndexedSubscript:bookmarksController.folderIndex];
    
    //Save the bookmark into the correct folder
    [defaults setObject:foldersArray forKey:FOLDERS_KEY];
    [defaults synchronize];
    
	//Reload all bC controllers on the navigation stack
    for (BookmarksController* bC in self.navigationController.viewControllers)
    {
        if([bC isKindOfClass:[BookmarksController class]])
        {
            [bC loadBookmarks];
            [bC.tableView reloadData];
        }
    }
    
    if(self.mode == 'A')
    {
        [bookmarksController switchToBrowser:sender];
    }
    else
    {
        self.mode = 'B';
        [self.navigationController popViewControllerAnimated:YES];
    }
    
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
