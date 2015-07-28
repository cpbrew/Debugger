//
//  ServerUtils.m
//  opentok-ios-sdk-tests
//
//  Created by Christopher Brew on 4/25/13.
//  Copyright (c) 2013 TokBox. All rights reserved.
//

#import "ServerUtils.h"
#import <CommonCrypto/CommonHMAC.h>
#import <mach/mach_time.h>
#import "NSData+Base64.h"
#import "NSData+HexString.h"
#import "TestXMLNode.h"

#define HTTP_OK                 200
#define API_SERVER_HOSTNAME     @"https://anvil.opentok.com"
#define CONGESTION_REQUEST_BODY @"{\"manual_override\": { \"congestion_event\": %@}}"
#define CONGESTION_EVENT_AUTO   @"{\"enable\": false}"
#define CONGESTION_EVENT_NONE   @"{\"enable\": true, \"value\":0}"
#define CONGESTION_EVENT_LOW    @"{\"enable\": true, \"value\":1}"
#define CONGESTION_EVENT_HIGH   @"{\"enable\": true, \"value\":2}"

@implementation ServerUtils

static NSString *urlEncode(id object) {
    NSString *string = [NSString stringWithFormat:@"%@", object];
    return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}

+ (NSString *)urlEncodedStringFromDictionary:(NSDictionary *)dictionary {
    NSMutableArray *parts = [NSMutableArray array];
    for (id key in dictionary) {
        id value = [dictionary objectForKey:key];
        NSString *part = [NSString stringWithFormat:@"%@=%@", urlEncode(key), urlEncode(value)];
        [parts addObject:part];
    }
    return [parts componentsJoinedByString:@"&"];
}

+ (NSString *)generateTokenWithApiKey:(NSString *)apiKey
                            apiSecret:(NSString *)apiSecret
                            sessionId:(NSString *)sessionId
                                 role:(TokenRole)tokenRole
                           expireTime:(NSDate *)expireTime
                       connectionData:(NSString *)connectionData {
    srandom((unsigned int)mach_absolute_time());
    double epochTimeNow = [[[NSDate alloc] init] timeIntervalSince1970];
    NSString *nonce = [NSString stringWithFormat:@"%0.f%ld", epochTimeNow * USEC_PER_SEC, random()];
    NSString *role;
    switch (tokenRole) {
        case Moderator:
            role = @"moderator";
            break;
        case Subscriber:
            role = @"subscriber";
            break;
        case Publisher:
            role = @"publisher";
            break;
    }
    NSString *dataString = [NSString stringWithFormat:@"session_id=%@&create_time=%0.f&role=%@&nonce=%@",sessionId,epochTimeNow,role,nonce];
    if (connectionData != nil) {
        if ([connectionData length] < 1000) {
            dataString = [NSString stringWithFormat:@"%@&connection_data=%@", dataString, connectionData];
        } else {
            NSLog(@"Token connection data must be less than 1000 characters.");
        }
    }
    
    const char *cKey  = [apiSecret cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [dataString cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *signature = [[NSData alloc] initWithBytes:cHMAC
                                               length:sizeof(cHMAC)];
    
    NSString *token = [NSData base64EncodedStringFromData:[[NSString stringWithFormat:@"partner_id=%@&sig=%@:%@", apiKey, [signature hexString], dataString] dataUsingEncoding:NSUTF8StringEncoding]];
    return [NSString stringWithFormat:@"T1==%@", token];
}

+ (void)generateSessionWithApiKey:(NSString *)apiKey
                        apiSecret:(NSString *)apiSecret
                           apiUrl:(NSString *)apiUrl
                         Location:(NSString *)location
                       properties:(NSDictionary *)properties
                  completionBlock:(void (^)(NSString *sessionId))block {
    
    NSMutableDictionary *myProperties = [[NSMutableDictionary alloc] init];
    if (properties != nil) {
        [myProperties addEntriesFromDictionary:properties];
    }
    [myProperties setValue:location forKey:@"location"];
    [myProperties setValue:apiKey forKey:@"api_key"];
    
    NSURL *sessionCreateURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/session/create", apiUrl]];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:sessionCreateURL
                                                                   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                               timeoutInterval:3.0f];
    
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:[NSString stringWithFormat:@"%@:%@", apiKey, apiSecret] forHTTPHeaderField:@"X-TB-PARTNER-AUTH"];
    
    [urlRequest setHTTPBody:[[ServerUtils urlEncodedStringFromDictionary:myProperties] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               
                               if (!error) {
                                   NSString *xmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   TestXMLNode *xmlRoot = [TestXMLNode newXmlNodeWithUTF8String:xmlString];
                                   if (![[xmlRoot.name lowercaseString] isEqualToString:@"error"]) {
                                       TestXMLNode *sessionNode = [xmlRoot childNodeForName:@"Session"];
                                       TestXMLNode *sessionIdNode = [sessionNode childNodeForName:@"session_id"];
                                       NSString *sessionId = sessionIdNode.text;
                                       block(sessionId);
                                   } else {
                                       NSLog(@"Failed to generate session: bad response %@", xmlString);
                                       block(nil);
                                   }
                               } else {
                                   NSLog(@"Failed to generate session. Request failed with error %@", [error description]);
                                   block(nil);
                               }
                               
                           }];
}

