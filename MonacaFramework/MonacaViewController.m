//
//  MonacaViewController.m
//  Template
//
//  Created by Hiroki Nakagawa on 11/06/07.
//  Copyright 2011 ASIAL CORPORATION. All rights reserved.
//

#import "MonacaViewController.h"
#import "MonacaTabBarController.h"
#import "JSONKit.h"
#import "MonacaTemplateEngine.h"
#import "MonacaTransitPlugin.h"
#import "Utility.h"

@interface MonacaViewController ()
- (NSString *)careWWWdir:(NSString *)path;
@end

@implementation MonacaViewController

@synthesize scrollView = scrollView_;
@synthesize previousPath = previousPath_;
@synthesize recall = recall_;
@synthesize monacaPluginOptions;

@synthesize tabBarController;
@synthesize appNavigationController;
@synthesize cdvViewController;

// Parses *.ui files.
static NSDictionary *
parseJSONFile(NSString *path) {
    NSError *error = nil;
    NSString *data = [NSString stringWithContentsOfFile:path
                                               encoding:NSUTF8StringEncoding
                                                  error:&error];
    if (data == nil) {
        [NSException raise:@"RuntimeException" format:@"File Not Found: %@", path];
    }
    if(NO){
    data = [data stringByReplacingOccurrencesOfString:@"[\"]*(\\w+)[\"]*\\s*:(\\s*[\"]*.*[\"]*)"
                                           withString:@"\"$1\":$2"
                                              options:NSRegularExpressionSearch
                                                range:NSMakeRange(0, [data length])];
    }
    return [data cdvjk_objectFromJSONString];
}

+ (BOOL)isPhoneGapScheme:(NSURL *)url {
    return ([[url scheme] isEqualToString:@"gap"]);
}

+ (BOOL)isExternalPage:(NSURL *)url {
    return ([[url scheme] isEqualToString:@"http"] ||
            [[url scheme] isEqualToString:@"https"]);
}

// Returns YES if |url| has anchor parameter (http://example.com/index.html#aaa).
// TODO: Should use fragment method in NSURL class.
+ (BOOL)hasAnchor:(NSURL *)url {
    NSRange searchResult = [[url absoluteString] rangeOfString:@"#"];
    return searchResult.location != NSNotFound;
}

+ (NSURL *)standardizedURL:(NSURL *)url {
    // Standardize relative path ("." and "..").
    url = [url standardizedURL];
    NSString *last = [url lastPathComponent];
    
    // Replace double thrash to single thrash ("//" => "/").
    NSString *tmp = [url absoluteString];
    NSString *str = [tmp stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
    while (![str isEqualToString:tmp]) {
        tmp = str;
        str = [tmp stringByReplacingOccurrencesOfString:@"//" withString:@"/"];
    }
    
    // Remove |index.html| ("/www/item/index.html" => "/www/item").
    if ([last isEqualToString:@"index.html"]) {
        str = [str substringToIndex:[str length] - [@"/index.html" length]];
    }
    
    return [NSURL URLWithString:str];
}

- (id)init{
    self = [super init];
    if (self){
        uiSetting = nil;
    }
    return self;
}

- (id)initWithFileName:(NSString *)fileName {
    self = [self init];
    if (nil != self) {
        cdvViewController = [[[CDVViewController alloc] init] autorelease];
        cdvViewController.wwwFolderName = @"www";
        cdvViewController.startPage = fileName;
        
        self.recall = NO;
        self.previousPath = nil;
        interfaceOrientationUnspecified = YES;
        interfaceOrientation = UIInterfaceOrientationPortrait;
        
        // parse plist for ExternalHosts.
        NSArray *externalHosts = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ExternalHosts"];
        monacaWhitelist = [[[CDVWhitelist alloc] initWithArray:externalHosts] retain];
        
        // create native component items.
        NSMutableArray *viewControllers = [[[NSMutableArray alloc] init] autorelease];
        [viewControllers addObject:cdvViewController];
        tabBarController = [[MonacaTabBarController alloc] init];
        [tabBarController setViewControllers:viewControllers];
        
        appNavigationController = [[UINavigationController alloc] initWithRootViewController:tabBarController];
        
        [self.view addSubview:appNavigationController.view];
    }
    
    return self;
}

- (void)dealloc {
    self.scrollView = nil;
    self.previousPath = nil;
    [uiSetting release];
    [super dealloc];
}

/* 現時点では不要なため、コメントアウト
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    UIWebView *webView = ((MonacaDelegate *)[UIApplication sharedApplication].delegate).webView;
    NSString *js = [NSString stringWithFormat:@"window.onMemoryWarning && window.onMemoryWarning({'type':'ios'});"];
    [webView stringByEvaluatingJavaScriptFromString:js];
}
*/

#pragma mark - UIScrollViewDelegate

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    UIWebView *webView = ((MonacaDelegate *)[UIApplication sharedApplication].delegate).viewController.cdvViewController.webView;
    NSString *js = [NSString stringWithFormat:@"window.onTapStatusBar && window.onTapStatusBar();"];
    [webView stringByEvaluatingJavaScriptFromString:js];
    return YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [cdvViewController.webView scrollViewDidEndDecelerating:scrollView];
}

