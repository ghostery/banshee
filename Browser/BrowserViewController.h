//
//  BrowserViewController.h
//
//  Created by Alexandru Catighera on 3/5/13.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define kStartedLoadingNotification @"kStartedLoadingNotification"
#define kFinishedLoadingNotification @"kFinishedLoadingNotification"

//reference: http://stackoverflow.com/a/18085584/347339
#define DEVICE_SIZE [[UIScreen mainScreen] bounds].size

@class Tab, BookmarksController, BookmarksFormController, Reachability;

@interface BrowserViewController : UIViewController <UIActionSheetDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property(nonatomic,strong) IBOutlet UIView *webViewTemplate;

@property(nonatomic,strong) IBOutlet UIScrollView *tabsView;
@property(nonatomic,strong) IBOutlet UIView *topBar;
@property(nonatomic,strong) IBOutlet UIToolbar *bottomBar;

@property(nonatomic,strong) IBOutlet UIToolbar *navBar;
@property(nonatomic,strong) UIToolbar *bugListNavBar;
@property(nonatomic,strong) IBOutlet UITextField *addressBar;
@property(nonatomic,strong) UITextField *searchBar;
@property(nonatomic,strong) NSMutableString *oldAddressText;

@property(nonatomic,strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic,strong) IBOutlet UIView *addressBarButtonsView;
@property(nonatomic,strong) IBOutlet UIButton *refreshButton;
@property(nonatomic,strong) IBOutlet UIButton *stopButton;

@property(nonatomic,strong) IBOutlet UIBarButtonItem *forwardButton;
@property(nonatomic,strong) IBOutlet UIBarButtonItem *backButton;
@property(nonatomic,strong) IBOutlet UIBarButtonItem *addressItem;
@property(nonatomic,strong) IBOutlet UIBarButtonItem *searchItem;
@property(nonatomic,strong) IBOutlet UIBarButtonItem *moreButton;
@property(nonatomic,strong) IBOutlet UIBarButtonItem *bookmarkButton;

@property(nonatomic,strong) UIBarButtonItem *barItemPopoverPresenter;
@property(nonatomic,strong) UIActionSheet *popupQuery;
@property(nonatomic,strong) UIPopoverController *padPopover;

@property(nonatomic,strong) IBOutlet UIButton *addTab;
@property(nonatomic,strong) Tab *selectedTab;
@property(nonatomic,strong) NSMutableArray *tabs;

@property(nonatomic,strong) NSURL *gotoUrl;

@property(nonatomic,strong) UINavigationController *bookmarksNavController;
@property(nonatomic,strong) BookmarksFormController *bookmarksFormController;
@property(nonatomic,strong) BrowserViewController *browserController;

@property(nonatomic,assign) BOOL reloadOnPageLoad;
@property(nonatomic,assign) BOOL initialPageLoad;
@property(nonatomic,assign) BOOL saveScrollPosition;
@property(nonatomic, assign) NSInteger lastScrollContentOffset;

@property(nonatomic,strong) NSString *userAgent;

@property(nonatomic,strong) IBOutlet UIProgressView *progressBar;
@property(nonatomic,assign) float contentSize;

-(IBAction) gotoAddress:(id)sender;
-(IBAction) didStartEditingAddressBar:(id)sender;
-(IBAction) searchWeb:(id)sender;
-(IBAction) goBack:(id)sender;
-(IBAction) goForward:(id)sender;
-(IBAction) stopLoading:(id)sender;
-(IBAction) showBookmarks:(id)sender;
-(IBAction) scrollToTop:(id)sender;

-(void) toggleBottomBarWithCompletion:(void (^)(BOOL finished))completion;

-(NSArray *) actionSheetButtons;
-(IBAction) showActionSheet:(id)sender;
-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

-(IBAction) addTab:(id)sender;
-(void) addTabWithAddress:(NSString *)urlAddress;
-(IBAction) selectTab:(id)sender;
-(IBAction) removeTab:(id)sender;
//-(IBAction) toggleTabsView:(id)sender;

-(void) loadTabs:(UIWebView *) webView;
-(void) switchTabFrom:(Tab *)fromTab ToTab:(Tab *)toTab;

-(void) showBookmarksView:(id)sender;
-(void) addBookmarkFromSheet:(UIActionSheet *) sheet;

-(UIWebView *) webView;
-(UIWebView *) setWebView:(UIWebView *) newWebView;
-(void) currentWebViewDidFinishFinalLoad:(UIWebView *) webView;

-(BOOL)isPad;

-(BOOL) checkNetworkStatus;

-(void) cannotConnect:(UIWebView *) cnWebView;

-(void) gotoAddress:(id) sender withRequestObj:(NSURLRequest *)request inTab:(Tab *)tab;

-(void) saveOpenTabs;
-(void) openSavedTabs;
-(void) deleteSavedTabs;
-(void) dismissPopups;

@end
