//
//  NCButton.m
//  8Card
//
//  Created by KUBOTA Mitsunori on 12/05/30.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NCButton.h"

@implementation NCButton 

@synthesize imageButtonView;

- (id)init {
    self = [super init];

    if (self) {
        self.imageButtonView = [[[UIButton alloc] init] autorelease];
    }

    return self;
}

- (void)dealloc {
    [super dealloc];
}

@end