#pragma mark - View lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([Device iOSVersionMajor] < 5) {
        [self.tabBarController viewDidAppear:animated];
    }
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

- (void)viewWillAppear:(BOOL)animated {
    [tabBarController applyUserInterface:uiSetting];
    
    [super viewWillAppear:animated];
    if ([Device iOSVersionMajor] < 5) {
        [self.tabBarController viewWillAppear:animated];
    }
    cdvViewController.webView.delegate = self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [Utility fixedLayout:self interfaceOrientation:self.interfaceOrientation];
    
    // transit
    [MonacaTransitPlugin viewDidLoad:self];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)aInterfaceOrientation
{
    return [Utility getAllowOrientationFromPlist:aInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {

    // Adjust height of the navigation bar when the device ratates.
    // FIXME: the bug that colors of buttons is reset when the device rotates (iOS 4).

    UINavigationController *currentController = self.appNavigationController;
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation)) {
        float width = [Device widthOfWindow:UIInterfaceOrientationPortrait];
        float height = [Device heightOfNavigationBar:UIInterfaceOrientationPortrait];
        currentController.navigationBar.frame = CGRectMake(currentController.navigationBar.frame.origin.x, currentController.navigationBar.frame.origin.y, width, height);
    } else if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        float width = [Device widthOfWindow:UIInterfaceOrientationLandscapeLeft];
        float height = [Device heightOfNavigationBar:UIInterfaceOrientationLandscapeLeft];
        currentController.navigationBar.frame = CGRectMake(currentController.navigationBar.frame.origin.x, currentController.navigationBar.frame.origin.y, width, height);
    }

    // Adjust height of the toolbar when the device ratates.
    // FIXME: the bug that colors of buttons is reset when the device rotates (iOS 4).
//    float gap = [Device heightOfToolBar:UIInterfaceOrientationPortrait] - [Device heightOfToolBar:UIInterfaceOrientationLandscapeLeft];


    if ([[Utility currentTabBarController] hasTitleView]) {
        [[Utility currentTabBarController] changeTitleView];
    }
}

- (NSString *)careWWWdir:(NSString *)path {
    return path;
}

- (BOOL)webView:(UIWebView *)webView_ shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL hasAnchor = [[self class] hasAnchor:[request URL]];
    NSURL *url = [[request URL] standardizedURL];
    
    // avoid to open gap schema ---
    if ([url.scheme isEqual:@"gap"]){
        return [cdvViewController webView:webView_ shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    // care about 404 page ---
    if([url.scheme isEqual:@"monacahome"]){
        if(self.previousPath){
            [webView_ loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:self.previousPath]]];
        }else {
            [self.navigationController popViewControllerAnimated:NO];
        }
        return NO;
    }
    if ([url.scheme isEqual:@"monaca404"]){
        self.recall = YES;
        [Utility show404PageWithWebView:webView_ path:url.path];
        return NO;
    }
    
    MonacaDelegate *delegate = (MonacaDelegate *)[UIApplication sharedApplication].delegate;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *startPagePath = [[delegate getBaseURL].path stringByAppendingFormat:@"/%@", self.cdvViewController.startPage];
    
    if (![fileManager fileExistsAtPath:startPagePath] && !self.recall) {
        // for push
        NSString *path = [self careWWWdir:[self.cdvViewController.wwwFolderName stringByAppendingFormat:@"/%@", self.cdvViewController.startPage]];
        NSString *requestPathFor404 = [@"monaca404://dummy.domain" stringByAppendingFormat:@"/%@", path];
        [webView_ loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:requestPathFor404]]];
        return NO;
    }else if (![fileManager fileExistsAtPath:[url path]] && navigationType != 5){
        // for link
        NSString *requestPathFor404 = [@"monaca404://dummy.domain" stringByAppendingFormat:@"/%@", [Utility getWWWShortPath:url.path]];
        [webView_ loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:requestPathFor404]]];
        return NO;
    }
    // ---

    // monaca white list ---
    BOOL isOpenWebview = YES;
    if ([monacaWhitelist schemeIsAllowed:[url scheme]]) {
        if ([monacaWhitelist URLIsAllowed:url] == YES) {
            NSNumber *openAllInWhitelistSetting = [cdvViewController.settings objectForKey:@"OpenAllWhitelistURLsInWebView"];
            if ((nil != openAllInWhitelistSetting) && [openAllInWhitelistSetting boolValue]) {
                isOpenWebview = YES;
            }
            
            // mainDocument will be nil for an iFrame
            NSString *mainDocument = [webView_.request.mainDocumentURL absoluteString];
            
            // anchor target="_blank" - load in Mobile Safari
            if (navigationType == UIWebViewNavigationTypeOther && mainDocument != nil) {
                [[UIApplication sharedApplication] openURL:url];
                isOpenWebview = NO;
                return NO;
            }else {
                // other anchor target - load in Cordova webView
                isOpenWebview = YES;
            }
        }
    }

    if (isOpenWebview == YES && self.recall == NO && [url isFileURL]) {
        // Treat anchor parameters.
        if (hasAnchor) {
            if (self.previousPath && [[url path] isEqualToString:self.previousPath]) {
                self.recall=YES;
                return YES;
            }
        }
        self.previousPath = [url path];

        BOOL isDir;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager fileExistsAtPath:[url path] isDirectory:&isDir];

        NSString *filepath = [url path];
        NSString *uipath;

        if (isDir) {
            uipath = [filepath stringByAppendingPathComponent:@"index.ui"];
            filepath = [filepath stringByAppendingPathComponent:@"index.html"];
        } else {
            uipath = [[filepath stringByDeletingPathExtension] stringByAppendingPathExtension:@"ui"];
        }
        @try {
            if (cdvViewController.webView.tag != kWebViewIgnoreStyle) {
                // Apply user interface definitions.
                NSDictionary *uiDict = parseJSONFile(uipath);

                if (![fileManager fileExistsAtPath:uipath]) {
                    uiDict = nil;
                }
                [[Utility currentTabBarController] applyUserInterface:uiDict];
                uiSetting = [[NSMutableDictionary dictionaryWithDictionary:uiDict] retain];

                // タブバーが存在し、かつ activeIndex が指定されている場合はその html ファイルを読む
                NSMutableDictionary *bottomDict = [uiDict objectForKey:kNCPositionBottom];
                NSString *containerType = [bottomDict objectForKey:kNCTypeContainer];
                if ([containerType isEqualToString:kNCContainerTabbar]) {
                    NSMutableDictionary *style = [bottomDict objectForKey:kNCTypeStyle];
                    NSArray *items = [bottomDict objectForKey:kNCTypeItems];
                    int activeIndex = [[style objectForKey:kNCStyleActiveIndex] intValue];
                    if (activeIndex != 0) {
                        filepath = [NSString stringWithFormat:@"/%@", [[items objectAtIndex:activeIndex] objectForKey:kNCTypeLink]];
                    }
                }
            }
            cdvViewController.webView.tag = kWebViewNormal;
        }
        @catch (NSException *exception) {
            cdvViewController.webView.tag = kWebViewNormal;
            [[Utility currentTabBarController] applyUserInterface:nil];
        }

        NSString *html = [NSString stringWithContentsOfFile:[request URL].path encoding:NSUTF8StringEncoding error:nil];
