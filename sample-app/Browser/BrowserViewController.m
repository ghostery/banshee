//
//  BrowserViewController.m
//
//  Created by Alexandru Catighera on 3/5/13.
//
//

#import "BrowserViewController.h"
#import "Tab.h"
#import "BookmarksController.h"
#import "BookmarksFormController.h"
#import "BookmarkFolderFormController.h"

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>

@interface BrowserViewController ()

@end

@implementation BrowserViewController

@synthesize addressBar, searchBar, addressItem, searchItem, activityIndicator, topBar, refreshButton, forwardButton, backButton, navBar, oldAddressText, addTab, selectedTab, tabs, tabsView, webViewTemplate, bookmarksController, bookmarksFormController,  bookmarkButton, bugListNavBar, stopButton,  moreButton, reloadOnPageLoad,  initialPageLoad, pageData, progressBar, urlConnection, gotoUrl, contentSize, response, barItemPopoverPresenter, padPopover, popupQuery,  saveScrollPosition, currentURLString, customButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Set up bookmark controllers
	BookmarksFormController *bookmarksFormController = [[BookmarksFormController alloc]
                                                        initWithNibName:@"BookmarksForm"
                                                        bundle:[NSBundle mainBundle]];
	BookmarkFolderFormController *bookmarkFolderFormController = [[BookmarkFolderFormController alloc]
																  initWithNibName:@"BookmarkFoldersForm"
																  bundle:[NSBundle mainBundle]];
	
	BookmarksController *bookmarksController = [[BookmarksController alloc] initWithNibName:@"Bookmarks" bundle:[NSBundle mainBundle]];
	UINavigationController *bookmarksNavController = [[UINavigationController alloc] initWithRootViewController:bookmarksController];
	
	[self setBookmarksFormController:bookmarksFormController];
	[bookmarksController setBrowserController:self];
	[bookmarkFolderFormController setBookmarksController:bookmarksController];
	[bookmarksController setFolderController:bookmarkFolderFormController];
	[self setBookmarksController:bookmarksNavController];
    
    // Tweak address bar view so text doesn't overflow
    UIView *addressBarStatusView = [[ UIView  alloc ]  initWithFrame:
									CGRectMake(0.0, 0.0, 23.0, 10.0)];
	[self.addressBar setRightView: addressBarStatusView];
	[self.addressBar setRightViewMode: UITextFieldViewModeUnlessEditing];
	self.oldAddressText = [NSMutableString stringWithString:@""];
    
    self.currentURLString = @"";
    
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //create initial tab
    if ([self.tabs count] == 0) {
        [self addTab:[self addTab]];
    }
	
}

