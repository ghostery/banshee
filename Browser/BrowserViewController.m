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
#import "Reachability.h"
#import "Logging.h"

#import <CoreFoundation/CoreFoundation.h>

typedef enum ScrollDirection {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
} ScrollDirection;

@interface BrowserViewController () {
    
    BOOL localWiFiRef;
    SCNetworkReachabilityRef reachabilityRef;
}

@end

@implementation BrowserViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
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

- (id)initWithCoder:(NSCoder *)aDecoder{
    if ((self = [super initWithCoder:aDecoder])){
        NSString *nibNameOrNil;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            nibNameOrNil = @"MainWindow";
        } else {
            nibNameOrNil = @"MainWindow-iPad";
        }
        
        [self setView:
         [[[NSBundle mainBundle] loadNibNamed:nibNameOrNil
                                        owner:self
                                      options:nil] objectAtIndex:0]];
    }
    return self;
}

- (void)viewDidLoad
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [super viewDidLoad];
    
    //set background for toolbar in top bar
    if ([self isPad]) {
        UIImage *img = [UIImage imageNamed:@"gray-pixel.png"];
        [_bottomBar setBackgroundImage:img forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    }
    
    //size statusbar
    [(UIMainView *)[self view] sizeStatusBar];
    // Set up bookmark controllers
    [self createBookmarksController:YES];
    [self.view addSubview:self.bookmarksNavController.view];
    self.bookmarksNavController.view.alpha = 0.0f; //Hide the bookmarks controller
    
    // Tweak address bar view so text doesn't overflow
    UIView *addressBarStatusView = [[ UIView  alloc ]  initWithFrame:
									CGRectMake(0.0, 0.0, 23.0, 10.0)];
	[self.addressBar setRightView: addressBarStatusView];
	[self.addressBar setRightViewMode: UITextFieldViewModeUnlessEditing];
	self.oldAddressText = [NSMutableString stringWithString:@""];
    
    _selectedTab.currentURLString = @"";
    
    [self registerForKeyboardNotifications];
    [self registerForBrowserNotifications];
}

- (UINavigationController *)createBookmarksController:(BOOL)isMainController {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    BookmarksFormController *bookmarksFormController = [[BookmarksFormController alloc]
                                                        initWithNibName:@"BookmarksForm"
                                                        bundle:[NSBundle mainBundle]];
    [bookmarksFormController setBrowserController:self];
	BookmarkFolderFormController *bookmarkFolderFormController = [[BookmarkFolderFormController alloc]
																  initWithNibName:@"BookmarkFoldersForm"
																  bundle:[NSBundle mainBundle]];
	BookmarksController *bookmarksController = [[BookmarksController alloc] initWithNibName:@"Bookmarks" bundle:[NSBundle mainBundle]];
	UINavigationController *bookmarksNavController = [[UINavigationController alloc] initWithRootViewController:bookmarksController];
	[bookmarksController setBrowserController:self];
	[bookmarkFolderFormController setBookmarksController:bookmarksController];
	[bookmarksController setFolderController:bookmarkFolderFormController];
    if(isMainController) //Creating the main bookmarks page which persists by hiding/unhiding
    {
        [self setBookmarksNavController:bookmarksNavController];
        [self setBookmarksFormController:bookmarksFormController];
    }
    else //Creating a temporary bookmark controller for the popup with a form controller on the top of the nav stack
    {
        [bookmarksNavController pushViewController:bookmarksFormController animated:NO];
    }
    return bookmarksNavController;
}

- (void)registerForKeyboardNotifications
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasHidden:)
                                                 name:UIKeyboardDidHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (![self isPad] && [_selectedTab currentURL] == nil && ![_addressBar isFirstResponder]) {
        [self scrollToTop:aNotification];
        [[_selectedTab webView] stringByEvaluatingJavaScriptFromString:@"document.getElementById('contain').style.top = '-15px'"];
    }
}

- (void)keyboardWasHidden:(NSNotification*)aNotification {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (![self isPad] && [_selectedTab currentURL] == nil && ![_addressBar isFirstResponder]) {
        [[_selectedTab webView] stringByEvaluatingJavaScriptFromString:@"document.getElementById('contain').style.top = '15%'"];
        [self scrollToTop:aNotification];
    }
}

