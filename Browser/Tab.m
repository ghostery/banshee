//
//  Tab.m
//
//  Created by Alexandru Catighera on 4/28/11.
//  Copyright 2011 Evidon. All rights reserved.
//

#import "Tab.h"
#import "BrowserViewController.h"
#import "BookmarksFormController.h"
#import "UIMainView.h"
#import "Logging.h"

@interface Tab ()

/**
 Counter that increments when webViewDidStartLoad: is called and decrements 
 when webViewDidFinishLoad: is called.
 */


@end

@implementation Tab

-(id) initWithFrame:(CGRect)frame addTarget:(BrowserViewController *) vc {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	if ((self = [super initWithFrame:frame])) {
        _viewController = vc;
        NSString *path = [[NSBundle mainBundle] pathForResource:@"page_info" ofType:@"js"];
        _pageInfoJS = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        
        
		// Create tab button
		[self setTabButton:[UIButton buttonWithType:UIButtonTypeCustom]];
	
		// Style tab button
		[[_tabButton layer] setCornerRadius: 5.0f];
		[[_tabButton layer] setMasksToBounds:YES];
		[[_tabButton layer] setBorderWidth: 0.5f];
	
		[_tabButton setBackgroundColor:[UIColor grayColor]];
	
		_tabButton.titleLabel.font = [UIFont systemFontOfSize:11];
		[_tabButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

		_tabButton.contentEdgeInsets = UIEdgeInsetsMake(0.0, 8.0, 0.0, 0.0);
		_tabButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		_tabButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
	
		_tabButton.frame = CGRectMake(0.0, 0.0, kTabWidth, 26.0);
        
        _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _activityIndicator.frame = CGRectMake(5, 2, 20, 20);
	
		// Create close tab button
		[self setCloseButton:[UIButton buttonWithType:UIButtonTypeCustom]];
	
		[_closeButton setTitle:@"x" forState:UIControlStateNormal];
        [_closeButton setAccessibilityLabel:@"close tab"];
		[_closeButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		_closeButton.frame = CGRectMake(kTabWidth - 21.0, -1.0, 25.0, 25.0);
		_closeButton.titleLabel.font = [UIFont systemFontOfSize:18];
	
        _tabTitleFrame = CGRectMake(5, 1, 80, 22);
        _tabTitle = [[UILabel alloc] initWithFrame:_tabTitleFrame];
        _tabTitle.font = [UIFont systemFontOfSize:11];
        _tabTitle.text = @"New Tab";
        
		// append views
        [_tabButton addSubview:_tabTitle];
		[self addSubview:_tabButton];
		[self addSubview:_closeButton];
        [self addSubview:_activityIndicator];
	
		// Set up webview
        UIWebView *wvTemplate = (UIWebView *)[_viewController webViewTemplate];
        int minWebViewSize = wvTemplate.frame.size.height;
        int maxWebViewSize = minWebViewSize + [_viewController bottomBar].frame.size.height;
        int height = [_viewController bottomBar].alpha > 0.0 ? minWebViewSize : maxWebViewSize;
        CGRect frame = CGRectMake(wvTemplate.frame.origin.x, wvTemplate.frame.origin.y, wvTemplate.frame.size.width, height);
		_webView = [[UIWebView alloc] initWithFrame:frame];
		_webView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		_webView.scalesPageToFit = true;
        _webView.scrollView.scrollEnabled = YES;
        _webView.scrollView.bounces = YES;
        _webView.backgroundColor = [UIColor whiteColor];
		[_webView sizeToFit];
		[_webView setDelegate:self];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextualMenuAction:)
                                                     name:@"TapAndHoldNotification"
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(startedLoadingNotification:)
                                                     name:kStartedLoadingNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(finishedLoadingNotification:)
                                                     name:kFinishedLoadingNotification
                                                   object:nil];
        
        // Scroll topbar
        [[_webView scrollView] setDelegate:_viewController];
        [[_webView scrollView] setContentInset:UIEdgeInsetsMake([_viewController topBar].frame.size.height, 0, 0, 0)];
        [[_webView scrollView] setContentOffset:CGPointMake(0, - [_viewController topBar].frame.size.height)];
        
		[[_viewController view] addSubview:_webView];
		[[_viewController view] sendSubviewToBack:_webView];
        [[_viewController view] sendSubviewToBack:[_viewController webViewTemplate]];
	
		// Set up interactions
		[_tabButton addTarget:_viewController
                       action:@selector(selectTab:)
                        forControlEvents:UIControlEventTouchDown];
		[_closeButton addTarget:_viewController
                         action:@selector(removeTab:)
                        forControlEvents:UIControlEventTouchDown];
		
        //Set history
        [self setHistory:[[NSMutableArray alloc] initWithCapacity:0]];
        _traverse = 0;
        _history_position = 0;
        _loadingCount = 0;
	
		//Set title
//		[_tabButton setTitle:@"New Tab" forState:UIControlStateNormal];
//		[_tabButton setTitle:@"New Tab" forState:UIControlStateHighlighted];
        

	}
	return self;
}