- (void) viewWillAppear:(BOOL)animated {
    [moreButton setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIFont fontWithName:@"Helvetica-Bold" size:29.0], UITextAttributeFont,nil] forState:UIControlStateNormal];
    [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
	[self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Scrolling

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    
    if (saveScrollPosition) {
        selectedTab.scrollPosition = scrollView.contentOffset.y;
        //NSLog(@"search scroll: %i", selectedTab.scrollPosition);
        
    }
    
    if(![self isPad] && scrollView.contentOffset.y>=-topBar.frame.size.height)
    {
        topBar.frame=CGRectMake(0,-topBar.frame.size.height-scrollView.contentOffset.y, topBar.frame.size.width, topBar.frame.size.height);
    }
}

// Web methods

-(void) gotoAddress:(id) sender withRequestObj:(NSURLRequest *) request {
    // Clear detected bugs
    self.currentURLString = @"";
	[[selectedTab detectedBugArray] removeAllObjects];
    [self setInitialPageLoad:YES];
	
    //[whiteView setHidden:NO];
    [[self webView] stopLoading];
    //[[self webView] loadHTMLString:@"<html><head></head><body></body></html>" baseURL:[NSURL URLWithString:@"about:blank" ]];
    
    saveScrollPosition = [[[request URL] host] isEqualToString:@"duckduckgo.com"] || [[[request URL] host] isEqualToString:@"www.duckduckgo.com"];
    
    if (![self isPad]) {
        [[[self webView] scrollView] setContentOffset:CGPointMake(0, - topBar.frame.size.height) animated:YES];
    }
	
	[oldAddressText setString:[addressBar text]];
	
	// Load the request in the UIWebView.
    if ([self checkNetworkStatus]) {
        //[[self webView] loadRequest:requestObj];
        
        NSMutableURLRequest *mRequest = [request mutableCopy];
        NSString *d = [self isPad] ? @"iPad" : @"iPhone";
        [mRequest setValue:[NSString stringWithFormat:@"iOS AppleWebKit Mobile %@", d] forHTTPHeaderField:@"User-Agent"];
        
        if ( [[[request URL] host] isEqualToString:@"itunes.apple.com"]) {
            [[UIApplication sharedApplication] openURL: mRequest.URL ];
        } else {
            [progressBar setHidden:NO];
            [progressBar setProgress:0.1 animated:NO];
            urlConnection = nil;
            urlConnection = [[NSURLConnection alloc] initWithRequest:mRequest delegate:self];
            if (sender != refreshButton) {
                [selectedTab updateHistory];
            }
        }
        
        
    } else {
        UIAlertView *netAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Open Page"
                                                           message:@"Cannot open page because it is not connected to the internet!"
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:@"Okay", nil];
        [netAlert show];
        
    }
    
    [addressBar resignFirstResponder];
}

-(IBAction) gotoAddress:(id) sender {
    gotoUrl = [NSURL URLWithString:[addressBar text]];
	if (!([[gotoUrl scheme] isEqualToString:@"http"] || [[gotoUrl scheme] isEqualToString:@"https"])) {
		gotoUrl = [NSURL URLWithString: [@"http://" stringByAppendingString: [gotoUrl absoluteString]]];
	}
    [self gotoAddress:sender withRequestObj:[NSURLRequest requestWithURL:gotoUrl]];
}

-(IBAction) searchWeb:(id) sender {
	NSString *searchQuery = [searchBar text];
    NSString *encodedSearchQuery = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                         NULL,
                                                                                                         (CFStringRef)searchQuery,
                                                                                                         NULL,
                                                                                                         (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                    kCFStringEncodingUTF8 ));
	NSString *urlString = [@"http://www.duckduckgo.com/html/?q=" stringByAppendingString:encodedSearchQuery];
	
	[addressBar	setText: urlString];
    
    // Clear detected bugs
	[[selectedTab detectedBugArray] removeAllObjects];
    
    // Load the request in the UIWebView.
    if ([self checkNetworkStatus]) {
        [self gotoAddress:sender];
    } else {
        UIAlertView *netAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Open Page"
                                                           message:@"Cannot open page because it is not connected to the internet!"
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:@"Okay", nil];
        [netAlert show];
        
    }
	//Load the request in the UIWebView.
	[addressBar resignFirstResponder];
}

-(IBAction) goBack:(id)sender {
	// Clear detected bugs
	[[selectedTab detectedBugArray] removeAllObjects];
	
    [selectedTab goBack];
    self.reloadOnPageLoad = YES;
}

-(IBAction) goForward:(id)sender {
	// Clear detected bugs
	[[selectedTab detectedBugArray] removeAllObjects];
	
    [selectedTab goForward];
	//[[self webView] stringByEvaluatingJavaScriptFromString:@"history.forward();"];
}

-(IBAction) expandURLBar:(id)sender {
	if ([self webView].loading) {
		[self stopLoading:sender];
	}
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	NSArray *items = [NSArray arrayWithObjects: addressItem, cancelButton, nil];
	
	[navBar setItems: items animated: YES];
	addressItem.width = 230;
	[addressBar sizeToFit];
	[refreshButton setHidden:true];
}

