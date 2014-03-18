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
#import "UIMainView.h"
#import "BrowserDelegate.h"
#import "Reachability.h"

#import <CoreFoundation/CoreFoundation.h>

typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
} ScrollDirection;

@interface BrowserViewController ()

@end

@implementation BrowserViewController {

    BOOL localWiFiRef;
    SCNetworkReachabilityRef reachabilityRef;
}

@synthesize addressBar, addressBarButtonsView, addressItem, searchItem, activityIndicator, topBar, bottomBar, refreshButton, forwardButton, backButton, navBar, oldAddressText, addTab, selectedTab, tabs, tabsView, webViewTemplate, bookmarksController, bookmarksFormController,  bookmarkButton, bugListNavBar, stopButton,  moreButton, reloadOnPageLoad,  initialPageLoad, progressBar, gotoUrl, contentSize, barItemPopoverPresenter, padPopover, popupQuery,  saveScrollPosition, customButton, customButton2, userAgent;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (nibNameOrNil == nil) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            nibNameOrNil = @"MainWindow";
        } else {
            nibNameOrNil = @"MainWindow-iPad";
        }
    }
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //set background for toolbar in top bar
    if ([self isPad]) {
        UIImage *img = [UIImage imageNamed:@"gray-pixel.png"];
        [bottomBar setBackgroundImage:img forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    }
    
    //size statusbar
    [(UIMainView *)[self view] sizeStatusBar];
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
    
    selectedTab.currentURLString = @"";
    
    [self registerForKeyboardNotifications];
    
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasHidden:)
                                                 name:UIKeyboardDidHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
    if (![self isPad] && [selectedTab currentURL] == nil && ![addressBar isFirstResponder]) {
        [self scrollToTop:aNotification];
        [[selectedTab webView] stringByEvaluatingJavaScriptFromString:@"document.getElementById('contain').style.top = '-15px'"];
    }
}

- (void)keyboardWasHidden:(NSNotification*)aNotification {
    if (![self isPad] && [selectedTab currentURL] == nil && ![addressBar isFirstResponder]) {
        [[selectedTab webView] stringByEvaluatingJavaScriptFromString:@"document.getElementById('contain').style.top = '15%'"];
        [self scrollToTop:aNotification];
    }
}

