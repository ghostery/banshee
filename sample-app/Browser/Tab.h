//
//  Tab.h
//  Ghostery
//
//  Created by Alexandru Catighera on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class BrowserViewController;

@interface Tab : UIView {
	UIButton *tabButton;
	UILabel *tabTitle;
	UIWebView *webView;
	UIButton *closeButton;
	
	NSMutableArray *detectedBugArray;
    
    NSMutableArray *history;
    int traverse;
    int history_position;
    
    int scrollPosition;
    
    BrowserViewController *viewController;
	
}

@property(nonatomic,strong) UIButton *tabButton;
@property(nonatomic,strong) UILabel *tabTitle;
@property(nonatomic,strong) UIWebView *webView;
@property(nonatomic,strong) UIButton *closeButton;

@property(nonatomic,strong) NSMutableArray *detectedBugArray;

@property(nonatomic,strong) NSMutableArray *history;
@property(nonatomic,assign) int traverse;
@property(nonatomic,assign) int history_position;

@property(nonatomic,assign) int scrollPosition;

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