+ (NSDictionary *)getSessionInfoWithSessionId:(NSString *)sessionId
                                        token:(NSString *)token {
    return [ServerUtils getSessionInfoWithSessionId:sessionId
                                              token:token
                                  apiServerHostname:API_SERVER_HOSTNAME];
}

+ (NSDictionary *)getSessionInfoWithSessionId:(NSString *)sessionId
                                        token:(NSString *)token
                            apiServerHostname:(NSString *)apiServerHostname {
    NSURL *getSessionURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/session/%@", apiServerHostname, sessionId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:getSessionURL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:3.0f];
    [request setHTTPMethod:@"GET"];
    [request setValue:token forHTTPHeaderField:@"X-TB-TOKEN-AUTH"];
    [request setValue:@"1" forHTTPHeaderField:@"X-TB-VERSION"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error != nil) {
        NSLog(@"Failed to get session info. Request failed with error: %@", [error localizedDescription]);
        return nil;
    }
    if ([response statusCode] != HTTP_OK) {
        NSLog(@"Failed to get session info. Request returned response code: %ld", (long)[response statusCode]);
        return nil;
    }
    
    NSArray *sessionInfo = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    if (error != nil) {
        NSLog(@"Failed to parse session info. Bad response: %@", [NSString stringWithUTF8String:[responseData bytes]]);
        return nil;
    }
    
    return [sessionInfo objectAtIndex:0];
}

+ (NSString *)getSubscriberIdWithMediaServerHostname:(NSString *)mediaServerHostname
                                            streamId:(NSString *)streamId
                                        connectionId:(NSString *)connectionId {
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:7778/server/client", mediaServerHostname]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:3.0f];
    [request setHTTPMethod:@"GET"];
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error != nil) {
        NSLog(@"Failed to get subscriber id. Request failed with error: %@", [error localizedDescription]);
        return nil;
    }
    if ([response statusCode] != HTTP_OK) {
        NSLog(@"Failed to get subscriber id. Request returned response code: %ld", (long)[response statusCode]);
        return nil;
    }
    
    NSArray *responseArray = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];
    if (error != nil) {
        NSLog(@"Failed to get subscriber id. Bad response: %@", [NSString stringWithUTF8String:[responseData bytes]]);
        return nil;
    }
    
    for (NSDictionary *client in responseArray) {
        if ([@"Subscriber" isEqualToString:[client objectForKey:@"widgetType"]] &&
            [streamId isEqualToString:[client objectForKey:@"streamId"]] &&
            [connectionId isEqualToString:[client objectForKey:@"connectionId"]]) {
            return [client objectForKey:@"id"];
        }
    }
    
    NSLog(@"Failed to get subscriber id. Could not find a matching client.");
    return nil;
}

+ (void)setCongestionLevelWithMediaServerHostname:(NSString *)mediaServerHostname
                                     subscriberId:(NSString *)subscriberId
                                  congestionLevel:(CongestionLevel)congestionLevel {
    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@:7778/client/%@", mediaServerHostname, subscriberId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:3.0f];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    
    NSString *congestionEvent = nil;
    switch (congestionLevel) {
        case CongestionLevelAuto:
            congestionEvent = CONGESTION_EVENT_AUTO;
            break;
            
        case CongestionLevelNone:
            congestionEvent = CONGESTION_EVENT_NONE;
            break;
            
        case CongestionLevelLow:
            congestionEvent = CONGESTION_EVENT_LOW;
            break;
            
        case CongestionLevelHigh:
            congestionEvent = CONGESTION_EVENT_HIGH;
            break;
            
        default:
            @throw [NSException exceptionWithName:@"wtf" reason:@"unrecognized congestion level" userInfo:nil];
            break;
    }
    NSString *httpBodyContent = [NSString stringWithFormat:CONGESTION_REQUEST_BODY, congestionEvent];
    [request setHTTPBody:[httpBodyContent dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error != nil) {
        NSLog(@"Failed to set congestion level. Request failed with error: %@", [error localizedDescription]);
    } else if ([response statusCode] != HTTP_OK) {
        NSLog(@"Failed to set congestion level. Request returned response code: %ld", (long)[response statusCode]);
    }
}

+ (BOOL)isP2PSession:(NSString *)sessionId {
    sessionId = [sessionId substringFromIndex:2];
    
    NSMutableArray *parts = [NSMutableArray arrayWithArray:[sessionId componentsSeparatedByString:@"-"]];
    if ([@"" isEqualToString:[parts lastObject]]) {
        [parts removeLastObject];
    }
    
    NSData *data = [NSData dataFromBase64String:[parts lastObject]];
    NSString *decodedPart = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    parts = [NSMutableArray arrayWithArray:[decodedPart componentsSeparatedByString:@"~"]];
    if ([@"" isEqualToString:[parts lastObject]]) {
        [parts removeLastObject];
    }
    
    return [@"P" isEqualToString:[parts lastObject]];
}

@end
