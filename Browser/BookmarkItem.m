//
//  BookmarkItem.m
//
//  Created by Alexandru Catighera on 6/17/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "BookmarkItem.h"
#import "BookmarksController.h"
#import "QuartzCore/CAAnimation.h"

@implementation BookmarkItem

@synthesize cellImage, cellLabel, deleteCircle, deleteConfirmation, indexPath, tableView, bookmarksController;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state.
}

-(void) enableEdit {
	if (deleteCircle.hidden) {
		deleteCircle.hidden = NO;
		cellImage.frame = CGRectOffset(cellImage.frame, deleteCircle.bounds.size.width, 0.0);
		cellLabel.frame = CGRectMake(cellLabel.frame.origin.x + deleteCircle.bounds.size.width, 
									 cellLabel.frame.origin.y, 
									 cellLabel.bounds.size.width - deleteCircle.bounds.size.width, 
									 cellLabel.bounds.size.height);
	}
}

-(void) disableEdit {
	if (!deleteCircle.hidden) {
		deleteCircle.hidden = YES;
		cellImage.frame = CGRectOffset(cellImage.frame, -deleteCircle.bounds.size.width, 0.0);
		cellLabel.frame = CGRectMake(cellLabel.frame.origin.x - deleteCircle.bounds.size.width, 
									 cellLabel.frame.origin.y, 
									 cellLabel.bounds.size.width + deleteCircle.bounds.size.width, 
									 cellLabel.bounds.size.height);
		if (!deleteConfirmation.hidden){
			[self disableDelete];
		}
	}

}

-(void) enableDelete {
	// rotate delete circle
	deleteCircle.transform = CGAffineTransformMakeRotation( ( 90 * M_PI ) / 180 );
	
	deleteConfirmation.hidden = NO;
	cellLabel.frame = CGRectMake(cellLabel.frame.origin.x , 
								 cellLabel.frame.origin.y, 
								 cellLabel.bounds.size.width - deleteConfirmation.bounds.size.width, 
								 cellLabel.bounds.size.height);
}

-(void) disableDelete {
	// rotate delete circle
	deleteCircle.transform = CGAffineTransformMakeRotation( ( 0 * M_PI ) / 180 );
	
	deleteConfirmation.hidden = YES;
	cellLabel.frame = CGRectMake(cellLabel.frame.origin.x , 
								 cellLabel.frame.origin.y, 
								 cellLabel.bounds.size.width + deleteConfirmation.bounds.size.width, 
								 cellLabel.bounds.size.height);
}

-(IBAction) deleteCircleClick:(id)sender {
	if (deleteConfirmation.hidden) {
		[self enableDelete];
	} else {
		[self disableDelete];
	}
}

-(IBAction) deleteItem:(id)sender {
	NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
    [self deleteFromBookmarks:[indexPath row]];
	[tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:YES];
	[tableView reloadData];
}

-(void)deleteFromBookmarks:(NSInteger)index {
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    if (bookmarksController.folderIndex == BOOKMARKS_ROOT)
    {
        [bookmarksController.folders removeObjectAtIndex:index];
    }
    else
    {
        [bookmarksController.bookmarks removeObjectAtIndex:index];
        NSMutableDictionary* folderDict = (NSMutableDictionary*)[[bookmarksController.folders objectAtIndex:bookmarksController.folderIndex] mutableCopy];
        [folderDict setObject:bookmarksController.bookmarks forKey:@"bookmarks"];
        [bookmarksController.folders setObject:folderDict atIndexedSubscript:bookmarksController.folderIndex];
    }
    
    [defaults setObject:bookmarksController.folders forKey:FOLDERS_KEY];
    [defaults synchronize];
    [bookmarksController loadBookmarks];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.deleteConfirmation setFrame:CGRectMake(self.tableView.frame.size.width - self.deleteConfirmation.frame.size.width,
                                                 self.deleteConfirmation.frame.origin.y,
                                                 self.deleteConfirmation.frame.size.width,
                                                 self.deleteConfirmation.frame.size.height)];
}

@end