- (void)startedLoadingNotification:(NSNotification *)notification {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    
}

- (void)finishedLoadingNotification:(NSNotification *)notification {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    
}

- (void)incrementLoadingCount {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    BOOL startedAtZero = NO;
    if (_loadingCount == 0) {
        startedAtZero = YES;
    }
    _loadingCount++;
    if (startedAtZero) {
        CGRect newTabButtonFrame = _tabTitle.frame;
        CGFloat offset = _activityIndicator.frame.size.width + 5;
        LogDebug(@"offset: %f", offset);
        newTabButtonFrame.origin.x += offset;
        newTabButtonFrame.size.width -= offset;
        _tabTitle.frame = newTabButtonFrame;
        [_activityIndicator startAnimating];
    }
}

- (void)decrementLoadingCount {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (_loadingCount > 0) {
        _loadingCount--;
    }
    if (_loadingCount == 0) {
        [_activityIndicator stopAnimating];
//        CGRect newTabButtonFrame = _tabTitle.frame;
//        CGFloat offset = _activityIndicator.frame.size.width + 5;
//        LogDebug(@"offset: %f", offset);
//        newTabButtonFrame.origin.x -= offset;
//        newTabButtonFrame.size.width += offset;
        _tabTitle.frame = _tabTitleFrame;
    }
}

-(void) setTitle:(NSString *)title {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	if ([title length] > 11) {
		title = [[title substringToIndex:11] stringByAppendingString:@".."];
	}
	[[self tabButton] setTitle:title forState:UIControlStateNormal];
	[[self tabButton] setTitle:title forState:UIControlStateHighlighted];
    [[self tabButton] setAccessibilityLabel:[NSString stringWithFormat:@"Tab with title %@", title]];
    [[self closeButton] setAccessibilityLabel:[NSString stringWithFormat:@"Close Tab with title %@", title]];

}

-(void) select {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    _current = YES;
	[_tabButton setBackgroundColor:[UIColor whiteColor]];
	_tabButton.selected = YES;
	_tabButton.enabled = NO;
	[_webView.superview bringSubviewToFront:_webView];
	[self.superview bringSubviewToFront:self];
}

-(void) deselect {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    _current = NO;
	[_tabButton setBackgroundColor:[UIColor lightGrayColor]];
	_tabButton.selected = NO;
	_tabButton.enabled = YES;
	[_webView.superview sendSubviewToBack:_webView];
	[self.superview sendSubviewToBack:self];
}

-(void) incrementOffset {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	self.frame = CGRectOffset(self.frame, -kTabWidth, 0.0);
}

-(void) hideText {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_tabButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

-(void) showText {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_tabButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

// CONNECTION
#pragma mark -
#pragma mark urlConnection delegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    self.loading =YES;
    self.urlConnection = connection;
    self.connectionURLString = [[[connection currentRequest] URL] absoluteString];
    if (![self.connectionURLString hasSuffix:@"/"]) {
        self.connectionURLString = [self.connectionURLString stringByAppendingString:@"/"];
    }
    
    if (redirectResponse) {
        NSMutableURLRequest *r = [[connection currentRequest] mutableCopy]; // original request
        [r setURL: [request URL]];
        self.currentURL = [request URL];
        self.currentURLString = [[request URL] absoluteString];
        return r;
    } else {
        return request;
    }
}

- (void)connection: (NSURLConnection*) connection didReceiveResponse: (NSHTTPURLResponse*) response
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    self.currentURL = [response URL];
    self.currentURLString = [[response URL] absoluteString];
    [self setResponse:response];
    if (_current) {
        [[self progressBar] setProgress:0.25 animated:NO];
    }
    _pageData = [[NSMutableData alloc] initWithLength:0];
}