-(IBAction) expandSearchBar:(id)sender {
	if ([self webView].loading) {
		[self stopLoading:sender];
	}
	UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	NSArray *items = [NSArray arrayWithObjects: searchItem, cancelButton, nil];
	
	[navBar setItems: items animated: YES];
	searchItem.width = 230;
	[searchBar sizeToFit];
	[refreshButton setHidden:true];
}

-(IBAction) contractBar:(id)sender {
	
    if ([[navBar items] objectAtIndex:1] != sender && ![searchBar isHidden]) {
        [addressBar setText:oldAddressText];
    }
    
    [searchBar setHidden:false];
	[navBar setItems: [NSArray arrayWithObjects:addressItem, searchItem, nil] animated: YES];
	
	addressItem.width = 214;
	searchItem.width = 74;
    
    if ([[self urlConnection] currentRequest] != nil && !([tabs count] == 0 || [[[[self webView] request] URL] isFileURL])) {
        [refreshButton setHidden:false];
    }
	
	[addressBar resignFirstResponder];
	[searchBar resignFirstResponder];
	[addressBar sizeToFit];
	[searchBar sizeToFit];
}

-(IBAction) cancel:(id)sender {
	[self contractBar: sender];
}

-(IBAction) showBookmarks:(id)sender {
    [self showBookmarksView:sender];
}

-(IBAction) customButtonClick:(id)sender {
    //noop, implement in subclass
}

-(void) showBookmarksView:(id)sender {

    [UIView transitionFromView:self.view
                        toView:[bookmarksController view]
                      duration:1.0
                       options:(UIViewAnimationOptionTransitionCurlDown)
                    completion:^(BOOL finished) {}];
	
}

-(IBAction) stopLoading:(id)sender {
	[stopButton setHidden:true];
    [refreshButton setHidden:false];
    
	//[activityIndicator stopAnimating];
    if ([tabs count] > 0) {        
        [[selectedTab webView] stopLoading];
    }
}

-(NSArray *) actionSheetButtons {
    // hide add bookmark for local html files
    if ([[[selectedTab webView] request].URL isFileURL]) {
        return [NSArray arrayWithObjects:@"Clear Cookies", @"Clear Cache", @"Import Bookmarks", nil];
    } else {
        return [NSArray arrayWithObjects:@"Add Bookmark", @"Clear Cookies", @"Clear Cache", @"Import Bookmarks", nil];
    }
}