-(void) saveOpenTabs {
    NSManagedObjectContext *managedObjectContext = [(BrowserDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSError *error;
    int orderCount = 0;
    for (Tab *tab in [self tabs]) {
        NSManagedObject *tabEntity =[NSEntityDescription insertNewObjectForEntityForName:@"Tab" inManagedObjectContext:managedObjectContext];
        [tabEntity setValue:[[tab tabButton] titleForState:UIControlStateNormal] forKey:@"title"];
        [tabEntity setValue:[tab currentURLString] forKey:@"url"];
        [tabEntity setValue:[NSNumber numberWithInteger:orderCount] forKey:@"order"];
        orderCount++;
    }
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error inserting %@ - error:%@",[self tabs],error);
    }
}

-(void) openSavedTabs {
    NSManagedObjectContext *managedObjectContext = [(BrowserDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSError *error = nil;
	NSEntityDescription *tabEntity = [NSEntityDescription entityForName:@"Tab" inManagedObjectContext:managedObjectContext];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"order" ascending:YES];

    [request setEntity:tabEntity];
    [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    NSMutableArray *tabFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    
    for (NSManagedObject *tab in tabFetchResults) {
        [self addTabWithAddress:[tab valueForKey:@"url"]];
        [selectedTab setTitle:[tab valueForKey:@"title"]];
        
        [managedObjectContext deleteObject:tab];
    }
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error deleting %@ - error:%@",tabFetchResults,error);
    }

}

-(void) deleteSavedTabs {
    NSManagedObjectContext *managedObjectContext = [(BrowserDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSError *error = nil;
	NSEntityDescription *tabEntity = [NSEntityDescription entityForName:@"Tab" inManagedObjectContext:managedObjectContext];
    [request setEntity:tabEntity];
    NSMutableArray *tabFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    
    for (NSManagedObject *tab in tabFetchResults) {
        [managedObjectContext deleteObject:tab];
    }
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error deleting %@ - error:%@",tabFetchResults,error);
    }
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //create initial tab
    if ([self.tabs count] == 0) {
        [self addTab:[self addTab]];
    }
	
}

- (void) viewWillAppear:(BOOL)animated {
    //[refreshButton setHidden:YES];
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

-(IBAction)scrollToTop:(id)sender {
    if (![self isPad]) {
        BOOL animated = ![sender isKindOfClass:[NSNotification class]];
        [[[self webView] scrollView] setContentOffset:CGPointMake(0, - topBar.frame.size.height) animated:NO];
        [[[self webView] scrollView] setContentInset:UIEdgeInsetsMake(-[[self webView] scrollView].contentOffset.y, 0, 0, 0)];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    ScrollDirection scrollDirection;
    int minWebViewSize = webViewTemplate.frame.size.height;
    int maxWebViewSize = minWebViewSize + bottomBar.frame.size.height;
    if (self.lastScrollContentOffset > scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionUp;
    else if (self.lastScrollContentOffset < scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionDown;
    
    if (saveScrollPosition) {
        selectedTab.scrollPosition = scrollView.contentOffset.y;
    }
    if(![self isPad]) {
        UIView *statusBarView = [(UIMainView *)self.view statusBarView];
        if (scrollView.contentOffset.y <= -topBar.frame.size.height) {
            // noop
        } else if (scrollView.contentOffset.y < -statusBarView.frame.size.height) {
            [[[self webView] scrollView] setContentInset:UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0)];
        } else {
            [[[self webView] scrollView] setContentInset:UIEdgeInsetsMake(statusBarView.frame.size.height, 0, 0, 0)];
        }
        
        // show bottom toolbar when scrolling up fast
        if (scrollDirection == ScrollDirectionUp && scrollView.contentOffset.y - self.lastScrollContentOffset < -20 && bottomBar.alpha == 0.0) {
                [UIView animateWithDuration: 0.5
                                      delay: 0.0
                                    options: UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     bottomBar.alpha = 1.0;
                                 }
                                 completion:^(BOOL finished){
                                     if (finished) {
                                         [selectedTab webView].frame = CGRectMake([selectedTab webView].frame.origin.x, [selectedTab webView].frame.origin.y, [selectedTab webView].frame.size.width, minWebViewSize);
                                     }
                                 }];
                topBar.frame=CGRectMake(0,0, topBar.frame.size.width, topBar.frame.size.height);
    
            
        } else if (scrollView.contentOffset.y > 0 && scrollView.contentOffset.y + scrollView.frame.size.height < scrollView.contentSize.height) {
            if (scrollDirection == ScrollDirectionDown && bottomBar.alpha == 1.0) {
                [selectedTab webView].frame = CGRectMake([selectedTab webView].frame.origin.x, [selectedTab webView].frame.origin.y, [selectedTab webView].frame.size.width, maxWebViewSize);
                
                [UIView animateWithDuration: 1.0
                                      delay: 0.0
                                    options: UIViewAnimationOptionCurveEaseIn
                                 animations:^{
                                     bottomBar.alpha = 0.0;
                                 }
                                 completion:^(BOOL finished){
                                     if (finished) {
                                     }
                                 }];
            }
        
        // show bottom toolbar
        } else if (bottomBar.alpha == 0.0)  {

            
            [UIView animateWithDuration: 0.5
                                  delay: 0.0
                                options: UIViewAnimationOptionCurveEaseOut
                             animations:^{
                                 bottomBar.alpha = 1.0;
                             }
                             completion:^(BOOL finished){
                                 if (finished) {
                                     [selectedTab webView].frame = CGRectMake([selectedTab webView].frame.origin.x, [selectedTab webView].frame.origin.y, [selectedTab webView].frame.size.width, minWebViewSize);
                                     if (scrollView.contentOffset.y > 0) {
                                         CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - [selectedTab webView].frame.size.height);
                                         [scrollView setContentOffset:bottomOffset animated:NO];
                                     }
                                 }
                             }];

        }
    }
    
    //topbar logic
    if(![self isPad] && scrollView.contentOffset.y>=-topBar.frame.size.height && (scrollView.contentOffset.y <= 0 || scrollDirection == ScrollDirectionDown))
    {
        topBar.frame=CGRectMake(0,-topBar.frame.size.height-scrollView.contentOffset.y, topBar.frame.size.width, topBar.frame.size.height);
    }
    
    self.lastScrollContentOffset = scrollView.contentOffset.y;
}

- (void)showHideView
{
    // Fade out the view right away
    [UIView animateWithDuration:1.0
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         bottomBar.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         // Wait one second and then fade in the view
                         [UIView animateWithDuration:1.0
                                               delay: 1.0
                                             options:UIViewAnimationOptionCurveEaseOut
                                          animations:^{
                                              bottomBar.alpha = 1.0;
                                          }
                                          completion:nil];
                     }];
}



// Web methods

- (void) currentWebViewDidStartLoading:(UIWebView *) webView  {
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

-(void) currentWebViewDidFinishFinalLoad:(UIWebView *) webView {
    [progressBar setProgress:1.0 animated:NO];
    [progressBar setHidden:YES];
    
    [stopButton setHidden:YES];
    
    NSURL *url = [webView.request URL];
    if ([url isFileURL] || [[url absoluteString] isEqualToString:@"about:blank"]) {
        [refreshButton setHidden:YES];
    } else {
        [refreshButton setHidden:NO];
    }
    if (saveScrollPosition && [selectedTab scrollPosition] > 0) {
        [[[self webView] scrollView] setContentOffset:CGPointMake(0, [selectedTab scrollPosition]) animated:NO];
    }
    [self loadTabs:webView];
}

-(void) gotoAddress:(id) sender withRequestObj:(NSURLRequest *)request inTab:(Tab *)tab {
    // Clear detected bugs
    tab.currentURLString = @"";
    [self setInitialPageLoad:YES];
	
    //[whiteView setHidden:NO];
    [[self webView] stopLoading];
    //[[self webView] loadHTMLString:@"<html><head></head><body></body></html>" baseURL:[NSURL URLWithString:@"about:blank" ]];
    
    saveScrollPosition = [[[request URL] host] isEqualToString:@"duckduckgo.com"] || [[[request URL] host] isEqualToString:@"www.duckduckgo.com"];
    
    if (![self isPad]) {
        [self scrollToTop:nil];
    }
	
	[oldAddressText setString:[addressBar text]];
	
	// Load the request in the UIWebView.
    if ([self checkNetworkStatus]) {
        //[[self webView] loadRequest:requestObj];
        
        NSMutableURLRequest *mRequest = [request mutableCopy];
        NSString *d = [self isPad] ? @"iPad" : @"iPhone";
        if (!self.userAgent) {
            self.userAgent = [[tab webView] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        }
        [mRequest setValue:[NSString stringWithFormat:self.userAgent, d] forHTTPHeaderField:@"User-Agent"];
        
        if ( [[[request URL] host] isEqualToString:@"itunes.apple.com"]) {
            [[UIApplication sharedApplication] openURL: mRequest.URL ];
        } else {
            [progressBar setHidden:NO];
            [progressBar setProgress:0.1 animated:NO];
            tab.urlConnection = nil;
            tab.urlConnection = [[NSURLConnection alloc] initWithRequest:mRequest delegate:tab];
            if (sender != refreshButton) {
                [tab updateHistory];
            }
        }
        
        
    } else {
        /*UIAlertView *netAlert = [[UIAlertView alloc] initWithTitle:@"Cannot Open Page"
                                                           message:@"Cannot open page because it is not connected to the internet!"
                                                          delegate:self
                                                 cancelButtonTitle:nil
                                                 otherButtonTitles:@"Okay", nil];

        [netAlert show];*/
        [progressBar setHidden:YES];
        [self cannotConnect:nil];
        
    }
    
    [addressBar resignFirstResponder];
}

-(IBAction) didStartEditingAddressBar:(id)sender {
    if ([[addressBar text] length] > 0) {
        [self performSelector:@selector(selectAllAddressText) withObject:nil afterDelay:0.0];
    }
    [addressBarButtonsView setHidden:YES];
}

-(void) selectAllAddressText {
    [addressBar setSelectedTextRange:[addressBar textRangeFromPosition:addressBar.beginningOfDocument toPosition:addressBar.endOfDocument]];
}

-(IBAction) gotoAddress:(id) sender {
    [addressBarButtonsView setHidden:NO];
    [stopButton setHidden:NO];
    [refreshButton setHidden:YES];
    
    NSString *inputText = [[addressBar text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    gotoUrl = [NSURL URLWithString:inputText];
    if (gotoUrl != nil && (!([[gotoUrl scheme] isEqualToString:@"http"] || [[gotoUrl scheme] isEqualToString:@"https"]))) {
        gotoUrl = [NSURL URLWithString: [@"http://" stringByAppendingString: [gotoUrl absoluteString]]];
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:gotoUrl];
    if ([inputText rangeOfString:@"."].location != NSNotFound && [NSURLConnection canHandleRequest:request]){
        [self gotoAddress:sender withRequestObj:request inTab:selectedTab];
    } else {
        [self searchWeb:sender];
    }
}

-(IBAction) didEndEditingAddressBar:(id)sender {
    
}

-(IBAction) searchWeb:(id) sender {
	NSString *searchQuery = [addressBar text];
    NSString *encodedSearchQuery = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                         NULL,
                                                                                                         (CFStringRef)searchQuery,
                                                                                                         NULL,
                                                                                                         (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                    kCFStringEncodingUTF8 ));
	NSString *urlString = [@"http://www.duckduckgo.com/html/?q=" stringByAppendingString:encodedSearchQuery];
    
    // Load the request in the UIWebView.
    if ([self checkNetworkStatus]) {
        [self gotoAddress:sender withRequestObj:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] inTab:selectedTab];
    } else {
        [self cannotConnect:nil];
        [progressBar setHidden:YES];
        
    }
	//Load the request in the UIWebView.
	[addressBar resignFirstResponder];
}

-(void) cannotConnect:(UIWebView *) cnWebView {
    [stopButton setHidden:NO];
    [refreshButton setHidden:YES];
    NSURL *ucUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"unable_to_connect" ofType:@"html"] isDirectory:NO];
    NSString *ucContentString = [NSString stringWithContentsOfURL:ucUrl encoding:NSUTF8StringEncoding error:nil];
    [[self webView] loadHTMLString:ucContentString baseURL:nil];
}

-(IBAction) goBack:(id)sender {
	
    [selectedTab goBack];
    self.reloadOnPageLoad = YES;
}

-(IBAction) goForward:(id)sender {
	
    [selectedTab goForward];
	//[[self webView] stringByEvaluatingJavaScriptFromString:@"history.forward();"];
}

-(IBAction) cancel:(id)sender {
	//[self contractBar: sender];
}

-(IBAction) showBookmarks:(id)sender {
    [self showBookmarksView:sender];
}

-(void) showBookmarksView:(id)sender {

    [UIView transitionFromView:self.view
                        toView:[bookmarksController view]
                      duration:0.5
                       options:(UIViewAnimationOptionTransitionCrossDissolve)
                    completion:^(BOOL finished) {}];
	
}

-(IBAction) stopLoading:(id)sender {
	[stopButton setHidden:true];
    [refreshButton setHidden:false];
    [progressBar setHidden:YES];
    
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
	// Hide popover for ipad
	if ([self isPad] ) {
        
		if (padPopover.popoverVisible) {
			[padPopover dismissPopoverAnimated:YES];
		}
        
		if (popupQuery.visible || barItemPopoverPresenter == moreButton) {
			barItemPopoverPresenter = nil;
			[popupQuery dismissWithClickedButtonIndex:nil animated:YES];
		} else {
            [self generatePopupQuery];
			barItemPopoverPresenter = moreButton;
			[popupQuery showFromBarButtonItem:moreButton animated:YES];
		}
	} else {
        [self generatePopupQuery];
		[popupQuery showInView:self.view];
	}
}

-(void) generatePopupQuery {
    UIActionSheet *pQuery= [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    for (NSString *button in [self actionSheetButtons]) {
        [pQuery addButtonWithTitle:button];
    }
    
    pQuery.cancelButtonIndex = [pQuery addButtonWithTitle:@"Cancel"];
    
    self.popupQuery = pQuery;
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    // skip add bookmarks if we are loading a local file
    if ([[[selectedTab webView] request].URL isFileURL]) {
        buttonIndex += 1;
    }
    // Add Bookmark
	if (buttonIndex == 0) {
        [self addBookmarkFromSheet:actionSheet];
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
        [[self webView] loadData:launchData MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:nil];
        [addressBar setText:urlAddress];
    }

}

-(void) addBookmarkFromSheet:(UIActionSheet *) sheet {
    [sheet dismissWithClickedButtonIndex:0 animated:YES];
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
                          duration:0.5
                           options:(UIViewAnimationOptionTransitionCrossDissolve)
                        completion:^(BOOL finished) {}];
    }
}

// TABS

-(IBAction) addTab:(id)sender {
    if (tabsView.hidden) {
        [self toggleTabsView:sender];
    }
    [self addTabWithAddress:@""];
}

-(void) addTabWithAddress:(NSString *)urlAddress {

	if ([tabs count] == 0) {
		tabs = [[NSMutableArray alloc] initWithCapacity:8];
	}
	// reset navbar
	//[self contractBar:sender];
    /*if (!stopButton.hidden) {
     [self stopLoading:sender];
     }*/
	
    Tab *nTab = [[Tab alloc] initWithFrame:CGRectMake((100.0 * [tabs count]) + 2.0, 2.0, 100.0, 34.0) addTarget: self];
    
	[self switchTabFrom:selectedTab ToTab:nTab];
	[tabsView addSubview:selectedTab];
	
	[tabs addObject:selectedTab];
	[selectedTab select];
	
	//scrolling
	tabsView.contentSize = CGSizeMake(((100.0) * [tabs count]) + 5.0, 23.0);
    if (tabsView.frame.size.width < tabsView.contentSize.width) {
        tabsView.contentOffset = CGPointMake(tabsView.contentSize.width - tabsView.frame.size.width,0);
    }
    
	tabsView.clipsToBounds = YES;
	tabsView.showsHorizontalScrollIndicator = NO;
	
    if ([urlAddress isEqualToString:@""]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"launch" ofType:@"html"];
        NSData *launchData = [NSData dataWithContentsOfFile:path];
        [[self webView] loadData:launchData MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:nil];
        if (![addressBar isFirstResponder])  {
            [addressBar setText:urlAddress];
        }
        
    } else {
        [self gotoAddress:nil withRequestObj:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlAddress]] inTab:selectedTab];
    }
    
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
	
	
	if ([tabs count] == 0) {
		[self addTab:nil];
	}
	[self loadTabs:[selectedTab webView]];
	
	//scrolling
	tabsView.contentSize = CGSizeMake(((100.0) * [tabs count]) + 40.0, 23.0);
}