- (void)registerForBrowserNotifications
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kStartedLoadingNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFinishedLoadingNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startedLoadingNotification:)
                                                 name:kStartedLoadingNotification
                                               object:_selectedTab];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishedLoadingNotification:)
                                                 name:kFinishedLoadingNotification
                                               object:_selectedTab];
    
}

- (void)startedLoadingNotification:(NSNotification *)notification {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [self displayAsLoading];
}

- (void)finishedLoadingNotification:(NSNotification *)notification {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [self displayAsNotLoading];
}

- (void)displayAsLoading {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_stopButton setHidden:NO];
    [_refreshButton setHidden:YES];
}

- (void)displayAsNotLoading {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_stopButton setHidden:YES];
    [_refreshButton setHidden:NO];
}

-(void) saveOpenTabs {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    //Core Data Fix
    /*
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
     */
}

-(void) openSavedTabs {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    //Core Data Fix
    /*
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
        [_selectedTab setTitle:[tab valueForKey:@"title"]];
        
        [managedObjectContext deleteObject:tab];
    }
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error deleting %@ - error:%@",tabFetchResults,error);
    }
     */

}

-(void) deleteSavedTabs {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    //Core Data Fix
    /*
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
    */
    
}

- (void) viewDidAppear:(BOOL)animated {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [super viewDidAppear:animated];
    //create initial tab
    if ([self.tabs count] == 0) {
        [self addTab:[self addTab]];
    }
	
}

- (void) viewWillAppear:(BOOL)animated {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    //[refreshButton setHidden:YES];
    [super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	[self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Scrolling

-(IBAction)scrollToTop:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (![self isPad]) {
//        BOOL animated = ![sender isKindOfClass:[NSNotification class]];
        [[[self webView] scrollView] setContentOffset:CGPointMake(0, - _topBar.frame.size.height) animated:NO];
        [[[self webView] scrollView] setContentInset:UIEdgeInsetsMake(-[[self webView] scrollView].contentOffset.y, 0, 0, 0)];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    ScrollDirection scrollDirection = ScrollDirectionNone;
    int minWebViewSize = _webViewTemplate.frame.size.height;
    int maxWebViewSize = minWebViewSize + _bottomBar.frame.size.height;
    if (self.lastScrollContentOffset > scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionUp;
    else if (self.lastScrollContentOffset < scrollView.contentOffset.y)
        scrollDirection = ScrollDirectionDown;
    
    if (_saveScrollPosition) {
        _selectedTab.scrollPosition = scrollView.contentOffset.y;
    }
    if(![self isPad]) {
        UIView *statusBarView = [(UIMainView *)self.view statusBarView];
        if (scrollView.contentOffset.y <= -_topBar.frame.size.height) {
            // noop
        } else if (scrollView.contentOffset.y < -statusBarView.frame.size.height) {
            [[[self webView] scrollView] setContentInset:UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0)];
        } else {
            [[[self webView] scrollView] setContentInset:UIEdgeInsetsMake(statusBarView.frame.size.height, 0, 0, 0)];
        }
        
        // show bottom toolbar when scrolling up fast
        if (scrollDirection == ScrollDirectionUp && scrollView.contentOffset.y - self.lastScrollContentOffset < -20 && _bottomBar.alpha == 0.0) {
                [self toggleBottomBarWithCompletion:^(BOOL finished){
                                     if (finished) {
                                         [_selectedTab webView].frame = CGRectMake([_selectedTab webView].frame.origin.x, [_selectedTab webView].frame.origin.y, [_selectedTab webView].frame.size.width, minWebViewSize);
                                     }
                                 }];
                _topBar.frame=CGRectMake(0,0, _topBar.frame.size.width, _topBar.frame.size.height);
    
            
        } else if (scrollView.contentOffset.y > 0 && scrollView.contentOffset.y + scrollView.frame.size.height < scrollView.contentSize.height) {
            if (scrollDirection == ScrollDirectionDown && _bottomBar.alpha == 1.0) {
                [_selectedTab webView].frame = CGRectMake([_selectedTab webView].frame.origin.x, [_selectedTab webView].frame.origin.y, [_selectedTab webView].frame.size.width, maxWebViewSize);
                
                [self toggleBottomBarWithCompletion:nil];
            }
        
        // show bottom toolbar
        } else if (_bottomBar.alpha == 0.0)  {
            [self toggleBottomBarWithCompletion:^(BOOL finished){
                                 if (finished) {
                                     [_selectedTab webView].frame = CGRectMake([_selectedTab webView].frame.origin.x, [_selectedTab webView].frame.origin.y, [_selectedTab webView].frame.size.width, minWebViewSize);
                                     if (scrollView.contentOffset.y > 0) {
                                         CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - [_selectedTab webView].frame.size.height);
                                         [scrollView setContentOffset:bottomOffset animated:NO];
                                     }
                                 }
                             }];

        }
    }
    
    //topbar logic
    if(![self isPad] && scrollView.contentOffset.y>=-_topBar.frame.size.height && (scrollView.contentOffset.y <= 0 || scrollDirection == ScrollDirectionDown))
    {
        _topBar.frame=CGRectMake(0,-_topBar.frame.size.height-scrollView.contentOffset.y, _topBar.frame.size.width, _topBar.frame.size.height);
    }
    
    self.lastScrollContentOffset = scrollView.contentOffset.y;
}

- (void)toggleBottomBarWithCompletion:(void (^)(BOOL finished))completion
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    float alpha = 0.0;
    //UIViewAnimationCurve *options = UIViewAnimationCurveEaseO
    
    if (_bottomBar.alpha == 0.0) {
        alpha = 1.0;
    }
    // Fade out the view right away
    [UIView animateWithDuration:1.0
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         _bottomBar.alpha = alpha;
                     }
                     completion: completion];
}



