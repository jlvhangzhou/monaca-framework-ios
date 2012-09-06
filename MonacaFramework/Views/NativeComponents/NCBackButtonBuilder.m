//
//  NCBackButtonBuilder.m
//  MonacaFramework
//
//  Created by Nakagawa Hiroki on 12/01/28.
//  Copyright (c) 2012年 ASIAL CORPORATION. All rights reserved.
//

#import "NCBackButtonBuilder.h"

@implementation NCBackButtonBuilder

static UIButton *
updateBackButton(UIButton *button, NSDictionary *style) {
    BOOL invisible = isFalse([style objectForKey:kNCStyleVisibility]);
    [button setHidden:invisible];

    BOOL disable = isTrue([style objectForKey:kNCStyleDisable]);
    [button setEnabled:!disable];

    NSString *textColor = [style objectForKey:kNCStyleTextColor];
    if (textColor) {
        [button setTitleColor:hexToUIColor(removeSharpPrefix(textColor), 1) forState:UIControlStateNormal];
    }
    
    NSString *innerImagePath = [style objectForKey:kNCStyleInnerImage];
    NSString *text = [style objectForKey:kNCStyleText];

    
    if (innerImagePath) {
        NSString *imagePath = [@"www" stringByAppendingPathComponent:innerImagePath];
        UIImage *image = [UIImage imageNamed:imagePath];
        if (image) {
            [button setImage:image forState:UIControlStateNormal];
            [button setImageEdgeInsets:UIEdgeInsetsMake(0, 2, 0, -2)];
        }
    } else if (text) {
        [button setTitle:text forState:UIControlStateNormal];
    }

    // FIXME: A shape of the button changes into a rectangle when the color of it is modified.
    /*
    NSString *bgColor = [style objectForKey:kNCStyleBackgroundColor];
    if (bgColor) {
        [button setTintColor:hexToUIColor(removeSharpPrefix(bgColor), 1)];
    }
     */

    return button;
}

+ (UIButton *)backButton:(NSDictionary *)style {
    UIButton *button = [UIButton buttonWithType:101];
    return updateBackButton(button, style);
}

+ (UIBarButtonItem *)update:(UIBarButtonItem *)button with:(NSDictionary *)style {
    button.customView = updateBackButton((UIButton *)button.customView, style);
    [button setWidth:0];
    return button;
}

@end