#ifndef DISABLE_MONACA_TEMPLATE_ENGINE
        NSURL *url = ((NSURL *)[NSURL fileURLWithPath:filepath]);
        html = [MonacaTemplateEngine compileFromString:html path:url.path];
#else
        if (nil == html) {
            [NSException raise:@"RuntimeException" format:@"File Not Found"];
        }
#endif  // DISABLE_MONACA_TEMPLATE_ENGINE
        html = [self hookForLoadedHTML:html request:request];

        // The |loadHTMLString| method calls the |webView:shouldStartLoadWithRequest|
        // method, so infinite loop occurs. We stop it by |recall| flag.
        self.recall = YES;
        NSString *basepath = [[NSURL fileURLWithPath:filepath] description];
        [webView_ loadHTMLString:html baseURL:[NSURL URLWithString:basepath]];

        return NO;
    }
    
    // External URL. Opens it by Safari ---
    if ([[self class] isExternalPage:url] && navigationType != UIWebViewNavigationTypeOther) {
        [[UIApplication sharedApplication] openURL:url];
        return NO;
    }
    
    self.recall = NO;
    return [cdvViewController webView:webView_ shouldStartLoadWithRequest:request navigationType:navigationType];
}

/*
 * debuggerで使いたいので作りました katsuya
 */
- (NSString *)hookForLoadedHTML:(NSString *)html request:(NSURLRequest *)aRequest {
    return html;
}

- (void) webViewDidFinishLoad:(UIWebView*) theWebView 
{
    // Black base color for background matches the native apps
    //theWebView.backgroundColor = [UIColor blackColor];
    
    [MonacaTransitPlugin webViewDidFinishLoad:theWebView viewController:self];
    
    return [cdvViewController webViewDidFinishLoad:theWebView];
}

- (void)setFixedInterfaceOrientation:(UIInterfaceOrientation)orientation
{
  interfaceOrientation = orientation;
  [self setInterfaceOrientationUnspecified:NO];
}

- (UIInterfaceOrientation)getFixedInterfaceOrientation
{
  return interfaceOrientation;
}

- (void)setInterfaceOrientationUnspecified:(BOOL)flag
{
    interfaceOrientationUnspecified = flag;
}

- (BOOL)isInterfaceOrientationUnspecified
{
    return interfaceOrientationUnspecified;
}

- (void)webViewDidStartLoad:(UIWebView *)_webView {
    [self.cdvViewController webViewDidStartLoad:_webView];
}

- (void)webView:(UIWebView *)_webView didFailLoadWithError:(NSError *)error {
    [self.cdvViewController webView:_webView didFailLoadWithError:error];
}


@end
