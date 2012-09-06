//
//  MonacaURLCache.h
//  MonacaFramework
//
//  Created by Katsuya SAITO on 12/07/12.
//  Copyright (c) 2012å¹´ ASIAL CORPORATION. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MonacaURLCache : NSURLCache {
    NSMutableDictionary *cacheList;
}

@end