// Web methods

- (void) currentWebViewDidStartLoading:(UIWebView *) webView  {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if (_addressBar.editing) {
        [webView stopLoading];
        return;
    }
    
    
    Tab *tab = nil;
    for (id cTab in _tabs) {
        if ([cTab webView] == webView) {
            tab = cTab;
        }
    }
    if (tab == _selectedTab) {
        
        if (_initialPageLoad) {
            [_refreshButton setHidden:YES];
            [_stopButton setHidden:NO];
        }
        
    }
    if (_progressBar.progress < 0.95) {
        [_progressBar setProgress:_progressBar.progress + 0.05];
    }
    [self setInitialPageLoad:NO];
}

- (void)currentWebViewDidFinishFinalLoad:(UIWebView *) webView {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_progressBar setProgress:1.0 animated:NO];
    [_progressBar setHidden:YES];
    
    [_stopButton setHidden:YES];
    
    NSURL *url = [webView.request URL];
    if ([url isFileURL] || [[url absoluteString] isEqualToString:@"about:blank"]) {
        [_refreshButton setHidden:YES];
    } else {
        [_refreshButton setHidden:NO];
    }
    if (_saveScrollPosition && [_selectedTab scrollPosition] > 0) {
        [[[self webView] scrollView] setContentOffset:CGPointMake(0, [_selectedTab scrollPosition]) animated:NO];
    }
    [self loadTabs:webView];
}

