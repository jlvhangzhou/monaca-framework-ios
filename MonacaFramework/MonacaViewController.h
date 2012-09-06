//
//  MonacaViewController.h
//  Template
//
//  Created by Hiroki Nakagawa on 11/06/07.
//  Copyright 2011 ASIAL CORPORATION. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CDVViewController.h"

@class MonacaDelegate;
@class MonacaTabBarController;

@interface MonacaViewController : UIViewController <UIScrollViewDelegate, UIWebViewDelegate> {
 @private
    UINavigationController *appNavigationController;
    MonacaTabBarController *tabBarController;
    CDVViewController *cdvViewController;
    
    UIScrollView *scrollView_;
    UIInterfaceOrientation interfaceOrientation;
    
    NSString *previousPath_;
    CDVWhitelist *monacaWhitelist;
    BOOL recall_;
    BOOL interfaceOrientationUnspecified;
    NSMutableDictionary *uiSetting;
}

+ (BOOL)isPhoneGapScheme:(NSURL *)url;
+ (BOOL)isExternalPage:(NSURL *)url;

- (id)initWithFileName:(NSString *)fileName;
- (void)setFixedInterfaceOrientation:(UIInterfaceOrientation)orientation;
- (UIInterfaceOrientation)getFixedInterfaceOrientation;
- (void)setInterfaceOrientationUnspecified:(BOOL)flag;
- (BOOL)isInterfaceOrientationUnspecified;

- (NSString *)hookForLoadedHTML:(NSString *)html request:(NSURLRequest *)aRequest;

@property (nonatomic, assign) BOOL recall;
@property (nonatomic, copy) NSString *previousPath;
@property(nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) NSDictionary *monacaPluginOptions;

@property (nonatomic, retain) UINavigationController *appNavigationController;
@property (nonatomic, retain) CDVViewController *cdvViewController;
@property (nonatomic, retain) MonacaTabBarController *tabBarController;

@end
