//
//  BookmarkImporter.h
//
//  Created by Alexandru Catighera on 10/11/12.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <libxml/xpath.h>

@interface BookmarkImporter : NSObject

- (void)loadBookmarksFromUrl:(NSURL *) url;
- (void) loadBookmarksFromNodes:(NSArray *)nodes inFolder:(NSManagedObject *)parentFolder scanDL:(BOOL)scanDL;
- (void) loadBookmarksFromChildrenNodes:(xmlNodePtr)children inFolder:(NSManagedObject *)parentFolder scanDL:(BOOL)scanDL;
- (void) loadBookmarksFromAllNodesinFolder:(NSManagedObject *)parentFolder scanDL:(BOOL)scanDL;

- (void) save:(NSError **) err;

@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, strong) NSManagedObject *rootFolder;
@property(nonatomic, assign) xmlNodeSetPtr allNodes;


@end
