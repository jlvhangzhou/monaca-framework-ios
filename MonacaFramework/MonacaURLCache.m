//
//  MonacaURLCache.m
//  MonacaFramework
//
//  Created by Katsuya SAITO on 12/07/12.
//  Copyright (c) 2012å¹´ ASIAL CORPORATION. All rights reserved.
//

#import "MonacaURLCache.h"
#import "CDVWhitelist.h"
#import "MonacaDelegate.h"

@interface MonacaURLCache ()

- (void)storeMonacaCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request;
- (NSCachedURLResponse *)getNullResponse;

@end


@implementation MonacaURLCache

- (id)init {
    self = [super init];
    if (self) {
        cacheList = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (NSCachedURLResponse *)cachedResponseForRequest:(NSURLRequest *)request {
    NSURL *url = [request URL];
    
    // ExternalHostsによるAJAXコンテンツフィルタ
    if ([[url scheme] isEqualToString:@"http"]){
        @try {
            MonacaDelegate *delegate = (MonacaDelegate *)[[UIApplication sharedApplication] delegate];
            NSArray *externalHosts = [delegate getExternalHosts];
            CDVWhitelist *monacaWhitelist = [[CDVWhitelist alloc] initWithArray:externalHosts];
            
            if ([monacaWhitelist schemeIsAllowed:[url scheme]]) {
                if ([monacaWhitelist URLIsAllowed:url] == NO) {
                    [self storeMonacaCachedResponse:[self getNullResponse] forRequest:request];
                }
            }
            return [cacheList objectForKey:request.URL.absoluteString];
        }
        @catch (NSException *exception) {
            NSLog(@"failed to try monaca rejection.");
            return [self getNullResponse];
        }
    }
    //file protocolではnullを返すことで、リソースから取得する
    return nil;
}

- (void)storeMonacaCachedResponse:(NSCachedURLResponse *)cachedResponse forRequest:(NSURLRequest *)request {
    [cacheList setObject:cachedResponse forKey:request.URL.absoluteString];
}


- (NSCachedURLResponse *)getNullResponse {
    NSURLResponse *response = [[[NSURLResponse alloc] initWithURL:nil
                                                         MIMEType:@"text/plain"
                                            expectedContentLength:1
                                                 textEncodingName:nil] autorelease];
    NSCachedURLResponse *cachedResponse = [[[NSCachedURLResponse alloc] initWithResponse:response
                                                                                    data:[NSData dataWithBytes:" " length:1]] autorelease];
    return cachedResponse;
}

- (void)dealloc {
    [cacheList release];
    [super dealloc];
}

@end