- (void)gotoAddress:(id)sender withRequestObj:(NSURLRequest *)request inTab:(Tab *)tab {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    // Clear detected bugs
    tab.currentURLString = @"";
    [self setInitialPageLoad:YES];
	
    //[whiteView setHidden:NO];
    [[self webView] stopLoading];
    //[[self webView] loadHTMLString:@"<html><head></head><body></body></html>" baseURL:[NSURL URLWithString:@"about:blank" ]];
    
    _saveScrollPosition = [[[request URL] host] isEqualToString:@"duckduckgo.com"] || [[[request URL] host] isEqualToString:@"www.duckduckgo.com"];
    
    if (![self isPad]) {
        [self scrollToTop:nil];
    }
	
	[_oldAddressText setString:[_addressBar text]];
	
	// Load the request in the UIWebView.
    if ([self checkNetworkStatus]) {
        //[[self webView] loadRequest:requestObj];
        
        NSMutableURLRequest *mRequest = [request mutableCopy];
        NSString *deviceString = [self isPad] ? @"iPad" : @"iPhone";
        if (!self.userAgent) {
            self.userAgent = [[tab webView] stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        }
        [mRequest setValue:[NSString stringWithFormat:self.userAgent, deviceString] forHTTPHeaderField:@"User-Agent"];
        
        if ([[[request URL] host] isEqualToString:@"itunes.apple.com"]) {
            [[UIApplication sharedApplication] openURL: mRequest.URL ];
        } else {
            [_progressBar setHidden:NO];
            [_progressBar setProgress:0.1 animated:NO];
            tab.urlConnection = nil;
            tab.urlConnection = [[NSURLConnection alloc] initWithRequest:mRequest delegate:tab];
            if (sender != _refreshButton) {
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
        [_progressBar setHidden:YES];
        [self cannotConnect:nil];
        
    }
    
    [_addressBar resignFirstResponder];
}

-(IBAction) didStartEditingAddressBar:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if ([[_addressBar text] length] > 0) {
        [self performSelector:@selector(selectAllAddressText) withObject:nil afterDelay:0.0];
    }
    [_addressBarButtonsView setHidden:YES];
}

-(void) selectAllAddressText {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_addressBar setSelectedTextRange:[_addressBar textRangeFromPosition:_addressBar.beginningOfDocument toPosition:_addressBar.endOfDocument]];
}

-(IBAction) gotoAddress:(id) sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_addressBarButtonsView setHidden:NO];
    [_stopButton setHidden:NO];
    [_refreshButton setHidden:YES];
    
    NSString *inputText = [[_addressBar text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    _gotoUrl = [NSURL URLWithString:inputText];
    if (_gotoUrl != nil && (!([[_gotoUrl scheme] isEqualToString:@"http"] || [[_gotoUrl scheme] isEqualToString:@"https"]))) {
        _gotoUrl = [NSURL URLWithString: [@"http://" stringByAppendingString:[_gotoUrl absoluteString]]];
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:_gotoUrl];
    if ([inputText rangeOfString:@"."].location != NSNotFound && [NSURLConnection canHandleRequest:request]){
        [self gotoAddress:sender withRequestObj:request inTab:_selectedTab];
    } else {
        [self searchWeb:sender];
    }
}

-(IBAction) didEndEditingAddressBar:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
}

-(IBAction) searchWeb:(id) sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	NSString *searchQuery = [_addressBar text];
    NSString *encodedSearchQuery = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                         NULL,
                                                                                                         (CFStringRef)searchQuery,
                                                                                                         NULL,
                                                                                                         (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                    kCFStringEncodingUTF8 ));
	NSString *urlString = [@"http://www.duckduckgo.com/html/?q=" stringByAppendingString:encodedSearchQuery];
    
    // Load the request in the UIWebView.
    if ([self checkNetworkStatus]) {
        [self gotoAddress:sender withRequestObj:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] inTab:_selectedTab];
    } else {
        [self cannotConnect:nil];
        [_progressBar setHidden:YES];
        
    }
	//Load the request in the UIWebView.
	[_addressBar resignFirstResponder];
}

-(void) cannotConnect:(UIWebView *) cnWebView {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_stopButton setHidden:NO];
    [_refreshButton setHidden:YES];
    NSURL *ucUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"unable_to_connect" ofType:@"html"] isDirectory:NO];
    NSString *ucContentString = [NSString stringWithContentsOfURL:ucUrl encoding:NSUTF8StringEncoding error:nil];
    [[self webView] loadHTMLString:ucContentString baseURL:nil];
}

-(IBAction) goBack:(id)sender {
	LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_selectedTab goBack];
    self.reloadOnPageLoad = YES;
}

-(IBAction) goForward:(id)sender {
	LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [_selectedTab goForward];
	//[[self webView] stringByEvaluatingJavaScriptFromString:@"history.forward();"];
}

-(IBAction) cancel:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	//[self contractBar: sender];
}

-(IBAction) showBookmarks:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);

    [self showBookmarksView:sender];
}