-(IBAction)showActionSheet:(id)sender {
    //self.popupQuery = nil;
    UIActionSheet *pQuery= [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    for (NSString *button in [self actionSheetButtons]) {
        [pQuery addButtonWithTitle:button];
    }
    
    pQuery.cancelButtonIndex = [pQuery addButtonWithTitle:@"Cancel Button"];
    
    self.popupQuery = pQuery;
	// Hide popover for ipad
	if ([self isPad] ) {
        
		if (padPopover.popoverVisible) {
			[padPopover dismissPopoverAnimated:YES];
		}
        
		if (popupQuery.visible || barItemPopoverPresenter == moreButton) {
			barItemPopoverPresenter = nil;
			[popupQuery dismissWithClickedButtonIndex:0 animated:YES];
		} else {
			barItemPopoverPresenter = moreButton;
			[popupQuery showFromBarButtonItem:moreButton animated:YES];
		}
	} else {
		[popupQuery showInView:self.view];
	}
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // skip add bookmarks if we are loading a local file
    if ([[[selectedTab webView] request].URL isFileURL]) {
        buttonIndex += 1;
    }
    // Add Bookmark
	if (buttonIndex == 0) {
        [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
		[bookmarksFormController setMode:'A'];
		[[bookmarksFormController navigationItem] setHidesBackButton:YES animated:NO];
		[bookmarksController pushViewController:bookmarksFormController animated:NO];
		if ([self isPad]) {
			if (padPopover == nil) {
                UIPopoverController *ppop = [[UIPopoverController alloc]
                                             initWithContentViewController:bookmarksController];
                self.padPopover = ppop;
                
			} else {
				[self.padPopover setContentViewController:bookmarksController animated:YES];
			}
			[self.padPopover presentPopoverFromBarButtonItem: bookmarkButton
									permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
			
		} else {
			[UIView transitionFromView:self.view
								toView:[bookmarksController view]
							  duration:1.0
							   options:(UIViewAnimationOptionTransitionCurlDown)
							completion:^(BOOL finished) {}];
		}
    }
    
    // Clear Cookies
    else if (buttonIndex == 1) {
        NSHTTPCookie *cookie;
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (cookie in [storage cookies]) {
            [storage deleteCookie:cookie];
        }
    }
    
    // Clear Cache
    else if (buttonIndex == 2) {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
    
    
    // Import Bookmarks
    else if (buttonIndex == 3) {
        [self addTab:actionSheet];
        NSString *urlAddress = @"";
        //[[self webView] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"import_bookmark_howto" ofType:@"html"]isDirectory:NO]]];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"import_bookmark_howto" ofType:@"html"];
        NSData *launchData = [NSData dataWithContentsOfFile:path];
        [[self webView] loadData:launchData MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:[NSURL fileURLWithPath:path]];
        [addressBar setText:urlAddress];
    }

}

// TABS

-(IBAction) addTab:(id)sender {
    if (tabsView.hidden) {
        [self toggleTabsView:sender];
    }
	if ([tabs count] == 0) {
		tabs = [[NSMutableArray alloc] initWithCapacity:8];
	}
	// reset navbar
	[self contractBar:sender];
	[self stopLoading:sender];
	
    Tab *nTab = [[Tab alloc] initWithFrame:CGRectMake((100.0 * [tabs count]) + 2.0, 2.0, 100.0, 34.0) addTarget: self];
    
	[self switchTabFrom:selectedTab ToTab:nTab];
	[tabsView addSubview:selectedTab];
	
	[tabs addObject:selectedTab];
	[selectedTab select];
	addTab.frame = CGRectOffset(addTab.frame, 100.0, 0.0);
	
	//scrolling
	tabsView.contentSize = CGSizeMake(((100.0 + 2.0) * [tabs count]) + 40.0, 23.0);
	tabsView.clipsToBounds = YES;
	tabsView.showsHorizontalScrollIndicator = NO;
	
    NSString *urlAddress = @"";
    //[[self webView] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"launch" ofType:@"html"]isDirectory:NO]]];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"launch" ofType:@"html"];
    NSData *launchData = [NSData dataWithContentsOfFile:path];
    [[self webView] loadData:launchData MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:[NSURL fileURLWithPath:path]];
    [addressBar setText:urlAddress];
    
	[self loadTabs:[selectedTab webView]];
    
}

-(IBAction) removeTab:(id)sender {
	[sender setEnabled:NO];
	Tab *toBeRemoved = (Tab *)[sender superview];
	[[toBeRemoved tabButton] setEnabled:NO];
	
	BOOL removed = false;
	BOOL select = false;
	
	for (id cTab in tabs) {
		if (select) {
			[self switchTabFrom:selectedTab ToTab:cTab];
			select = false;
		}
		if (removed) {
			[cTab incrementOffset];
		}
		if ([cTab closeButton] == sender) {
			removed = YES;
			select = (selectedTab == cTab);
		}
        
	}
    
	if (toBeRemoved == [tabs lastObject] && [tabs lastObject] != [NSNull null] && [tabs count] > 1) {
		[self switchTabFrom:selectedTab ToTab:[tabs objectAtIndex:[tabs count]-2]];
	} else if ([tabs count] == 0) {
        self.webView = nil;
    }
	[toBeRemoved removeFromSuperview];
	[[toBeRemoved webView] removeFromSuperview];
	[tabs removeObject: toBeRemoved];
	
	
	addTab.frame = CGRectOffset(addTab.frame, -100.0, 0.0);
	if ([tabs count] == 0) {
		[self addTab:nil];
	}
	[self loadTabs:[selectedTab webView]];
	
	//scrolling
	tabsView.contentSize = CGSizeMake(((100.0 + 2.0) * [tabs count]) + 40.0, 23.0);
}

-(IBAction) selectTab:(id)sender {
	for (id cTab in tabs) {
		if ([cTab tabButton] == sender) {
			[self switchTabFrom:selectedTab ToTab:cTab];
		}
	}
	// set address bar
    if ([[[selectedTab webView] request].URL isFileURL]) {
        [addressBar setText:@""];
    } else {
        [addressBar setText:[selectedTab webView].request.URL.absoluteString];
    }
	[self loadTabs:[selectedTab webView]];
}

-(void) switchTabFrom:(Tab *)fromTab ToTab:(Tab *)toTab {
	if ([tabs count] > 0) {
		[fromTab deselect];
	}
	[toTab select];
	selectedTab = toTab;
}

-(IBAction) toggleTabsView:(id)sender {
    if ([self isPad]) {
        if (tabsView.hidden) {
            [self webView].frame = CGRectMake([self webView].frame.origin.x,
                                              [self webView].frame.origin.y + tabsView.bounds.size.height,
                                              [self webView].bounds.size.width,
                                              [self webView].bounds.size.height - tabsView.bounds.size.height);
            progressBar.frame = CGRectMake(progressBar.frame.origin.x,
                                           progressBar.frame.origin.y + tabsView.bounds.size.height,
                                           progressBar.frame.size.width,
                                           progressBar.frame.size.height);
            tabsView.hidden = NO;
        } else {
            [self webView].frame = CGRectMake([self webView].frame.origin.x,
                                              [self webView].frame.origin.y - tabsView.bounds.size.height,
                                              [self webView].bounds.size.width,
                                              [self webView].bounds.size.height + tabsView.bounds.size.height);
            progressBar.frame = CGRectMake(progressBar.frame.origin.x,
                                           progressBar.frame.origin.y - tabsView.bounds.size.height,
                                           progressBar.frame.size.width,
                                           progressBar.frame.size.height);
            tabsView.hidden = YES;
        }
    } else {
        if (tabsView.hidden) {
            topBar.frame = CGRectMake(topBar.frame.origin.x,
                                      topBar.frame.origin.y ,
                                      topBar.bounds.size.width,
                                      topBar.bounds.size.height + tabsView.bounds.size.height);
            progressBar.frame = CGRectMake(progressBar.frame.origin.x,
                                           progressBar.frame.origin.y + tabsView.bounds.size.height,
                                           progressBar.frame.size.width,
                                           progressBar.frame.size.height);
            tabsView.hidden = NO;
        } else {
            tabsView.hidden = YES;
            topBar.frame = CGRectMake(topBar.frame.origin.x,
                                      topBar.frame.origin.y ,
                                      topBar.bounds.size.width,
                                      topBar.bounds.size.height - tabsView.bounds.size.height);
            progressBar.frame = CGRectMake(progressBar.frame.origin.x,
                                           progressBar.frame.origin.y - tabsView.bounds.size.height,
                                           progressBar.frame.size.width,
                                           progressBar.frame.size.height);
        }
        
        [[[self webView] scrollView] setContentInset:UIEdgeInsetsMake(topBar.frame.size.height, 0, 0, 0)];
        [[[self webView] scrollView] setContentOffset:CGPointMake(0, - topBar.frame.size.height) animated:YES];
    }
    
}

// CONNECTION
#pragma mark -
#pragma mark urlConnection delegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    if (redirectResponse) {
        NSMutableURLRequest *r = [[connection currentRequest] mutableCopy]; // original request
        [r setURL: [request URL]];
        self.currentURLString = [[request URL] absoluteString];
        return r;
    } else {
        return request;
    }
}

- (void)connection: (NSURLConnection*) connection didReceiveResponse: (NSHTTPURLResponse*) response
{
    self.currentURLString = [[response URL] absoluteString];
    [self setResponse:response];
    [progressBar setProgress:0.25 animated:NO];
    pageData = [[NSMutableData alloc] initWithLength:0];
}

- (void) connection: (NSURLConnection*) connection didReceiveData: (NSData*) data
{
    [pageData appendData: data];
    if ([progressBar progress] < 0.75) {
        [progressBar setProgress:[progressBar progress] + .05 animated:NO];
    }
    // Broadcast a notification with the progress change, or call a delegate
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([pageData length] == 0) {
        [[[self selectedTab] history] removeObjectAtIndex:[[[self selectedTab] history] count] - 1];
        self.currentURLString = [[[[[self selectedTab] history] lastObject] URL] absoluteString];
        [addressBar setText:self.currentURLString];
        [progressBar setHidden:YES];
        return;
    }
    if ([[response MIMEType] isEqualToString:@"text/html"] || [[response MIMEType] isEqualToString:@"application/xhtml+xml"] || [[response MIMEType] isEqualToString:@"text/vnd.wap.wml"]) {
        NSStringEncoding *enc;
        if ([response textEncodingName] != nil) {
            enc = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[response textEncodingName]));
        } else {
            enc = NSUTF8StringEncoding;
        }
        NSString *page = (NSString *)[[NSString alloc] initWithData:pageData encoding:enc];
        
        [self loadPageString:page];

    } else {
        [[self webView] stopLoading];
        [[self webView] loadData:pageData MIMEType:[response MIMEType] textEncodingName:[response textEncodingName] baseURL:[response URL]];
        //[whiteView setHidden:YES];
        [progressBar setHidden:YES];
    }
    
    [progressBar setProgress:0.75 animated:NO];
    pageData = nil;
    
}