-(IBAction) selectTab:(id)sender {
	for (id cTab in tabs) {
		if ([cTab tabButton] == sender) {
			[self switchTabFrom:selectedTab ToTab:cTab];
		}
	}
	[self loadTabs:[selectedTab webView]];
}

-(void) switchTabFrom:(Tab *)fromTab ToTab:(Tab *)toTab {
	if ([tabs count] > 0) {
		[fromTab deselect];

	}
	[toTab select];
	selectedTab = toTab;
    if (![toTab loading]) {
        [[self progressBar] setHidden:YES];
        [[self stopButton] setHidden:YES];
        [[self refreshButton] setHidden:NO];
        [[self addressBar] setText:[selectedTab currentURLString]];
    } else {
        [[self progressBar] setHidden:NO];
        [[self stopButton] setHidden:NO];
        [[self refreshButton] setHidden:YES];
    }

}

/*-(IBAction) toggleTabsView:(id)sender {
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

            progressBar.frame = CGRectMake(progressBar.frame.origin.x,
                                           progressBar.frame.origin.y + tabsView.bounds.size.height,
                                           progressBar.frame.size.width,
                                           progressBar.frame.size.height);
            tabsView.hidden = NO;
            addTab.hidden = NO;
        } else {
            addTab.hidden = YES;
            tabsView.hidden = YES;

            progressBar.frame = CGRectMake(progressBar.frame.origin.x,
                                           progressBar.frame.origin.y - tabsView.bounds.size.height,
                                           progressBar.frame.size.width,
                                           progressBar.frame.size.height);
        }
        
        [[[self webView] scrollView] setContentInset:UIEdgeInsetsMake(topBar.frame.size.height, 0, 0, 0)];
        [[[self webView] scrollView] setContentOffset:CGPointMake(0, - topBar.frame.size.height) animated:YES];
    }
    
}*/

