//
//  MonacaFrameworkDelegate.m
//  Template
//
//  Created by Hiroki Nakagawa on 11/06/07.
//  Copyright 2011 ASIAL CORPORATION. All rights reserved.
//

#import "MonacaDelegate.h"
#import "MonacaViewController.h"
#import "MonacaTabBarController.h"
#import "NativeComponents.h"
#import "MonacaURLProtocol.h"
#import "MonacaURLCache.h"

#import "Utility.h"

#ifndef DISABLE_MONACA_TEMPLATE_ENGINE
#import "MonacaTemplateEngine.h"
#endif  // DISABLE_MONACA_TEMPLATE_ENGINE

@class MonacaViewController;

// =====================================================================
// MonacaDelegate class.
// =====================================================================

@implementation MonacaDelegate

@synthesize monacaNavigationController = monacaNavigationController_;
@synthesize window;
@synthesize viewController = viewController_;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //[NSURLCache setSharedURLCache:[[[MonacaURLCache alloc] init] autorelease]];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    self.viewController = [[[MonacaViewController alloc] initWithFileName:@"index.html"] autorelease];
    [Utility setupMonacaViewController:self.viewController];
    
    self.monacaNavigationController = [[[MonacaNavigationController alloc] initWithRootViewController:self.viewController] autorelease];
    
    self.window.rootViewController = self.monacaNavigationController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (NSURL *)getBaseURL {
    NSString *base_path = [NSString stringWithFormat:@"%@/www", [[NSBundle mainBundle] bundlePath]];
    return [NSURL fileURLWithPath:base_path];
}

- (UIInterfaceOrientation)currentInterfaceOrientation{
    return self.monacaNavigationController.interfaceOrientation;
}

- (NSArray *)getExternalHosts {
    return [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"ExternalHosts"] autorelease];
}

@end
