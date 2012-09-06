//
//  MonacaTransitPlugin.m
//  MonacaFramework
//
//  Created by air on 12/06/28.
//  Copyright (c) 2012年 ASIAL CORPORATION. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "MonacaTransitPlugin.h"
#import "MonacaDelegate.h"
#import "MonacaViewController.h"
#import "MonacaTabBarController.h"

#define kMonacaTransitPluginJsReactivate @"window.onReactivate"
#define kMonacaTransitPluginOptionUrl @"url"
#define kMonacaTransitPluginOptionBg  @"bg"

@implementation MonacaTransitPlugin

#pragma mark - private methods

- (MonacaDelegate *)monacaDelegate
{
    return (MonacaDelegate *)[self appDelegate];
}

- (MonacaNavigationController *)monacaNavigationController
{
    return [[self monacaDelegate] monacaNavigationController];
}

- (NSURLRequest *)createRequest:(NSString *)urlString
{
    // wwwDir上の現在のパスから、アプリケーションの相対パスに変換
    NSString *currentDirectory = [[self monacaDelegate].viewController.cdvViewController.webView.request.URL URLByDeletingLastPathComponent].filePathURL.path;
    urlString = [currentDirectory stringByAppendingPathComponent:urlString];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[urlString componentsSeparatedByString:@"www/"]];
    [array removeObjectAtIndex:0];
    urlString = [[array valueForKey:@"description"] componentsJoinedByString:@""];
    
    NSURL *url;
    if ([self.commandDelegate pathForResource:urlString]){
        url = [NSURL fileURLWithPath:[self.commandDelegate pathForResource:urlString]]; 
    }else {
        url = [NSURL URLWithString:[@"monaca404:///www/" stringByAppendingPathComponent:urlString]];
    }
    return [NSURLRequest requestWithURL:url];
}

// @see [MonacaDelegate application: didFinishLaunchingWithOptions:]
- (void)setupViewController:(MonacaViewController *)viewController url:(NSString *)url options:(NSDictionary *)options
{
    viewController.monacaPluginOptions = options;
    [Utility setupMonacaViewController:viewController];
}

+ (void)setBgColor:(MonacaViewController *)viewController color:(UIColor *)color
{
    viewController.cdvViewController.webView.backgroundColor = [UIColor clearColor];
    viewController.cdvViewController.webView.opaque = NO;

    UIScrollView *scrollView = nil;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) {
        for (UIView *subview in [viewController.cdvViewController.webView subviews]) {
            if ([[subview.class description] isEqualToString:@"UIScrollView"]) {
                scrollView = (UIScrollView *)subview;
            }
        }
    } else {
        scrollView = (UIScrollView *)[viewController.cdvViewController.webView scrollView];
    }

    if (scrollView) {
        scrollView.opaque = NO;
        scrollView.backgroundColor = [UIColor clearColor];
        // Remove shadow
        for (UIView *subview in [scrollView subviews]) {
            if([subview isKindOfClass:[UIImageView class]]){
                subview.hidden = YES;
            }
        }
    }

    viewController.view.opaque = YES;
    viewController.view.backgroundColor = color;
}

#pragma mark - public methods

+ (BOOL)changeDelegate:(UIViewController *)viewController
{
    if(![viewController isKindOfClass:[MonacaViewController class]]){
        return NO;
    }

    MonacaDelegate *monacaDelegate = (MonacaDelegate *)[[UIApplication sharedApplication] delegate];
    NSMutableDictionary *pluginObjects = monacaDelegate.viewController.cdvViewController.pluginObjects;
    monacaDelegate.viewController = (MonacaViewController *)viewController;
    for (id key in pluginObjects) {
        CDVPlugin *plugin = [pluginObjects objectForKey:key];
        [plugin setViewController:viewController];
        [plugin setWebView:((MonacaViewController *)viewController).cdvViewController.webView];
    }

    return YES;
}

#pragma mark - MonacaViewController actions

+ (void)viewDidLoad:(MonacaViewController *)viewController
{
    if(![viewController isKindOfClass:[MonacaViewController class]]) {
        return;
    }

    if (viewController.monacaPluginOptions) {
        NSString *bgName = [viewController.monacaPluginOptions objectForKey:kMonacaTransitPluginOptionBg];
        if (bgName) {
            NSString *bgPath = [viewController.cdvViewController pathForResource:bgName];
            UIImage *bgImage = [UIImage imageWithContentsOfFile:bgPath];
            if (bgImage) {
                [[self class] setBgColor:viewController color:[UIColor colorWithPatternImage:bgImage]];
            }
        }
    }
}

+ (void)webViewDidFinishLoad:(UIWebView*)theWebView viewController:(MonacaViewController *)viewController
{
    if (!viewController.monacaPluginOptions || ![viewController.monacaPluginOptions objectForKey:kMonacaTransitPluginOptionBg]) {
        theWebView.backgroundColor = [UIColor blackColor];
    }
}

- (NSString *)getRelativePathTo:(NSString *)filePath{
    NSString *currentDirectory = [[self monacaDelegate].viewController.cdvViewController.webView.request.URL URLByDeletingLastPathComponent].filePathURL.path;
    NSString *urlString = [currentDirectory stringByAppendingPathComponent:filePath];
    NSMutableArray *array = [NSMutableArray arrayWithArray:[urlString componentsSeparatedByString:@"www/"]];
    [array removeObjectAtIndex:0];
    return [[array valueForKey:@"description"] componentsJoinedByString:@""];
}

