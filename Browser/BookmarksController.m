//
//  BookmarksController.m
//
//  Created by Alexandru Catighera on 6/14/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "Logging.h"
#import "BookmarksController.h"
#import "BrowserViewController.h"
#import	"BookmarkItem.h"
#import "BookmarksFormController.h"
#import "BookmarkFolderFormController.h"

@implementation BookmarksController

@synthesize browserController, formController, folderController;
@synthesize mode, bookmarks, folders, folderImage, bookmarkImage;
@synthesize toolbar, editToolbar, folderIndex, bookmarkIndex;
@synthesize bookmarksSeedResourceName;

// The designated initializer.  Override if you create the controller programmatically
// and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
        self.folderIndex = BOOKMARKS_ROOT;
        self.bookmarksSeedResourceName = BOOKMARKS_SEED_RESOURCE_NAME;
        [self loadBookmarks];
    }
    return self;
}

- (void)viewDidLoad {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    //Load the Folders dictionary from the key in user defaults storage.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* foldersDict = [defaults objectForKey:FOLDERS_KEY];
    //Check to see if the folders dict is nil, if it is, create a new folder withe the default structure.
    if (foldersDict == nil)
    {
        NSString *fname = nil;
        fname = [[NSBundle mainBundle] pathForResource:bookmarksSeedResourceName ofType:@"strings"];
        NSDictionary *seedBookmarks = [NSDictionary dictionaryWithContentsOfFile:fname];
        
        NSMutableDictionary *foldersDict = [[NSMutableDictionary alloc] init];
        
        NSEnumerator *enumerator = [seedBookmarks keyEnumerator];
        NSString *key;
        NSArray *bookmarkComponents;
        NSString *url;
        NSDictionary *bookmark;
        NSDictionary *folder;
        NSString *folderName;
        NSString *bookmarkName;
        
        
        while ((key = [enumerator nextObject])) {
            bookmarkComponents = [key componentsSeparatedByString:@"/"];
            url = [seedBookmarks objectForKey:key];

            if ([bookmarkComponents count] == 2) {
                folderName = [bookmarkComponents objectAtIndex:0];
                bookmarkName = [bookmarkComponents objectAtIndex:1];
                
                bookmark = [NSDictionary dictionaryWithObjectsAndKeys:
                                   bookmarkName, @"title",url,@"URL",nil];
                
                folder = [foldersDict objectForKey:folderName];
                if (folder) {
                    [(NSMutableArray *)[folder objectForKey:@"bookmarks"] addObject:bookmark];
                } else {
                    folder = [NSDictionary dictionaryWithObjectsAndKeys:folderName, @"title",
                              [NSMutableArray arrayWithObject:bookmark], @"bookmarks",nil];
                    [foldersDict setObject:folder forKey:folderName];
                }

            }
        } 

        [defaults setObject:[foldersDict allValues] forKey:FOLDERS_KEY];
        [defaults synchronize];
    }
    
	// nav
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				target:self 
																				action:@selector(switchToBrowser:)];
	[self.navigationItem setRightBarButtonItem:doneButton];
	self.navigationItem.title = @"Bookmarks";
	
	// default to view mode
	if (!mode) {
		self.mode = 'V';
	}
	
	formController = [browserController bookmarksFormController];
	
    /*if ([self respondsToSelector:@selector(setPreferredContentSize:)]) {
        self.preferredContentSize = CGSizeMake(320.0, 480.0);
    } else {
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    }*/
    [super viewDidLoad];
}

-(void) viewDidAppear:(BOOL)animated {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	[_tableView deselectRowAtIndexPath:[_tableView indexPathForSelectedRow] animated:animated];
    [self.tableView reloadData];
}

-(void) viewWillAppear:(BOOL)animated {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [super viewWillAppear:animated];
    // load bookmark related images
    if (folderImage == nil || bookmarkImage == nil) {
        folderImage = [UIImage imageNamed:@"folder.png"];
        bookmarkImage = [UIImage imageNamed:@"bookmark.png"];
    }


    /*if (mode == 'P') {
        ((UIBarItem *)[[toolbar items] objectAtIndex:0]).enabled = NO;
    } else {
        ((UIBarItem *)[[toolbar items] objectAtIndex:0]).enabled = YES;
    }*/
    ((UIBarItem *)[[toolbar items] objectAtIndex:0]).enabled = YES;
    [self loadBookmarks];
    [self.tableView reloadData];
}


- (NSUInteger) supportedInterfaceOrientations {
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    // Return the orientation you'd prefer - this is what it launches to. The
    // user can still rotate. You don't have to implement this method, in which
    // case it launches in the current orientation
    return UIInterfaceOrientationPortrait;
}