- (void) connection: (NSURLConnection*) connection didReceiveData: (NSData*) data
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_pageData appendData: data];
    if ([[self progressBar] progress] < 0.75) {
        [[self progressBar] setProgress:[[self progressBar] progress] + .05 animated:NO];
    }
    // Broadcast a notification with the progress change, or call a delegate
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
//    NSURLRequest *request = [connection originalRequest];/
    
    if ([_pageData length] == 0) {
        [[self history] removeLastObject];
        self.currentURL = [[[self history] lastObject] URL];
        self.currentURLString = [[[[self history] lastObject] URL] absoluteString];
        if (_current && ![_currentURLString isEqualToString:@"about:blank"] &&
            [_currentURLString rangeOfString:@"https://duckduckgo.com"].location == NSNotFound)
        {
            [[_viewController addressBar] setText:self.currentURLString];
        }
        
        [[self progressBar] setHidden:YES];
        return;
    }
    if ([[_response MIMEType] isEqualToString:@"text/html"] ||
        [[_response MIMEType] isEqualToString:@"application/xhtml+xml"] ||
        [[_response MIMEType] isEqualToString:@"text/vnd.wap.wml"])
    {
        NSStringEncoding enc = NSUTF8StringEncoding;
        if ([_response textEncodingName] != nil) {
            enc = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[_response textEncodingName]));
        }
        NSString *page = (NSString *)[[NSString alloc] initWithData:_pageData encoding:enc];
        
        [[self webView] stopLoading];
        [[self webView] loadHTMLString:page baseURL:self.currentURL];
        
    } else {
        [[self webView] stopLoading];
        [[self webView] loadData:_pageData MIMEType:[_response MIMEType] textEncodingName:[_response textEncodingName] baseURL:self.currentURL];
        //[whiteView setHidden:YES];
    }
    
    [[self progressBar] setProgress:0.75 animated:NO];
    _pageData = nil;
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [[self progressBar] setHidden:YES];
    if ([[connection currentRequest] URL] != NULL) {
        [_viewController cannotConnect:_webView];
    } else {
     [[self webView] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"launch" ofType:@"html"]isDirectory:NO]]];
     [[_viewController addressBar] setText:@""];
    }
}

- (UIProgressView *)progressBar {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    return _current ? [_viewController progressBar] : nil;
}

- (void)loadingBegan {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    
}

#pragma mark -
#pragma mark webview delegate

-(BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (request == nil) {
        return NO;
    }
    
    // CAPTURE PAGE LOAD
    if ([[[request URL] absoluteString] isEqualToString:@"js:gh-page-loaded"]) {
        [self webViewDidFinishFinalLoad:webView];
    }
    
	//CAPTURE USER LINK-CLICK.
	else if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
        if ([[[request URL] absoluteString] isEqualToString:[[request mainDocumentURL] absoluteString]]) {
            NSURL *URL = [request URL];
            if ([[URL absoluteString] isEqualToString:@"about:blank"]) {
                return YES;
            }
            if ([[URL scheme] isEqualToString:@"http"] || [[URL scheme] isEqualToString:@"https"]) {
                if (_current) {
                    [[_viewController addressBar] setText:[URL absoluteString]];
                }
                [_viewController gotoAddress:nil withRequestObj:request inTab:self];
            }
            return NO;
        }
	}
	return YES;
}

-(void) webViewDidStartLoad:(UIWebView *)webView {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (_loadingCount == 0) {
        _isLoading = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:kStartedLoadingNotification object:self];
    }
    [self incrementLoadingCount];
    LogDebug(@"loading count: %lu", (unsigned long)_loadingCount);
}

