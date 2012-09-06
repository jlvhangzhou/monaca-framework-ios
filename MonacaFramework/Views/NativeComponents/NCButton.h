//
//  NCButton.h
//  8Card
//
//  Created by KUBOTA Mitsunori on 12/05/30.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCButton : UIBarButtonItem {
    UIView* _imageButtonView;
}

@property (retain) UIView* imageButtonView;
@end
