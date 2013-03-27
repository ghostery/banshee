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
	NSManagedObject *bookmarkToDelete = [[bookmarksController bookmarks] objectAtIndex:[indexPath row]];
	
	[[bookmarksController bookmarks] removeObject:bookmarkToDelete];
	[self deleteItemFromDB:bookmarkToDelete];
	[[bookmarksController managedObjectContext] save:nil];
	[tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:YES];
	[tableView reloadData];
}

- (void) deleteItemFromDB:(NSManagedObject *) dbItem {
    if ([[[dbItem entity] name] isEqualToString:@"Folder"]) {
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *folderEntity = [NSEntityDescription entityForName:@"Folder" inManagedObjectContext:[bookmarksController managedObjectContext]];
        NSPredicate *predicateF = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"Parent.name == '%@'", [dbItem valueForKey:@"name"]]];
        [request setEntity:folderEntity];
        [request setPredicate:predicateF];
        for (id child in [[bookmarksController managedObjectContext] executeFetchRequest:request error:nil]) {
            [self deleteItemFromDB:child];
        }

    }
    [[bookmarksController managedObjectContext] deleteObject:dbItem];
}




@end
