//
//  CDVCookieMaster.m
//
//
//  Created by Kristian Hristov on 12/16/14.
//
//

#import "CDVCookieMaster.h"
#import <WebKit/WebKit.h>


@implementation CDVCookieMaster

- (void)getCookies:(CDVInvokedUrlCommand*)command
{
   CDVPluginResult* pluginResult = nil;
   NSString* urlString = [command.arguments objectAtIndex:0];
   if (urlString != nil) {
       if ([self.webView isKindOfClass:[WKWebView class]]) {
            WKWebView* wkWebView = (WKWebView*) self.webView;
            if (@available(iOS 11.0, *)) {
                __block NSMutableDictionary* json = [NSMutableDictionary dictionary];
                [wkWebView.configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray* cookies) {
                    [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                           NSHTTPCookie *cookie = obj;
                           [json setObject:cookie.value forKey:cookie.name];
                    }];
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json
                                                                       options:NSJSONWritingPrettyPrinted
                                                                         error:&error];
                    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    __block CDVPluginResult* pluginResult = nil;
                    if (jsonString != nil) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No cookie found"];
                    }
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                    return;
                }];
                
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"WKWebView requires iOS 11+ in order to get the cookie"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

                return;
            }
        } else {
            NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:urlString]];


            __block NSMutableDictionary* json = [NSMutableDictionary dictionary];

            [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSHTTPCookie *cookie = obj;

                [json setObject:cookie.value forKey:cookie.name];

            }];

            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:NSJSONWritingPrettyPrinted error:nil];

            NSString* jsonString=[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

            if (jsonString != nil) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:jsonString];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No cookie found"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }

   } else {
       pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"URL was null"];
       [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
   }
}

 - (void)getCookieValue:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    NSString* urlString = [command.arguments objectAtIndex:0];
    __block NSString* cookieName = [command.arguments objectAtIndex:1];
    if (urlString != nil) {
        if ([self.webView isKindOfClass:[WKWebView class]]) {
            WKWebView* wkWebView = (WKWebView*) self.webView;
            if (@available(iOS 11.0, *)) {
                [wkWebView.configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray* cookies) {
                    __block NSString *cookieValue;
                 
                    [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                           NSHTTPCookie *cookie = obj;

                           if([cookie.name isEqualToString:cookieName])
                           {
                               cookieValue = cookie.value;
                               *stop = YES;
                           }
                       }];
                    if (cookieValue != nil) {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"cookieValue":cookieValue}];
                    } else {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No cookie found"];
                    }
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"WKWebView requires iOS 11+ in order to get the cookie"];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

                return;
            }
        } else {
            NSArray* cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:urlString]];
            __block NSString *cookieValue;

            [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSHTTPCookie *cookie = obj;

                if([cookie.name isEqualToString:cookieName])
                {
                    cookieValue = cookie.value;
                    *stop = YES;
                }
            }];
            if (cookieValue != nil) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"cookieValue":cookieValue}];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No cookie found"];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"URL was null"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

 - (void)setCookieValue:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* urlString = [command.arguments objectAtIndex:0];
    NSString* cookieName = [command.arguments objectAtIndex:1];
    NSString* cookieValue = [command.arguments objectAtIndex:2];

    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:cookieName forKey:NSHTTPCookieName];
    [cookieProperties setObject:cookieValue forKey:NSHTTPCookieValue];
    [cookieProperties setObject:urlString forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];

    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];

    if ([self.webView isKindOfClass:[WKWebView class]]) {
        WKWebView* wkWebView = (WKWebView*) self.webView;

        if (@available(iOS 11.0, *)) {
            [wkWebView.configuration.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:^{NSLog(@"Cookie set in WKWebView");}];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"WKWebView requires iOS 11+ in order to set the cookie"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

            return;
        }
    } else {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];

        NSArray* cookies = [NSArray arrayWithObjects:cookie, nil];

        NSURL *url = [[NSURL alloc] initWithString:urlString];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:url mainDocumentURL:nil];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Set cookie executed"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clearCookies:(CDVInvokedUrlCommand*)command
{
    NSHTTPCookie *cookie;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)clearCookie:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* urlString = [command.arguments objectAtIndex:0];
    NSString* cookieName = [command.arguments objectAtIndex:1];

    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:cookieName forKey:NSHTTPCookieName];
    [cookieProperties setObject:@"InvalidCookie" forKey:NSHTTPCookieValue];
    [cookieProperties setObject:urlString forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];

    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];

    if ([self.webView isKindOfClass:[WKWebView class]]) {
        WKWebView* wkWebView = (WKWebView*) self.webView;

        if (@available(iOS 11.0, *)) {
            [wkWebView.configuration.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:^{NSLog(@"Cookie cleared in WKWebView");}];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"WKWebView requires iOS 11+ in order to clear the cookie"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

            return;
        }
    } else {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];

        NSArray* cookies = [NSArray arrayWithObjects:cookie, nil];

        NSURL *url = [[NSURL alloc] initWithString:urlString];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookies:cookies forURL:url mainDocumentURL:nil];
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Clear cookie executed"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

@end