-(void) loadPageString:(NSString *)page {
    [[self webView] stopLoading];
    [[self webView] loadHTMLString:page baseURL:[response URL]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    UIAlertView *netAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Open Page"
                                                       message:[error localizedDescription]
                                                      delegate:self
                                             cancelButtonTitle:nil
                                             otherButtonTitles:@"Okay", nil];
    [netAlert show];
    
    NSString *urlAddress = @"";
    [[self webView] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"launch" ofType:@"html"]isDirectory:NO]]];
    [addressBar setText:urlAddress];
}

// WEBVIEW

-(UIWebView *) webView {
    return [selectedTab webView];
}

-(UIWebView *) setWebView:(UIWebView *)newWebView {
	[selectedTab setWebView:newWebView];
	return newWebView;
}

#pragma mark -
#pragma mark webview delegate

-(BOOL) webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (request == nil) {
        return NO;
    }
    
    // CAPTURE PAGE LOAD
    if ([[[request URL] absoluteString] isEqualToString:@"js:gh-page-loaded"]) {
        [self webViewDidFinishFinalLoad:webView];
    }
    
	//CAPTURE USER LINK-CLICK.
	if (navigationType == UIWebViewNavigationTypeLinkClicked || navigationType == UIWebViewNavigationTypeFormSubmitted) {
		NSURL *URL = [request URL];
		if ([[URL scheme] isEqualToString:@"http"] || [[URL scheme] isEqualToString:@"https"]) {
			[addressBar setText:[URL absoluteString]];
			[self gotoAddress:nil withRequestObj:request];
		}
		return NO;
	}
	return YES;
}

