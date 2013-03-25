//
//  BrowserViewController.h
//  Ghostery
//
//  Created by Alexandru Catighera on 3/5/13.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
@class Tab, BookmarksController, BookmarksFormController;

@interface BrowserViewController : UIViewController <UIActionSheetDelegate, UIWebViewDelegate, UIScrollViewDelegate, NSURLConnectionDelegate> {
	   
    IBOutlet UIView *webViewTemplate;
	IBOutlet UIScrollView *tabsView;
    IBOutlet UIView *topBar;
	IBOutlet UIToolbar *navBar;
	
	IBOutlet UITextField *addressBar;
	IBOutlet UITextField *searchBar;
	NSMutableString *oldAddressText;
	
	IBOutlet UIActivityIndicatorView *activityIndicator;
	IBOutlet UIButton *refreshButton;
	IBOutlet UIButton *stopButton;
	
	IBOutlet UIBarButtonItem *forwardButton;
	IBOutlet UIBarButtonItem *backButton;
	IBOutlet UIBarButtonItem *addressItem;
	IBOutlet UIBarButtonItem *searchItem;
	IBOutlet UIBarButtonItem *customButton;
	IBOutlet UIBarButtonItem *moreButton;
	IBOutlet UIBarButtonItem *bookmarkButton;
    
    UIBarButtonItem *barItemPopoverPresenter;
	UIActionSheet *popupQuery;
    UIPopoverController *padPopover;
	
	IBOutlet UIButton *addTab;
	Tab *selectedTab;
	NSMutableArray *tabs;
    
    NSString *currentURLString;
	
	UINavigationController *bookmarksController;
	BookmarksFormController *bookmarksFormController;	
        
    BOOL reloadOnPageLoad;
    BOOL initialPageLoad;
    BOOL saveScrollPosition;
    
    NSURLConnection *urlConnection;
    NSHTTPURLResponse *response;
    NSURL *gotoUrl;
    NSMutableData *pageData;
    IBOutlet UIProgressView *progressBar;
    float contentSize;
    
}
@property(nonatomic,strong) UIView *webViewTemplate;

@property(nonatomic,strong) UIScrollView *tabsView;
@property(nonatomic,strong) UIView *topBar;

@property(nonatomic,strong) UIToolbar *navBar;
@property(nonatomic,strong) UIToolbar *bugListNavBar;
@property(nonatomic,strong) UITextField *addressBar;
@property(nonatomic,strong) UITextField *searchBar;
@property(nonatomic,strong) NSMutableString *oldAddressText;

@property(nonatomic,strong) UIActivityIndicatorView *activityIndicator;
@property(nonatomic,strong) UIButton *refreshButton;
@property(nonatomic,strong) UIButton *stopButton;

@property(nonatomic,strong) UIBarButtonItem *forwardButton;
@property(nonatomic,strong) UIBarButtonItem *backButton;
@property(nonatomic,strong) UIBarButtonItem *addressItem;
@property(nonatomic,strong) UIBarButtonItem *searchItem;
@property(nonatomic,strong) UIBarButtonItem *customButton;
@property(nonatomic,strong) UIBarButtonItem *moreButton;
@property(nonatomic,strong) UIBarButtonItem *bookmarkButton;

@property(nonatomic,strong) UIBarButtonItem *barItemPopoverPresenter;
@property(nonatomic,strong) UIActionSheet *popupQuery;
@property(nonatomic,strong) UIPopoverController *padPopover;

@property(nonatomic,strong) UIButton *addTab;
@property(nonatomic,strong) Tab *selectedTab;
@property(nonatomic,strong) NSMutableArray *tabs;

@property(nonatomic,strong) NSString *currentURLString;

@property(nonatomic,strong) UINavigationController *bookmarksController;
@property(nonatomic,strong) BookmarksFormController *bookmarksFormController;
@property(nonatomic,strong) BrowserViewController *browserController;

@property(nonatomic,assign) BOOL reloadOnPageLoad;
@property(nonatomic,assign) BOOL initialPageLoad;
@property(nonatomic,assign) BOOL saveScrollPosition;

@property(nonatomic,strong) NSURLConnection *urlConnection;
@property(nonatomic,strong) NSHTTPURLResponse *response;
@property(nonatomic,strong) NSURL *gotoUrl;
@property(nonatomic,strong) NSMutableData *pageData;
@property(nonatomic,strong) UIProgressView *progressBar;
@property(nonatomic,assign) float contentSize;

-(IBAction) gotoAddress:(id)sender;
-(IBAction) searchWeb:(id)sender;
-(IBAction) goBack:(id)sender;
-(IBAction) goForward:(id)sender;
-(IBAction) stopLoading:(id)sender;
-(IBAction) expandURLBar:(id)sender;
-(IBAction) expandSearchBar:(id)sender;
-(IBAction) contractBar:(id)sender;
-(IBAction) showBookmarks:(id)sender;
-(IBAction) customButtonClick:(id)sender;

-(NSArray *) actionSheetButtons;
-(IBAction) showActionSheet:(id)sender;
-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;

-(IBAction) addTab:(id)sender;
-(IBAction) selectTab:(id)sender;
-(IBAction) removeTab:(id)sender;
-(IBAction) toggleTabsView:(id)sender;

-(void) loadTabs:(UIWebView *) webView;
-(void) switchTabFrom:(Tab *)fromTab ToTab:(Tab *)toTab;

-(void) loadPageString:(NSString *)page;

-(void) showBookmarksView:(id)sender;

-(UIWebView *) webView;
-(UIWebView *) setWebView:(UIWebView *) newWebView;

-(BOOL)isPad;

-(BOOL) checkNetworkStatus;

-(void) gotoAddress:(id) sender withRequestObj:(NSURLRequest *) request;

@end
