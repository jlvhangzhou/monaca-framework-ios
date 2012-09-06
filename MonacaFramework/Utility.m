//
//  Utility.m
//  Template
//
//  Created by Hiroki Nakagawa on 11/06/07.
//  Copyright 2011 ASIAL CORPORATION. All rights reserved.
//

#import "Utility.h"


@implementation Utility

+ (MonacaTabBarController *)currentTabBarController {
    return (MonacaTabBarController *)((MonacaDelegate *)[UIApplication sharedApplication].delegate).viewController.tabBarController;
}

+ (UIInterfaceOrientation)currentInterfaceOrientation {
    MonacaDelegate *delegate = ((MonacaDelegate *)[UIApplication sharedApplication].delegate);
    return [delegate currentInterfaceOrientation];
}

+ (BOOL)getAllowOrientationFromPlist:(UIInterfaceOrientation)interfaceOrientation {
    NSDictionary *orientationkv = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithInt:UIInterfaceOrientationPortrait],@"UIInterfaceOrientationPortrait",
                                   [NSNumber numberWithInt:UIInterfaceOrientationPortraitUpsideDown],@"UIInterfaceOrientationPortraitUpsideDown",
                                   [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight],@"UIInterfaceOrientationLandscapeRight",
                                   [NSNumber numberWithInt:UIInterfaceOrientationLandscapeLeft],@"UIInterfaceOrientationLandscapeLeft",nil];
    NSString *key = @"UISupportedInterfaceOrientations";
    NSArray *values = [[[NSBundle mainBundle] infoDictionary] objectForKey:key];
    for (NSString *value in values){
        NSNumber *num = (NSNumber *)[orientationkv objectForKey:value];
        if(interfaceOrientation == (UIInterfaceOrientation)[num intValue]){
            return YES;
        }
    }
    return NO;
}

/*
 * 4.3と5.1の互換性を保ちつつ、MonacaViewControllerをセットアップする
 */
+ (void) setupMonacaViewController:(MonacaViewController *)monacaViewController{
    if ([Device iOSVersionMajor] < 5) {
    }else{
        BOOL forceStartupRotation = YES;
        UIDeviceOrientation curDevOrientation = [[UIDevice currentDevice] orientation];
        if (UIDeviceOrientationUnknown == curDevOrientation) {
            curDevOrientation = (UIDeviceOrientation)[[UIApplication sharedApplication] statusBarOrientation];
        }
        if (UIDeviceOrientationIsValidInterfaceOrientation(curDevOrientation)) {
            for (NSNumber *orient in monacaViewController.cdvViewController.supportedOrientations) {
                if ([orient intValue] == curDevOrientation) {
                    forceStartupRotation = NO;
                    break;
                }
            }
        }
        if (forceStartupRotation) {
            UIInterfaceOrientation newOrient = [[monacaViewController.cdvViewController.supportedOrientations objectAtIndex:0] intValue];
            [[UIApplication sharedApplication] setStatusBarOrientation:newOrient];
        }
    }
}

/*
 * 表示される時のレイアウトを修正する
 */
+ (void) fixedLayout:(MonacaViewController *)monacaViewController interfaceOrientation:(UIInterfaceOrientation)aInterfaceOrientation{
    if (aInterfaceOrientation == UIInterfaceOrientationPortrait || aInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
        monacaViewController.view.frame = [[UIScreen mainScreen] bounds];
        UIViewController *vc = [monacaViewController.tabBarController.viewControllers objectAtIndex:0];
        [vc setWantsFullScreenLayout:YES];
    }
}

/*
 * 404 page
 */
+ (void) show404PageWithWebView:(UIWebView *)webView path:(NSString *)aPath {
    NSString *pathFor404 = [[NSBundle mainBundle] pathForResource:@"404/index" ofType:@"html"];
    NSString *html = [NSString stringWithContentsOfFile:pathFor404 encoding:NSUTF8StringEncoding error:nil];
    NSString *shortPath = [Utility getWWWShortPath:aPath];

    html = [html stringByReplacingOccurrencesOfString:@"%%%urlPlaceHolder%%%" withString:shortPath];
    html = [html stringByReplacingOccurrencesOfString:@"%%%backButtonText%%%" withString:NSLocalizedString(@"back", nil)];

    [webView loadHTMLString:html baseURL:[NSURL fileURLWithPath:pathFor404]];
    [[Utility currentTabBarController] applyUserInterface:nil];
}

/*
 *  convert path (ex 1234/xxxx/www/yyy.html -> www/yyy.html)
 */
+ (NSString *)getWWWShortPath:(NSString *)path{
    NSMutableArray *array = [NSMutableArray arrayWithArray:[path componentsSeparatedByString:@"www/"]];
    [array removeObjectAtIndex:0];
    return [@"www" stringByAppendingPathComponent:[array objectAtIndex:0]];
}

@end