-(void) webViewDidFinishFinalLoad:(UIWebView *)webView {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
//    _loadingCount--;
//    LogDebug(@"loading count: %lu", (unsigned long)_loadingCount);
    self.loading = NO;
    if (_current) {
        [_viewController currentWebViewDidFinishFinalLoad:webView];
    }
    
    NSLog(@"Loaded url: %@", [webView.request mainDocumentURL]);
    
    // set title
    NSString *tabTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
//    NSString *url = [webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    if ([tabTitle length] == 0) {
        _tabTitle.text = @"New Tab";
//        [self setTitle:@"Untitled"];
    } else {
//        [self setTitle:tabTitle];
        _tabTitle.text = tabTitle;
    }
}

-(void) webViewDidFinishLoad:(UIWebView *)webView {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [self decrementLoadingCount];
    LogDebug(@"loading count: %lu", (unsigned long)_loadingCount);
    if (_loadingCount == 0) {
        _isLoading = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kFinishedLoadingNotification object:self];
    }
    if (![[[webView request] URL] isFileURL] && _currentURL != nil) {
        [webView stringByEvaluatingJavaScriptFromString:@"if (document.getElementById('gh-page-loaded') == null && document.documentElement.innerHTML != '<head></head><body></body>') {"
         "var iframe = document.createElement('IFRAME');"
         "iframe.setAttribute('id','gh-page-loaded');"
         "iframe.setAttribute('src', 'js:gh-page-loaded');"
         "iframe.setAttribute('style', 'display:none');"
         "document.body.appendChild(iframe);"
         "iframe = null;"
         "document.body.style.webkitTouchCallout='none';}" ];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    LogDebug(@"error: %@", error);
    
    BOOL wasLoadingBeforeDecrement = NO;
    if (_loadingCount > 0) {
        wasLoadingBeforeDecrement = YES;
    }
    [self decrementLoadingCount];
    if (wasLoadingBeforeDecrement && _loadingCount == 0) {
        _isLoading = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kFinishedLoadingNotification object:self];
    }
    LogDebug(@"loading count: %lu", (unsigned long)_loadingCount);
}

- (void)contextualMenuAction:(NSNotification*)notification
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (_actionSheetVisible || _webView != [_viewController webView] || !(_viewController.isViewLoaded && _viewController.view.window)) {
        return;
    }
    CGPoint pt;
    NSDictionary *coord = [notification object];
    pt.x = [[coord objectForKey:@"x"] floatValue];
    pt.y = [[coord objectForKey:@"y"] floatValue];
    
    // convert point from window to view coordinate system
    pt = [_webView convertPoint:pt fromView:nil];
    
    // convert point from view to HTML coordinate system
//    CGPoint offset  = [self scrollOffset];
    CGSize viewSize = [_webView frame].size;
    CGSize windowSize = [self windowSize];
    
    CGFloat f = windowSize.width / viewSize.width;
    pt.x = pt.x * f;// + offset.x;
    pt.y = pt.y * f;// + offset.y;
    
    [self openContextualMenuAt:pt];
}

- (void)openContextualMenuAt:(CGPoint)pt
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    // Load the JavaScript code from the Resources and inject it into the web page
    NSString *path = [[NSBundle mainBundle] pathForResource:@"JSTools" ofType:@"js"];
    NSString *jsCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [_webView stringByEvaluatingJavaScriptFromString:jsCode];
    
    NSInteger topOffset;
    if ([_viewController isPad]) {
        topOffset = ((NSInteger)[_viewController topBar].frame.size.height) +
        ((NSInteger)[(UIMainView *)[_viewController view] statusBarView].frame.size.height);
    } else {
        topOffset = ((NSInteger)[(UIMainView *)[_viewController view] statusBarView].frame.size.height);
    }
    
    // get the Tags at the touch location
    NSArray *r = [[_webView stringByEvaluatingJavaScriptFromString:
                      [NSString stringWithFormat:@"MyAppGetHTMLElementsAtPoint(%i,%i);",(NSInteger)pt.x,(NSInteger)pt.y - topOffset]] componentsSeparatedByString:@"|"];
    
    NSString *tags = [r objectAtIndex:0];
    NSString *url = [r objectAtIndex:1];
    
    // create the UIActionSheet and populate it with buttons related to the tags
    if ([url isEqualToString:@""]) {
        return;
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[url isEqualToString:@""] ? @"Menu" : url
                                                       delegate:self 
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil 
                                              otherButtonTitles:nil];

    // If a link was touched, add link-related buttons
    if ([tags rangeOfString:@",A,"].location != NSNotFound) {
        [sheet addButtonWithTitle:@"Open Link"];
        [sheet addButtonWithTitle:@"Open Link in New Tab"];
        [sheet addButtonWithTitle:@"Copy Link"];
    }
    // If an image was touched, add image-related buttons
    if ([tags rangeOfString:@",IMG,"].location != NSNotFound) {
        [sheet addButtonWithTitle:@"Save Image"];
    }
    // Add buttons which should be always available
    [sheet addButtonWithTitle:@"Save Page as Bookmark"];
    [sheet addButtonWithTitle:@"Open Page in Safari"];
    
    if ([_viewController isPad]) {
        sheet.cancelButtonIndex = -1;
    } else {
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
    }

    [sheet showInView:_webView];
}