-(void) showBookmarksView:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [self dismissPopups];
    [self.view bringSubviewToFront:self.bookmarksNavController.view];
    self.bookmarksNavController.view.frame = CGRectMake(0, 0, self.bookmarksNavController.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height);
    //Reload all bC controllers on the navigation stack
    for (BookmarksController* bC in self.bookmarksNavController.viewControllers)
    {
        if([bC isKindOfClass:[BookmarksController class]])
        {
            [bC loadBookmarks];
            [bC setBrowserController:self];
            [bC.tableView reloadData];
        }
    }
    [UIView animateWithDuration:0.25 animations:^{
         self.bookmarksNavController.view.alpha =1.0f;
    }];
}

-(IBAction) stopLoading:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	[_stopButton setHidden:YES];
    [_refreshButton setHidden:NO];
    [_progressBar setHidden:YES];
    
	//[activityIndicator stopAnimating];
    if ([_tabs count] > 0) {
        [[_selectedTab webView] stopLoading];
    }
}

-(NSArray *) actionSheetButtons {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    // hide add bookmark for local html files
    NSURL *url = [[self webView].request URL];
    if ([url isFileURL] || [[url absoluteString] isEqualToString:@"about:blank"]) {
        return [NSArray arrayWithObjects:@"Clear Cookies", @"Clear Cache", nil];
    } else {
        return [NSArray arrayWithObjects:@"Add Bookmark", @"Clear Cookies", @"Clear Cache", nil];
    }
}

-(IBAction)showActionSheet:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	// Hide popover for ipad
	if ([self isPad] ) {
        
		if (_padPopover.popoverVisible) {
			[_padPopover dismissPopoverAnimated:YES];
		}
        
		if (_popupQuery.visible) {
			_barItemPopoverPresenter = nil;
			[_popupQuery dismissWithClickedButtonIndex:_popupQuery.cancelButtonIndex animated:YES];
		} else {
            [self generatePopupQuery];
			_barItemPopoverPresenter = _moreButton;
			[_popupQuery showFromBarButtonItem:_moreButton animated:YES];
		}
	} else {
        [self generatePopupQuery];
		[_popupQuery showInView:self.view];
	}
}