#pragma mark - plugins methods

- (void)push:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    NSString *fileName = [arguments objectAtIndex:1];
    NSString *urlString = [self getRelativePathTo:fileName];

    MonacaViewController *viewController = [[[MonacaViewController alloc] initWithFileName:urlString] autorelease];
    [self setupViewController:viewController url:fileName options:options];
    [[self class] changeDelegate:viewController];
    
    [[self monacaNavigationController] pushViewController:viewController animated:YES];
}

- (void)pop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    MonacaNavigationController *nav = [self monacaNavigationController];
    NSLog(@"count: %d, %@", [[nav viewControllers] count], [[nav viewControllers] lastObject]);
    [nav popViewControllerAnimated:YES];
    NSLog(@"count: %d, %@", [[nav viewControllers] count], [[nav viewControllers] lastObject]);

    BOOL res = [[self class] changeDelegate:[[nav viewControllers] lastObject]];
    if (res) {
        NSString *command =[NSString stringWithFormat:@"%@ && %@();", kMonacaTransitPluginJsReactivate, kMonacaTransitPluginJsReactivate];
        [self writeJavascript:command];
        NSLog(@"vc: %@", self.viewController);
    }
}

- (void)modal:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    NSString *fileName = [arguments objectAtIndex:1];
    NSString *urlString = [self getRelativePathTo:fileName];

    MonacaViewController *viewController = [[[MonacaViewController alloc] initWithFileName:urlString] autorelease];
    [self setupViewController:viewController url:fileName options:options];
    [[self class] changeDelegate:viewController];

    NSString *transitionSubtype;
    UIInterfaceOrientation orientation = viewController.interfaceOrientation;
    switch (orientation) {
        case UIInterfaceOrientationPortrait: // Device oriented vertically, home button on the bottom
            transitionSubtype = kCATransitionFromTop;
            break;
        case UIInterfaceOrientationPortraitUpsideDown: // Device oriented vertically, home button on the top
            transitionSubtype = kCATransitionFromBottom;
            break;
        case UIInterfaceOrientationLandscapeLeft: // Device oriented horizontally, home button on the right
            transitionSubtype = kCATransitionFromRight;
            break;
        case UIInterfaceOrientationLandscapeRight: // Device oriented horizontally, home button on the left
            transitionSubtype = kCATransitionFromLeft;
            break;
        default:
            transitionSubtype = kCATransitionFromTop;
            break;
    }

    CATransition *transition = [CATransition animation];
    transition.duration = 0.4f;
    transition.type = kCATransitionMoveIn;
    transition.subtype = transitionSubtype;
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];

    MonacaNavigationController *nav = [self monacaNavigationController];
    [nav.view.layer addAnimation:transition forKey:kCATransition];
    [nav pushViewController:viewController animated:NO];
}

- (void)dismiss:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    NSString *transitionSubtype;
    UIInterfaceOrientation orientation = self.viewController.interfaceOrientation;
    switch (orientation) {
        case UIInterfaceOrientationPortrait: // Device oriented vertically, home button on the bottom
            transitionSubtype = kCATransitionFromBottom;
            break;
        case UIInterfaceOrientationPortraitUpsideDown: // Device oriented vertically, home button on the top
            transitionSubtype = kCATransitionFromTop;
            break;
        case UIInterfaceOrientationLandscapeLeft: // Device oriented horizontally, home button on the right
            transitionSubtype = kCATransitionFromLeft;
            break;
        case UIInterfaceOrientationLandscapeRight: // Device oriented horizontally, home button on the left
            transitionSubtype = kCATransitionFromRight;
            break;
        default:
            transitionSubtype = kCATransitionFromBottom;
            break;
    }

    CATransition *transition = [CATransition animation];
    transition.duration = 0.4f;
    transition.type = kCATransitionReveal;
    transition.subtype = transitionSubtype;
    [transition setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault]];

    MonacaNavigationController *nav = [self monacaNavigationController];
    [nav.view.layer addAnimation:transition forKey:kCATransition];
    [nav popViewControllerAnimated:NO];

    BOOL res = [[self class] changeDelegate:[[nav viewControllers] lastObject]];
    if (res) {
        NSString *command =[NSString stringWithFormat:@"%@ && %@();", kMonacaTransitPluginJsReactivate, kMonacaTransitPluginJsReactivate];
        [self writeJavascript:command];
    }
}

- (void)home:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    NSString *fileName = [options objectForKey:kMonacaTransitPluginOptionUrl];

    UINavigationController *nav = [self monacaNavigationController];
    [nav popToRootViewControllerAnimated:YES];

    UIViewController *viewController = [[nav viewControllers] objectAtIndex:0];
    BOOL res = [[self class] changeDelegate:viewController];
    if (res) {
        if (fileName) {
            [self.webView loadRequest:[self createRequest:fileName]];
        }
        NSString *command =[NSString stringWithFormat:@"%@ && %@();", kMonacaTransitPluginJsReactivate, kMonacaTransitPluginJsReactivate];
        [self writeJavascript:command];
    }
}

- (void)browse:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    NSString *urlString = [arguments objectAtIndex:1];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

- (void)link:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
    NSString *fileName = [arguments objectAtIndex:1];
    [[self monacaDelegate].viewController.cdvViewController.webView loadRequest:[self createRequest:fileName]];
}

@end