// WEBVIEW

-(UIWebView *) webView {
    return [selectedTab webView];
}

-(UIWebView *) setWebView:(UIWebView *)newWebView {
	[selectedTab setWebView:newWebView];
	return newWebView;
}


-(void) loadTabs:(UIWebView *)webView {
    Tab *tab = nil;
	
    [[self view] sendSubviewToBack:webView];
    
	for (id cTab in tabs) {
		if ([cTab webView] == webView) {
			tab = cTab;
		} else {
            [[self view] sendSubviewToBack:[cTab webView]];
        }
	}
	
	if (tab == selectedTab) {
        if ([webView request] == nil || [[webView request].URL isFileURL]) {
            if (![addressBar isFirstResponder]) {
                [addressBar setText: @""];
            }
            
        } else {
            NSString *addressText = tab.currentURLString;
            if (![addressText isEqualToString:@"about:blank"] && [addressText rangeOfString:@"https://duckduckgo.com"].location == NSNotFound) {
                if (![addressBar isFirstResponder]) {
                    [addressBar setText: addressText];
                }
                [refreshButton setHidden:[tab loading]];
            }
            
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
}


// Orientation

- (NSUInteger) supportedInterfaceOrientations {
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskAll;
    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    // Return the orientation you'd prefer - this is what it launches to. The
    // user can still rotate. You don't have to implement this method, in which
    // case it launches in the current orientation
    return UIDeviceOrientationPortrait;
}


// Reachability
- (BOOL) checkNetworkStatus
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus *netstat = [reachability currentReachabilityStatus];
    return netstat != NotReachable;
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
