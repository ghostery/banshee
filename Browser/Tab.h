//
//  Tab.h
//
//  Created by Alexandru Catighera on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class BrowserViewController, FilterManager;

@interface Tab : UIView <NSURLConnectionDelegate, UIWebViewDelegate, UIActionSheetDelegate>{
	UIButton *tabButton;
	UILabel *tabTitle;
	UIWebView *webView;
	UIButton *closeButton;
	    
    NSString *currentURLString;
    NSURL *currentURL;
    NSString *connectionURLString;
    NSURLConnection *urlConnection;
    NSHTTPURLResponse *response;
    NSMutableData *pageData;
    
    NSMutableArray *history;
    int traverse;
    int history_position;
    
    int scrollPosition;
    
    BOOL loading;
    BOOL current;
    BOOL actionSheetVisible;
    
    double loadStartTime;
    double loadEndTime;
    NSString *pageInfoJS;
    
    BrowserViewController *viewController;
	
}

@property(nonatomic,strong) UIButton *tabButton;
@property(nonatomic,strong) UILabel *tabTitle;
@property(nonatomic,strong) UIWebView *webView;
@property(nonatomic,strong) UIButton *closeButton;

@property(nonatomic,strong) NSString *currentURLString;
@property(nonatomic,strong) NSURL *currentURL;
@property(nonatomic,strong) NSString *connectionURLString;
@property(nonatomic,strong) NSURLConnection *urlConnection;
@property(nonatomic,strong) NSHTTPURLResponse *response;
@property(nonatomic,strong) NSMutableData *pageData;

@property(nonatomic,strong) NSMutableArray *history;
@property(nonatomic,assign) int traverse;
@property(nonatomic,assign) int history_position;

@property(nonatomic,assign) int scrollPosition;

@property(nonatomic,assign) BOOL loading;
@property(nonatomic,assign) BOOL current;
@property(nonatomic,assign) BOOL actionSheetVisible;

@property(nonatomic,assign) double loadStartTime;
@property(nonatomic,assign) double loadEndTime;
@property(nonatomic,strong) NSString *pageInfoJS;

@property(nonatomic,strong) BrowserViewController *viewController;

-(void) select;
-(void) deselect;
-(void) setTitle:(NSString *)title;
-(void) incrementOffset;
-(void) hideText;
-(void) showText;

-(BOOL) canGoBack;
-(BOOL) canGoForward;
-(void) goBack;
-(void) goForward;
-(void) go:(int)t;
-(void) updateHistory;

-(id) initWithFrame:(CGRect)frame addTarget:(BrowserViewController *) viewController;

@end