-(void)reloadBookmarksData {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    //Get the array of folder dictionaries from NSUSerDefaults
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* foldersArray = (NSMutableArray*)[defaults objectForKey:FOLDERS_KEY];
    self.folders = [foldersArray mutableCopy];
    //If this isn't a folder array, it must be a bookmark array, so return the bookmark array.
    if (self.folderIndex != BOOKMARKS_ROOT) {
        NSMutableDictionary* folderDict = [foldersArray objectAtIndex:self.folderIndex];
        self.bookmarks = [[folderDict objectForKey:@"bookmarks"] mutableCopy];
    }
    else {
        self.bookmarks = nil;
    }
}

- (void) loadBookmarks {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    //Get the array of folder dictionaries from NSUSerDefaults
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* foldersArray = (NSMutableArray*)[defaults objectForKey:FOLDERS_KEY];
    self.folders = [foldersArray mutableCopy];
    //If this isn't a folder array, it must be a bookmark array, so return the bookmark array.
    if (self.folderIndex != BOOKMARKS_ROOT) {
        NSMutableDictionary* folderDict = [foldersArray objectAtIndex:self.folderIndex];
        self.bookmarks = [[folderDict objectForKey:@"bookmarks"] mutableCopy];
    }
    else {
        self.bookmarks = nil;
    }
}

- (IBAction)switchToBrowser:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	if (mode == 'E') {
		[self finishEditMode:sender];
	}
    //[self.navigationController popToRootViewControllerAnimated:NO];
	[UIView animateWithDuration:0.25 animations:^{
        [self.navigationController view].alpha =0.0f;
        [browserController dismissPopups];
    }];
}

-(void) openBookmark:(NSIndexPath *) indexPath{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	[[browserController addressBar] setText:[[bookmarks objectAtIndex:[indexPath row]] valueForKey:@"URL"]];
	[browserController gotoAddress:nil];
	[self switchToBrowser:nil];
}

-(IBAction) enableEditMode:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if(self.mode == 'B')
    {
        for (UIBarButtonItem *item in editToolbar.items)
        {
            if([[item title] isEqualToString:@"New Folder"])
            {
                [item setEnabled:NO];
                [item setTintColor:[UIColor clearColor]];
            }
        }
    }
    else
    {
        for (UIBarButtonItem *item in editToolbar.items)
        {
            if([[item title] isEqualToString:@"New Folder"])
            {
                [item setEnabled:YES];
                [item setTintColor:nil];
            }
        }
    }
	self.mode = 'E';
	toolbar.hidden = YES;
	editToolbar.hidden = NO;
	[self.navigationItem setRightBarButtonItem:nil];
	[_tableView reloadData];
}

-(IBAction) finishEditMode:(id)sender{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	if(self.folderIndex == BOOKMARKS_ROOT || self.mode == 'V')
        self.mode = 'V';
    else
        self.mode = 'B';
	toolbar.hidden = NO;
	editToolbar.hidden = YES;
	
	// done button
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
																				target:self 
																				action:@selector(switchToBrowser:)];
	[self.navigationItem setRightBarButtonItem:doneButton];
	
	[_tableView reloadData];
}