- (CGSize)windowSize
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    CGSize size;
    size.width = [[_webView stringByEvaluatingJavaScriptFromString:@"window.innerWidth"] integerValue];
    size.height = [[_webView stringByEvaluatingJavaScriptFromString:@"window.innerHeight"] integerValue];
    return size;
}

- (CGPoint)scrollOffset
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    CGPoint pt;
    pt.x = [[_webView stringByEvaluatingJavaScriptFromString:@"window.pageXOffset"] integerValue];
    pt.y = [[_webView stringByEvaluatingJavaScriptFromString:@"window.pageYOffset"] integerValue];
    return pt;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    if (buttonIndex == -1) {
        return;
    }
    NSURL *url = [NSURL URLWithString:[actionSheet title]];
    NSString *clickedButton = [actionSheet buttonTitleAtIndex:buttonIndex];
    if ([clickedButton isEqualToString:@"Open Link"]) {
        [_viewController gotoAddress:nil withRequestObj:[[NSURLRequest alloc] initWithURL:url] inTab:self];
    } else if ([clickedButton isEqualToString:@"Open Link in New Tab"]) {
        [_viewController addTabWithAddress:[actionSheet title]];
    } else if ([clickedButton isEqualToString:@"Copy Link"]) {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = [url absoluteString];
        [actionSheet resignFirstResponder];
    } else if ([clickedButton isEqualToString:@"Save Image"]) {
        UIImage *imageToBeSaved = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:url]];
        UIImageWriteToSavedPhotosAlbum(imageToBeSaved, nil, nil, nil);
    } else if ([clickedButton isEqualToString:@"Save Page as Bookmark"]) {
        [[_viewController bookmarksFormController] setDefaultUrlFieldText:[url absoluteString]];
        [_viewController addBookmarkFromSheet:actionSheet];
        [actionSheet resignFirstResponder];
    } else if ([clickedButton isEqualToString:@"Open Page in Safari"]) {
        [actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    _actionSheetVisible = YES;
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    _actionSheetVisible = NO;
}


// HISTORY

-(BOOL) canGoBack {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    return _history.count > 0 && _history_position > 0;
}

-(BOOL) canGoForward {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    return _history.count > 0 && _history_position < _history.count - 1;
}

-(void) goBack {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [self go:-1];
}

-(void) goForward {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [self go:1];
}

-(void) go:(int)t {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    NSURLRequest *req;
    [_viewController forwardButton].enabled = FALSE;
    [_viewController backButton].enabled = FALSE;
    _traverse = t;
    _history_position += _traverse;
    if (_history_position >= [_history count] || _history_position < 0) {
        req = [_history lastObject];
    }
     req = [_history objectAtIndex:_history_position];
    
    //[[viewController addressBar] setText:[[req URL] absoluteString]];
    if (req != nil) {
        [_viewController gotoAddress:nil withRequestObj:req inTab:self];
    }
}

-(void) updateHistory {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (_traverse == 0) {
        if (_history_position + 1 < _history.count) {
            [_history removeObjectsInRange:NSMakeRange(_history_position + 1, _history.count - _history_position - 1)];
        }
        NSURLRequest *req = [[[self urlConnection] currentRequest] mutableCopy];
        
        [_history addObject:req];
        _history_position = _history.count - 1;
    }
    _traverse = 0;
}

- (void)dealloc {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
