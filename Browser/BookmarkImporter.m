//
//  BookmarkImporter.m
//
//  Created by Alexandru Catighera on 10/11/12.
//
//

#import "BookmarkImporter.h"
#import "BrowserDelegate.h"

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/HTMLparser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

@implementation BookmarkImporter

- (void)loadBookmarksFromUrl:(NSURL *) url{
    NSError *error;
    if (_managedObjectContext == nil)
        
	{
        _managedObjectContext = [(BrowserDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSLog(@"After managedObjectContext: %@",  _managedObjectContext);
	}
    
    
    NSString *bookmarkHTML = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<DT>|<dt>|<p>|</p>|FOLDED|\n|\t|\r|<meta[^>]*|<!--(.|\n|\r)*-->|<!DOCTYPE.*>" options:NSRegularExpressionCaseInsensitive error:&error];
    bookmarkHTML = [regex stringByReplacingMatchesInString:bookmarkHTML options:0 range:NSMakeRange(0, [bookmarkHTML length]) withTemplate:@""];
    //bookmarkHTML = [bookmarkHTML stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    if ([[bookmarkHTML lowercaseString] rangeOfString:@"<html>"].location != NSNotFound) {
        bookmarkHTML = [bookmarkHTML stringByReplacingOccurrencesOfString:@"<HTML>" withString:@"<root>"];
        bookmarkHTML = [bookmarkHTML stringByReplacingOccurrencesOfString:@"<html>" withString:@"<root>"];
        bookmarkHTML = [bookmarkHTML stringByReplacingOccurrencesOfString:@"<\\HTML>" withString:@"<\root>"];
        bookmarkHTML = [bookmarkHTML stringByReplacingOccurrencesOfString:@"<\\html>" withString:@"<\root>"];
    } else {
        bookmarkHTML = [NSString stringWithFormat:@"<root>%@</root>", bookmarkHTML];
    }
    NSData *bookmarkData = [bookmarkHTML dataUsingEncoding:NSUTF8StringEncoding];
    
    NSManagedObject *parentFolder = [NSEntityDescription insertNewObjectForEntityForName:@"Folder" inManagedObjectContext:_managedObjectContext];
    [parentFolder setValue:[NSString stringWithFormat:@"import folder %@", [[NSDate date] description]] forKey:@"name"];
    [parentFolder setNilValueForKey:@"Parent"];
    
    [self setRootFolder:parentFolder];
    
    self.allNodes = [self extractXMLData:bookmarkData];
    [self loadBookmarksFromAllNodesinFolder:parentFolder scanDL:YES];
    //NSLog(@"error: %@", error);
    

}


- (xmlNodeSetPtr) extractXMLData:(NSData *) docData {
    
    xmlDocPtr doc = xmlReadMemory([docData bytes], (int)[docData length], "", NULL, XML_PARSE_RECOVER);
    xmlXPathContextPtr context = xmlXPathNewContext(doc);
    xmlNodeSetPtr nodes = xmlXPathEvalExpression((xmlChar *)[@"//root/*" cStringUsingEncoding:NSUTF8StringEncoding], context)->nodesetval;
    return nodes;
}


- (void) loadBookmarksFromNodes:(NSArray *)nodes inFolder:(NSManagedObject *)parentFolder scanDL:(BOOL)scanDL {
    for (int i =0; i < [nodes count]; i++) {
        xmlNodePtr node = [[nodes objectAtIndex:i] pointerValue];
        NSString *nodeName = nil;
        if (node->name) {
            nodeName = [[NSString stringWithCString:(const char *)node->name encoding:NSUTF8StringEncoding] lowercaseString];
        }
        if (nodeName != nil && [nodeName isEqualToString:@"h3"]) {
            NSManagedObject *folder = [NSEntityDescription insertNewObjectForEntityForName:@"Folder" inManagedObjectContext:_managedObjectContext];
            NSString *name = [NSString stringWithCString:node->children->content encoding:NSUTF8StringEncoding];
            name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            [folder setValue:name forKey:@"name"];
            [folder setValue:parentFolder forKey:@"Parent"];
            if (parentFolder != nil) {
                
                NSLog(@"folder:%@ parent:%@", [folder valueForKey:@"name"], [[folder valueForKey:@"Parent"] valueForKey:@"name"]);
            }
            xmlNodePtr nextNode;
            NSString *nextNodeName = nil;
            for (int z = i + 1; z < [nodes count]; z++) {
                nextNode = [[nodes objectAtIndex:z] pointerValue];
                if (nextNode->name) {
                    nextNodeName = [[NSString stringWithCString:(const char *)nextNode->name encoding:NSUTF8StringEncoding] lowercaseString];
                }
                if (nextNodeName != nil && [nextNodeName isEqualToString:@"dl"]) {
                    break;
                }
            }
            [self loadBookmarksFromChildrenNodes:nextNode->children inFolder:folder scanDL:NO];
            
        } else if (nodeName != nil && [nodeName isEqualToString:@"a"]) {
            xmlAttr *attr = node->properties;
            while (attr) {
                NSString *attrName = [[NSString stringWithCString:(const char *)attr->name encoding:NSUTF8StringEncoding] lowercaseString];
                NSString *attrVal = [NSString stringWithCString:(const char *)attr->children->content encoding:NSUTF8StringEncoding];
                if ([attrName isEqualToString:@"href"] &&
                    [attrVal hasPrefix:@"http"] &&
                    ![attrVal hasPrefix:@"http://localhost"]) {
                    NSManagedObject *bookmark = [NSEntityDescription insertNewObjectForEntityForName:@"Bookmark" inManagedObjectContext:_managedObjectContext];
                    NSString *name = [NSString stringWithCString:(const char *)node->children->content encoding:NSUTF8StringEncoding];
                    [bookmark setValue:name forKey:@"name"];
                    [bookmark setValue:attrVal forKey:@"url"];
                    [bookmark setValue:parentFolder forKey:@"Folder"];
                    if (![_managedObjectContext save:nil]) {
                        NSLog(@"save attempt %@ | %@",name, attrVal);
                    }
                }
                attr = attr->next;
            }
            
        } else if (nodeName != nil && scanDL && [nodeName isEqualToString:@"dl"]) {
            [self loadBookmarksFromChildrenNodes:node->children inFolder:parentFolder scanDL:NO];
        }
    }
}

- (void) loadBookmarksFromChildrenNodes:(xmlNodePtr)children inFolder:(NSManagedObject *)parentFolder scanDL:(BOOL)scanDL {
    xmlNodePtr child = children;
    NSMutableArray *nodes = [NSMutableArray array];
    while(child) {
        [nodes addObject:[NSValue valueWithPointer:child]];
        child = child->next;
    }
    [self loadBookmarksFromNodes:nodes inFolder:parentFolder scanDL:scanDL];

}

- (void) loadBookmarksFromAllNodesinFolder:(NSManagedObject *)parentFolder scanDL:(BOOL)scanDL {
    NSMutableArray *nodes = [NSMutableArray array];
    for (int i = 0; i < self.allNodes->nodeNr; i++ ) {
        xmlNodePtr node = self.allNodes->nodeTab[i];
        [nodes addObject:[NSValue valueWithPointer:node]];
    }
    [self loadBookmarksFromNodes:nodes inFolder:parentFolder scanDL:scanDL];

}

- (void) save:(NSError **) err {
    if (_managedObjectContext != nil)
	{
        [_managedObjectContext save:err];
        //NSLog(@"managed error: %@ %@ %@ %i", [*err localizedDescription], [*err helpAnchor], [*err domain], [*err code]);
    }
}



@end
