//
//  NCSearchBar.m
//  8Card
//
//  Created by KUBOTA Mitsunori on 12/05/29.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NCSearchBar.h"

@implementation NCSearchBar

- (id)init {
    id result = [super init];
    
    if (result) {
        [[NSNotificationCenter defaultCenter] addObserver:result
                                                 selector:@selector(didRotate:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        _type = kNCSearchBarTypeDefault;
        [result updateFrameForOrieantionAndType];
    }
    
    return result;
}

- (void)viewDidLoad {
    [self updateFrameForOrieantionAndType];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:UIDeviceOrientationDidChangeNotification 
                                                    object:nil];
    
    [super dealloc];
}

- (void)updateFrameForOrieantionAndType {
    UIDeviceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];//[[UIDevice currentDevice] orientation];
    
    
    if (_type == kNCSearchBarTypeCenter) {
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 220, 44);
        } else {
            // original * 2.0
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 360, 44);
        }
        
    } else {
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 110, 44);
        } else {
            // original * 1.5
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, 165, 44);
        }
    }
}

- (void)didRotate:(NSNotification *)notification {
    [self updateFrameForOrieantionAndType];
}

- (void)setNCSearchBarType:(NCSearchBarType)type {
    _type = type;
    [self updateFrameForOrieantionAndType];
}

@end