-(void) generatePopupQuery {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    UIActionSheet *pQuery= [[UIActionSheet alloc] initWithTitle:nil
                                                       delegate:self
                                              cancelButtonTitle:nil
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:nil];
    for (NSString *button in [self actionSheetButtons]) {
        [pQuery addButtonWithTitle:button];
    }
    
    pQuery.cancelButtonIndex = [pQuery addButtonWithTitle:@"Cancel"];
    
    _popupQuery = pQuery;
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    // skip add bookmarks if we are loading a local file
    NSURL *url = [[self webView].request URL];
    if ([url isFileURL] || [[url absoluteString] isEqualToString:@"about:blank"]) {
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
    /*else if (buttonIndex == 3) {
        [self addTab:actionSheet];
        NSString *urlAddress = @"";
        //[[self webView] loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"import_bookmark_howto" ofType:@"html"]isDirectory:NO]]];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"import_bookmark_howto" ofType:@"html"];
        NSData *launchData = [NSData dataWithContentsOfFile:path];
        [[self webView] loadData:launchData MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:nil];
        [_addressBar setText:urlAddress];
    }*/

}

-(void) addBookmarkFromSheet:(UIActionSheet *) sheet {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    [sheet dismissWithClickedButtonIndex:0 animated:YES];
    
    // Set up bookmark controllers
	UINavigationController *bookmarksNavController = [self createBookmarksController:NO];
    BookmarksFormController* bookmarksFormController = (BookmarksFormController*)[[bookmarksNavController viewControllers] objectAtIndex:1];
    [bookmarksFormController setMode:'A'];
    [[bookmarksFormController navigationItem] setHidesBackButton:YES animated:NO];
    
    if ([self isPad]) {
        if (_padPopover == nil) {
            UIPopoverController *ppop = [[UIPopoverController alloc]
                                         initWithContentViewController:bookmarksNavController];
            self.padPopover = ppop;
            
        } else {
            [self.padPopover setContentViewController:bookmarksNavController animated:YES];
        }
        [self.padPopover presentPopoverFromBarButtonItem:_bookmarkButton
                                permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    } else {
        [self presentViewController:bookmarksNavController animated:YES completion:nil];
    }
}

-(void) dismissPopups {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    if([self isPad])
    {
        [_popupQuery dismissWithClickedButtonIndex:_popupQuery.cancelButtonIndex animated:NO];
        [_padPopover dismissPopoverAnimated:NO];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// TABS

-(IBAction) addTab:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
//    if (_tabsView.hidden) {
//        [self toggleTabsView:sender];
//    }
    [self addTabWithAddress:@""];
}

-(void) addTabWithAddress:(NSString *)urlAddress {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	if ([_tabs count] == 0) {
		_tabs = [[NSMutableArray alloc] initWithCapacity:8];
	}
	// reset navbar
	//[self contractBar:sender];
    /*if (!stopButton.hidden) {
     [self stopLoading:sender];
     }*/
	
    Tab *rightMostTab = [_tabs lastObject];
    CGFloat rightMostTabEdge = (rightMostTab) ? rightMostTab.frame.origin.x + rightMostTab.frame.size.width : 0;
    CGFloat tabWidth = rightMostTab.frame.size.width;
    CGFloat initialX = (rightMostTabEdge < DEVICE_SIZE.width) ? DEVICE_SIZE.width + tabWidth : rightMostTabEdge + tabWidth;
    Tab *nTab = [[Tab alloc] initWithFrame:CGRectMake(initialX, 2.0, kTabWidth, 34.0)
                                 addTarget: self];
    
    [self switchTabFrom:_selectedTab ToTab:nTab];
	[_tabsView addSubview:_selectedTab];
	
	[_tabs addObject:_selectedTab];
	[_selectedTab select];
    
    [UIView animateWithDuration:0.35 animations:^{
        CGRect newFrame = nTab.frame;
        newFrame.origin.x = (kTabWidth * ([_tabs count] - 1)) + 2.0;
        nTab.frame = newFrame;
    } completion:^(BOOL finished) {
        if (!finished) {
            CGRect newFrame = nTab.frame;
            newFrame.origin.x = (kTabWidth * ([_tabs count] - 1)) + 2.0;
            nTab.frame = newFrame;
        }
    }];
	
	//scrolling
	_tabsView.contentSize = CGSizeMake((kTabWidth * [_tabs count]) + 5.0, 23.0);
    if (_tabsView.frame.size.width < _tabsView.contentSize.width) {
        _tabsView.contentOffset = CGPointMake(_tabsView.contentSize.width - _tabsView.frame.size.width,0);
    }
    
	_tabsView.clipsToBounds = YES;
	_tabsView.showsHorizontalScrollIndicator = NO;
	
    if ([urlAddress isEqualToString:@""]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"launch" ofType:@"html"];
        NSData *launchData = [NSData dataWithContentsOfFile:path];
        [[self webView] loadData:launchData MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:nil];
        if (![_addressBar isFirstResponder])  {
            [_addressBar setText:urlAddress];
        }
        
    } else {
        [self gotoAddress:nil withRequestObj:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:urlAddress]] inTab:_selectedTab];
    }
    
	[self loadTabs:[_selectedTab webView]];
}