-(void) webViewDidStartLoad:(UIWebView *)webView {
    
    if (!initialPageLoad) {
        //[whiteView setHidden:YES];
    }
    if (addressBar.editing) {
        [webView stopLoading];
        return;
    }
    
    
	Tab *tab = nil;
	for (id cTab in tabs) {
		if ([cTab webView] == webView) {
			tab = cTab;
		}
	}
	if (tab == selectedTab) {
		
		if (initialPageLoad) {
            [refreshButton setHidden:true];
            [stopButton setHidden:false];
        }
        
	}
    if (progressBar.progress < 0.95) {
        [progressBar setProgress: progressBar.progress + 0.05];
    }
    [self setInitialPageLoad:NO];
    
}

-(void) webViewDidFinishFinalLoad:(UIWebView *)webView {
    [progressBar setProgress:1.0 animated:NO];
    [progressBar setHidden:YES];
    //[whiteView setHidden:YES];
    if (saveScrollPosition && [selectedTab scrollPosition] > 0) {
        [[[self webView] scrollView] setContentOffset:CGPointMake(0, [selectedTab scrollPosition]) animated:NO];
    }
    [self loadTabs:webView];
}

-(void) webViewDidFinishLoad:(UIWebView *)webView {
    
    
    if (![[[webView request] URL] isFileURL]) {
        [webView stringByEvaluatingJavaScriptFromString:@"if (document.getElementById('gh-page-loaded') == null && document.documentElement.innerHTML != '<head></head><body></body>') {"
         "var iframe = document.createElement('IFRAME');"
         "iframe.setAttribute('id','gh-page-loaded');"
         "iframe.setAttribute('src', 'js:gh-page-loaded');"
         "document.body.appendChild(iframe);"
         "iframe.parentNode.removeChild(iframe);"
         "iframe = null;}" ];
    }
}

