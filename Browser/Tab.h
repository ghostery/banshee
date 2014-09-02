//
//  Tab.h
//
//  Created by Alexandru Catighera on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define kTabWidth 100.0

@class BrowserViewController, FilterManager;

@interface Tab : UIView <NSURLConnectionDelegate, UIWebViewDelegate, UIActionSheetDelegate>

@property (assign) NSUInteger loadingCount;

@property(nonatomic,strong) UIButton *tabButton;
@property (nonatomic, strong) UILabel *tabTitle;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) CGRect tabTitleFrame;
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
@property(nonatomic,assign) NSInteger history_position;

@property(nonatomic,assign) int scrollPosition;

@property(nonatomic,assign) BOOL isLoading;
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