- (IBAction) addFolder:(id)sender{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	[folderController setMode:'A'];
    [folderController setBookmarksController:self];
	[self.navigationController pushViewController:(UIViewController *)folderController animated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [self loadBookmarks];
    if(self.bookmarks != nil && self.folderIndex != BOOKMARKS_ROOT)
        return [bookmarks count];
    else
        return [folders count];
}

// get images for bookmarks
-(NSString *) getBookmarkImageURLFromUrlString:(NSString *) urlString {
    NSString *encodedURL = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    return [NSString stringWithFormat:@"http://www.google.com/s2/favicons?domain=%@", encodedURL];
}

-(UIImage *) getBookmarkImageFromUrlString:(NSString *) urlString {
    NSString *bookmarkImageUrl = [self getBookmarkImageURLFromUrlString:urlString];
    NSData *bookmarkImageData = [NSData dataWithContentsOfURL:[NSURL URLWithString:bookmarkImageUrl]];
    return ([bookmarkImageData length] > 0) ? [UIImage imageWithData:bookmarkImageData] : bookmarkImage;
}

-(void) setBookmarkImageForCellWithURL:(NSArray *) args {
    BookmarkItem *cell = [args objectAtIndex:0];
    NSString *urlString = [args objectAtIndex:1];
    cell.cellImage.image = [self getBookmarkImageFromUrlString:urlString];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)localTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    static NSString *CellIdentifier = @"BookmarkItem";
    
    BookmarkItem *cell = (BookmarkItem *)[localTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
		NSArray *tlObjects = [[NSBundle mainBundle] loadNibNamed:@"BookmarkItem" owner:nil options:nil];
		
		for (id current in tlObjects) {
			if ([current isKindOfClass: [UITableViewCell class]]) {
				cell = (BookmarkItem *) current;
				break;
			}
		}
	}
    cell.bookmarksController = self;
	cell.tableView = localTableView;
	cell.indexPath = indexPath;
    
    //Load contents of each folder dictionary into a cell if in the Bookmarks root
    if (self.mode == 'V' || self.mode == 'P')
    {
        NSDictionary* folderDict = [self.folders objectAtIndex:[indexPath row]];
        [cell.cellLabel setText:[folderDict valueForKey:@"title"]];
        cell.cellImage.image = folderImage;
    }
    
    //Load contents of each bookmark dictionary into a cell if in a Folder
    if (self.mode == 'B')
    {
        NSDictionary* folderDict = [self.folders objectAtIndex:self.folderIndex];
        NSArray* bookmarksArray = [folderDict objectForKey:@"bookmarks"];
        NSDictionary* bookmarkDict = [bookmarksArray objectAtIndex:[indexPath row]];
        [cell.cellLabel setText:[bookmarkDict valueForKey:@"title"]];
        LogInfo(@"Cell Label : %@", cell.cellLabel.text);
        // load bookmark icon async
        [self performSelectorInBackground:@selector(setBookmarkImageForCellWithURL:) withObject:@[cell, [bookmarkDict objectForKey:@"URL"]] ];
    }
    
    if (self.mode == 'E') {
        if(self.folderIndex != BOOKMARKS_ROOT)
        {
            NSDictionary* folderDict = [self.folders objectAtIndex:self.folderIndex];
            NSArray* bookmarksArray = [folderDict objectForKey:@"bookmarks"];
            NSDictionary* bookmarkDict = [bookmarksArray objectAtIndex:[indexPath row]];
            [cell.cellLabel setText:[bookmarkDict valueForKey:@"title"]];
            cell.cellImage.image = [self getBookmarkImageFromUrlString:[bookmarkDict objectForKey:@"URL"]];

            [cell enableEdit];
        }
        else
        {
            NSDictionary* folderDict = [self.folders objectAtIndex:[indexPath row]];
            [cell.cellLabel setText:[folderDict valueForKey:@"title"]];
            cell.cellImage.image = folderImage;
            if ([self.folders count] > 1)
            {
                [cell enableEdit];
            }
            else
            {
                [cell disableEdit];
            }
        }
	} else {
        [cell disableEdit];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	((BookmarkItem *)cell).cellLabel.font = [UIFont italicSystemFontOfSize:14.0];
    
}


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source.
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
 }   
 }
 */


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (mode == 'B') {
        //Open the URL from the bookmark in the folder
        [self openBookmark:indexPath];
    } else if (mode == 'V') {
        //Create a new bookmark controller, set the mode, and folder index
        BookmarksController *nextBookmarkController = [[BookmarksController alloc] initWithNibName:@"Bookmarks" bundle:[NSBundle mainBundle]];
        [nextBookmarkController setMode:'B'];
        [nextBookmarkController setFolderIndex:[indexPath row]];
        [nextBookmarkController setBrowserController:browserController];
        [nextBookmarkController setFolderController:[self folderController]];
        [self.navigationController pushViewController:nextBookmarkController animated:YES];
		
	} else if (mode == 'E') {
        
        [self loadBookmarks];
        
        if (self.folderIndex == BOOKMARKS_ROOT)
        {
            self.folderIndex = [indexPath row];
            [folderController setMode:'E'];
            [self setMode:'V'];
            [self.navigationController pushViewController:(UIViewController *)folderController animated:YES];
        }
        else
        {
            [formController setMode:'E'];
            [self setBookmarkIndex:[indexPath row]];
            [self.navigationController pushViewController:formController animated:YES];
        }
        
	} else if (self.mode == 'P') {
        NSArray *vControllers = self.navigationController.viewControllers;
		[[vControllers objectAtIndex:([vControllers count] - 3) ] setFolderIndex:[indexPath row]];
        [self.navigationController popViewControllerAnimated:YES];
        
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if ([tableView numberOfRowsInSection:0] < 2 && folderIndex == BOOKMARKS_ROOT) return NO;
    return YES;
}

- (void)didReceiveMemoryWarning {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}




@end