-(IBAction) removeTab:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	[sender setEnabled:NO];
	Tab *toBeRemoved = (Tab *)[sender superview];
	[[toBeRemoved tabButton] setEnabled:NO];
	
    [UIView animateWithDuration:0.20 animations:^{
        CGRect newFrame = toBeRemoved.frame;
        newFrame.origin.y += toBeRemoved.frame.size.height;
        toBeRemoved.frame = newFrame;
    } completion:^(BOOL finished) {
        BOOL removed = NO;
        BOOL select = NO;
        
        for (id cTab in _tabs) {
            if (select) {
                [self switchTabFrom:_selectedTab ToTab:cTab];
                select = NO;
            }
            if (removed) {
                if (!finished) {
                    [cTab incrementOffset];
                } else {
                    [UIView animateWithDuration:0.20 animations:^{
                        [cTab incrementOffset];
                    } completion:nil];
                }
            }
            if ([cTab closeButton] == sender) {
                removed = YES;
                select = (_selectedTab == cTab);
            }
            
        }
        
        if (toBeRemoved == [_tabs lastObject] && [_tabs lastObject] != [NSNull null] && [_tabs count] > 1) {
            [self switchTabFrom:_selectedTab ToTab:[_tabs objectAtIndex:[_tabs count]-2]];
        } else if ([_tabs count] == 0) {
            self.webView = nil; // why?
        }
        [toBeRemoved removeFromSuperview];
        [[toBeRemoved webView] removeFromSuperview];
        [_tabs removeObject:toBeRemoved];
        
        
        if ([_tabs count] == 0) {
            [self addTab:nil];
        }
        [self loadTabs:[_selectedTab webView]];
        
        //scrolling
        _tabsView.contentSize = CGSizeMake((kTabWidth * [_tabs count]) + 40.0, 23.0);
    }];
    
}

-(IBAction) selectTab:(id)sender {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	for (id cTab in _tabs) {
		if ([cTab tabButton] == sender) {
			[self switchTabFrom:_selectedTab ToTab:cTab];
            if ([_selectedTab isLoading]) {
                [self displayAsLoading];
            } else {
                [self displayAsNotLoading];
            }
            [self registerForBrowserNotifications];
		}
	}
	[self loadTabs:[_selectedTab webView]];
}

-(void) switchTabFrom:(Tab *)fromTab ToTab:(Tab *)toTab {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	if ([_tabs count] > 0) {
		[fromTab deselect];

	}
	[toTab select];
	_selectedTab = toTab;
    if (![toTab loading]) {
        [[self progressBar] setHidden:YES];
        [[self stopButton] setHidden:YES];
        [[self refreshButton] setHidden:NO];
        [[self addressBar] setText:[_selectedTab currentURLString]];
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
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    return [_selectedTab webView];
}

-(UIWebView *) setWebView:(UIWebView *)newWebView {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
	[_selectedTab setWebView:newWebView];
	return newWebView;
}


-(void) loadTabs:(UIWebView *)webView {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    Tab *tab = nil;
	
    [[self view] sendSubviewToBack:webView];
    
	for (id cTab in _tabs) {
		if ([cTab webView] == webView) {
			tab = cTab;
		} else {
            [[self view] sendSubviewToBack:[cTab webView]];
        }
	}
	
	if (tab == _selectedTab) {
        if ([webView request] == nil || [[webView request].URL isFileURL]) {
            if (![_addressBar isFirstResponder]) {
                [_addressBar setText: @""];
            }
            
        } else {
            NSString *addressText = tab.currentURLString;
            if (![addressText isEqualToString:@"about:blank"] && [addressText rangeOfString:@"https://duckduckgo.com"].location == NSNotFound) {
                if (![_addressBar isFirstResponder]) {
                    [_addressBar setText:addressText];
                }
                [_refreshButton setHidden:[tab loading]];
            }
            
        }
        
		if([_selectedTab canGoForward]) {
			_forwardButton.enabled = TRUE;
		}
		else if(![_selectedTab canGoForward]) {
			_forwardButton.enabled = FALSE;
		}
		if([_selectedTab canGoBack]) {
			_backButton.enabled = TRUE;
		}
		else if(![_selectedTab canGoBack]) {
			_backButton.enabled = FALSE;
		}
        
	}
    // Set title
    //[tab showText];
}


// Orientation

- (NSUInteger) supportedInterfaceOrientations {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    // Return a bitmask of supported orientations. If you need more,
    // use bitwise or (see the commented return).
    return UIInterfaceOrientationMaskAll;
    // return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    // Return the orientation you'd prefer - this is what it launches to. The
    // user can still rotate. You don't have to implement this method, in which
    // case it launches in the current orientation
    return UIInterfaceOrientationPortrait;
}


// Reachability
- (BOOL) checkNetworkStatus
{
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus netstat = [reachability currentReachabilityStatus];
    return netstat != NotReachable;
}

// HARDWARE
- (BOOL) isPad {
    LogTrace(@"%s", __PRETTY_FUNCTION__);
    
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}



@end
