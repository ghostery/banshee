//
//  Tab.m
//
//  Created by Alexandru Catighera on 4/28/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "Tab.h"
#import "BrowserViewController.h"

@implementation Tab

@synthesize detectedBugArray, tabButton, webView, closeButton, tabTitle, history, traverse, history_position, scrollPosition;

-(id) initWithFrame:(CGRect)frame addTarget:(BrowserViewController *) vc {
	if ((self = [super initWithFrame:frame])) {
        viewController = vc;
        
		// Create tab button
		[self setTabButton:[UIButton buttonWithType:UIButtonTypeCustom]];
	
		// Style tab button
		[[tabButton layer] setCornerRadius: 5.0f];
		[[tabButton layer] setMasksToBounds:YES];
		[[tabButton layer] setBorderWidth: 0.5f];
	
		[tabButton setBackgroundColor:[UIColor grayColor]];
	
		tabButton.titleLabel.font = [UIFont systemFontOfSize: 14];
		[tabButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

		tabButton.contentEdgeInsets = UIEdgeInsetsMake(-3.0, 8.0, 0.0, 0.0);
		tabButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		tabButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	
		tabButton.frame = CGRectMake(0.0, 0.0, 100.0, 34.0);
	
		// Create close tab button
		[self setCloseButton:[UIButton buttonWithType:UIButtonTypeCustom]];
	
		[closeButton setTitle:@"x" forState:UIControlStateNormal];
		[closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		closeButton.frame = CGRectMake(76.0, 3.0, 25.0, 25.0);
		closeButton.titleLabel.font = [UIFont systemFontOfSize: 18];
	
		// append views
		[self addSubview:tabButton];
		[self addSubview:closeButton];
	
		// Set up webview
		webView = [[UIWebView alloc] initWithFrame:((UIView *)[viewController webViewTemplate]).frame];
		webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		webView.scalesPageToFit = true;
        webView.scrollView.scrollEnabled = YES; 
        webView.scrollView.bounces = YES;
		[webView sizeToFit];
		[webView setDelegate:viewController];
        // Scroll topbar
        [[webView scrollView] setDelegate:viewController];
        [[webView scrollView] setContentInset:UIEdgeInsetsMake([viewController topBar].frame.size.height, 0, 0, 0)];
        
		[[viewController view] addSubview:webView];
		[[viewController view] sendSubviewToBack:webView];
        [[viewController view] sendSubviewToBack:[viewController webViewTemplate]];
        
	
		// Set up interactions
		[tabButton addTarget:viewController 
					action:@selector(selectTab:)
					forControlEvents:UIControlEventTouchDown];
		[closeButton addTarget:viewController 
					action:@selector(removeTab:)
					forControlEvents:UIControlEventTouchDown];
		
		//Set bug array
        NSMutableArray *dbugs = [[NSMutableArray alloc] initWithCapacity:0];
		[self setDetectedBugArray: dbugs];
        
        //Set history
        [self setHistory:[[NSMutableArray alloc] initWithCapacity:0]];
        traverse = 0;
        history_position = 0;
	
		//Set title
		[tabButton setTitle:@"New Tab" forState:UIControlStateNormal];
		[tabButton setTitle:@"New Tab" forState:UIControlStateHighlighted];
	}
	return self;
}

-(void) setTitle:(NSString *)title {
	if ([title length] > 7) {
		title = [[title substringToIndex:7] stringByAppendingString:@"..."];
	}
	[[self tabButton] setTitle:title forState:UIControlStateNormal];
	[[self tabButton] setTitle:title forState:UIControlStateHighlighted];

}

-(void) select {
	[tabButton setBackgroundColor:[UIColor whiteColor]];
	tabButton.selected = YES;
	tabButton.enabled = NO;
	[webView.superview bringSubviewToFront:webView];
	[self.superview bringSubviewToFront:self];
}

-(void) deselect {
	[tabButton setBackgroundColor:[UIColor lightGrayColor]];
	tabButton.selected = NO;
	tabButton.enabled = YES;
	[webView.superview sendSubviewToBack:webView];
	[self.superview sendSubviewToBack:self];
}

-(void) incrementOffset {
	self.frame = CGRectOffset(self.frame, -100.0, 0.0);
}

-(void) hideText {
    [tabButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(void) showText {
    [tabButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

// HISTORY

-(BOOL) canGoBack {
    return history.count > 0 && history_position > 0;
}

-(BOOL) canGoForward {
    return history.count > 0 && history_position < history.count - 1;
}

-(void) goBack {
    [self go:-1];
}

-(void) goForward {
    [self go:1];
}

-(void) go:(int)t {
    [viewController forwardButton].enabled = FALSE;
    [viewController backButton].enabled = FALSE;
    traverse = t;
    history_position += traverse;
    NSArray *req = [history objectAtIndex:history_position];
    
    //[[viewController addressBar] setText:[[req URL] absoluteString]];
    [viewController gotoAddress:nil withRequestObj:req];

}

-(void) updateHistory {
    if (traverse == 0) {
        if (history_position + 1 < history.count) {
            [history removeObjectsInRange:NSMakeRange(history_position + 1, history.count - history_position - 1)];
        }
        NSURLRequest *req = [[[viewController urlConnection] currentRequest] mutableCopy];
        
        [history addObject:req];
        history_position = history.count - 1;
    }
    traverse = 0;
}


@end
