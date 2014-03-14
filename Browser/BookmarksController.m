//
//  BookmarksController.m
//
//  Created by Alexandru Catighera on 6/14/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "BookmarksController.h"
#import "BrowserDelegate.h"
#import "BrowserViewController.h"
#import	"BookmarkItem.h"
#import "BookmarksFormController.h"
#import "BookmarkFolderFormController.h"

@implementation BookmarksController

@synthesize browserController, formController, folderController, managedObjectContext, mode, bookmarks, folderImage, bookmarkImage, toolbar, editToolbar, tableView, currentFolder;

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


- (void)viewDidLoad {
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
	
	self.contentSizeForViewInPopover = CGSizeMake(320.0, 480.0);
    [super viewDidLoad];
}

-(void) viewDidAppear:(BOOL)animated {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:animated];
}

-(void) viewWillAppear:(BOOL)animated {
    // load bookmark related images
    if (folderImage == nil || bookmarkImage == nil) {
        folderImage = [UIImage imageNamed:@"folder.png"];
        bookmarkImage = [UIImage imageNamed:@"bookmark.png"];
    }
    if (mode == 'P') {
        ((UIBarItem *)[[toolbar items] objectAtIndex:0]).enabled = NO;
    } else {
        ((UIBarItem *)[[toolbar items] objectAtIndex:0]).enabled = YES;
    }
    
    self.bookmarks = [self reloadBookmarks];
    [tableView reloadData];
	[super viewWillAppear:animated];
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

- (NSMutableArray *) reloadBookmarks {
	if (managedObjectContext == nil) 
	{ 
        managedObjectContext = [(BrowserDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSLog(@"After managedObjectContext: %@",  managedObjectContext);
	}
	
	// Create DB query request for bookmark folders
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *folderEntity = [NSEntityDescription entityForName:@"Folder" inManagedObjectContext:managedObjectContext];
    NSPredicate *predicateF = nil;
    if (mode != 'P') {
        predicateF = [NSPredicate predicateWithFormat:(currentFolder != nil) ? [NSString stringWithFormat:@"Parent.name == '%@'", [currentFolder valueForKey:@"name"]] : @"Parent == nil"];
    }
	[request setEntity:folderEntity];
    [request setPredicate:predicateF];
    NSMutableArray *folderFetchResults = [[managedObjectContext executeFetchRequest:request error:nil] mutableCopy];
    
	// Create DB query request for bookmarks
	
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Bookmark" inManagedObjectContext:managedObjectContext];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"Folder.name == %@", ((currentFolder == nil) ? nil : [currentFolder valueForKey:@"name"])];
	[request setEntity:entity];
	[request setPredicate:predicate];
	NSArray *bookmarkFetchResults = [managedObjectContext executeFetchRequest:request error:nil];
	
	if (mode != 'P') {
		[folderFetchResults addObjectsFromArray:bookmarkFetchResults];
	} else {
        [folderFetchResults insertObject:@"Bookmarks" atIndex:0];
    }
	
	return folderFetchResults;
}

- (IBAction)switchToBrowser:(id)sender {
	if (mode == 'E') {
		[self finishEditMode:sender];
	}
	
	if ([browserController isPad]) {
		[[browserController padPopover] dismissPopoverAnimated:YES];
	} else {
		[UIView transitionFromView:[self.navigationController view]
							toView: [browserController view]
						  duration:0.5
						   options:(UIViewAnimationOptionTransitionCrossDissolve)
						completion:^(BOOL finished) {}];
	}
	
	
	[self.navigationController popToRootViewControllerAnimated:NO];
}

-(void) openBookmark:(NSIndexPath *) indexPath{	
	[[browserController addressBar] setText:[[bookmarks objectAtIndex:[indexPath row]] valueForKey:@"url"]];
	[browserController gotoAddress:nil];
	[self switchToBrowser:nil];
}

-(IBAction) enableEditMode:(id)sender {
	self.mode = 'E';
	toolbar.hidden = YES;
	editToolbar.hidden = NO;
	[self.navigationItem setRightBarButtonItem:nil];
	
	[tableView reloadData];
	
}

-(IBAction) finishEditMode:(id)sender{
	self.mode = 'V';
	toolbar.hidden = NO;
	editToolbar.hidden = YES;
	
	// done button
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
																				target:self 
																				action:@selector(switchToBrowser:)];
	[self.navigationItem setRightBarButtonItem:doneButton];
	
	[tableView reloadData];
}
-(IBAction) addFolder:(id)sender{
	[folderController setMode:'A'];
	[self.navigationController pushViewController:(UIViewController *)folderController animated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	/*if (showAllBugs) {
		return [[[[NSURLCache sharedURLCache] filterManager] bugArray] count];
	} else {
		return [detectedBugs count];
	}*/
	return [bookmarks count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)localTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
    
	NSManagedObject *item= [bookmarks objectAtIndex:[indexPath row]];
	cell.bookmarksController = self;
	cell.tableView = localTableView;
	cell.indexPath = indexPath;
	if (![item isEqual:@"Bookmarks"] && [[[item entity] name] isEqualToString:@"Bookmark"]) {
		cell.cellImage.image = bookmarkImage;
	} else {
		cell.cellImage.image = folderImage;
	}
    if ([item isEqual:@"Bookmarks"]) {
        [cell.cellLabel setText:@"Bookmarks"];
    } else {
        [cell.cellLabel setText:[item valueForKey:@"name"]];
    }
	
	if (self.mode == 'E') {
		[cell enableEdit];
	} else if (self.mode == 'V') {
		[cell disableEdit];
	}

    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	/*NSMutableArray *bugs = showAllBugs ? [[[NSURLCache sharedURLCache] filterManager] bugArray] : detectedBugs;
	NSManagedObject *bug = [bugs objectAtIndex:[indexPath indexAtPosition:1]];
	NSNumber *block = [bug valueForKey:@"block"];
	if (block.boolValue) {
		cell.textLabel.font = [UIFont italicSystemFontOfSize:19.0];
		cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.0 blue:0.0 alpha:0.7];
	} else {
		cell.textLabel.font = [UIFont boldSystemFontOfSize:19.0];
		cell.textLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
	}*/
	//cell.selectionStyle = UITableViewCellSelectionStyleNone;
	((BookmarkItem *)cell).cellLabel.font = [UIFont italicSystemFontOfSize:17.0];
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
	/*NSMutableArray *bugs = showAllBugs ? [[[NSURLCache sharedURLCache] filterManager] bugArray] : detectedBugs;
	NSManagedObject *bug = [bugs objectAtIndex:[indexPath indexAtPosition:1]];
	NSNumber *block = [bug valueForKey:@"block"];
	
	selectedManagedObject = [bugs objectAtIndex:[indexPath row]];
	if (selectedIndexPath) {
		[selectedIndexPath release];
	}
	selectedIndexPath = [indexPath copy];
	
	if (block.boolValue) {
		[blockButton setTitle:@"Unblock"];
	} else {
		[blockButton setTitle:@"Block"];
	}*/
	NSManagedObject *item = [bookmarks objectAtIndex:[indexPath row]];
	if (mode == 'V') {
		if ([[[item entity] name] isEqualToString:@"Folder"]) {
			BookmarksController *nextBookmarkController = [[BookmarksController alloc] initWithNibName:@"Bookmarks" bundle:[NSBundle mainBundle]];
			[nextBookmarkController setMode:[self mode]];
			[nextBookmarkController setCurrentFolder:item];
			[nextBookmarkController setManagedObjectContext:managedObjectContext];
			[nextBookmarkController setBrowserController:browserController];
            [nextBookmarkController setFolderController:[self folderController]];
			[self.navigationController pushViewController:nextBookmarkController animated:YES];
		} else {
			[self openBookmark:indexPath];
		}
		
	} else if (mode == 'E') {
		if ([[[item entity] name] isEqualToString:@"Folder"]) {
			[folderController setMode:'E'];
			[folderController setFolder:item];
			[self.navigationController pushViewController:(UIViewController *)folderController animated:YES];
		} else {
			[formController setMode:'E'];
			[self.navigationController pushViewController:formController animated:YES];
		}

	} else if (mode == 'P') {
		NSArray *vControllers = self.navigationController.viewControllers;
		[[vControllers objectAtIndex:([vControllers count] - 2) ] setSelectedFolder:item];
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
