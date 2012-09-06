//
//  MonacaTransitPlugin.h
//  MonacaFramework
//
//  Created by air on 12/06/28.
//  Copyright (c) 2012年 ASIAL CORPORATION. All rights reserved.
//

#import "CDVPlugin.h"

@class MonacaViewController;
@class MonacaNavigationController;

@interface MonacaTransitPlugin : CDVPlugin

+ (BOOL)changeDelegate:(UIViewController *)viewController;
+ (void)viewDidLoad:(MonacaViewController *)viewController;
+ (void)webViewDidFinishLoad:(UIWebView*)theWebView viewController:(MonacaViewController *)viewController;

- (NSString *)getRelativePathTo:(NSString *)filePath;
- (void)push:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)pop:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)modal:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)dismiss:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)home:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)browse:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
- (void)link:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