-(void) loadTabs:(UIWebView *)webView {
    Tab *tab = nil;
	
    [[self view] sendSubviewToBack:webView];
    
	//[activityIndicator stopAnimating];
	[stopButton setHidden:true];
    if ([webView request] == nil || [[webView request].URL isFileURL]) {
        [refreshButton setHidden:true];
    } else {
        [refreshButton setHidden:false];
    }
    
	for (id cTab in tabs) {
		if ([cTab webView] == webView) {
			tab = cTab;
		} else {
            [[self view] sendSubviewToBack:[cTab webView]];
        }
	}
	
	if (tab == selectedTab) {
        if ([webView request] == nil || [[webView request].URL isFileURL]) {
            [addressBar setText: @""];
        } else {
            [addressBar setText: [[[selectedTab webView] request].URL absoluteString]];
            
        }
        
		if([selectedTab canGoForward]) {
			forwardButton.enabled = TRUE;
		}
		else if(![selectedTab canGoForward]) {
			forwardButton.enabled = FALSE;
		}
		if([selectedTab canGoBack]) {
			backButton.enabled = TRUE;
		}
		else if(![selectedTab canGoBack]) {
			backButton.enabled = FALSE;
		}
        
	}
    // Set title
    //[tab showText];
	NSString *tabTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
	NSString *url = [webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
	if ((tab != nil) && (![url isEqualToString:@"about:blank"])) {
		if ([tabTitle length] == 0) {
			[tab setTitle:@"Untitled"];
		} else {
			[tab setTitle:tabTitle];
		}
	}
}


// Orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}


// Reachability
- (BOOL) checkNetworkStatus
{
    // called after network status changes
    
    struct sockaddr_in zeroAddress;
	bzero(&zeroAddress, sizeof(zeroAddress));
	zeroAddress.sin_len = sizeof(zeroAddress);
	zeroAddress.sin_family = AF_INET;
    
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*)&zeroAddress);
    
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reachability, &flags)) {
        if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
            NSLog(@"The internet is down.");
            return NO;
        }
        if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
            NSLog(@"The internet is working via WIFI.");
            return YES;
        }
        
        if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
            
			if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
                NSLog(@"The internet is working via WIFI.");
                return YES;
            }
        }
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
            NSLog(@"The internet is working via WWAN.");
            return YES;
        }
	}
    return YES;
}

// HARDWARE
- (BOOL) isPad {
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}



@end
