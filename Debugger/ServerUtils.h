//
//  ServerUtils.h
//  opentok-ios-sdk-tests
//
//  Created by Christopher Brew on 4/25/13.
//  Copyright (c) 2013 TokBox. All rights reserved.
//

#define SECONDS_PER_DAY 86400

typedef enum {
    Publisher,
    Subscriber,
    Moderator,
} TokenRole;

typedef enum {
    CongestionLevelAuto = -1,
    CongestionLevelNone = 0,
    CongestionLevelLow = 1,
    CongestionLevelHigh = 2
} CongestionLevel;

/**
 * A port of our server-side API for Objective-C. This is a little bit disjoint from the
 * havelock client, but I expect this file will end up on github one day, so we'll say it
 * makes sense.
 */
@interface ServerUtils : NSObject

+ (NSString*)generateTokenWithApiKey:(NSString *)apiKey
                           apiSecret:(NSString *)apiSecret
                           sessionId:(NSString*)sessionId
                                role:(TokenRole)tokenRole
                          expireTime:(NSDate*)expireTime
                      connectionData:(NSString*)connectionData;

+ (void)generateSessionWithApiKey:(NSString *)apiKey
                        apiSecret:(NSString *)apiSecret
                           apiUrl:(NSString *)apiUrl
                         Location:(NSString*)location
                       properties:(NSDictionary*)properties
                  completionBlock:(void (^)(NSString* sessionId))block;

+ (NSDictionary *)getSessionInfoWithSessionId:(NSString *)sessionId
                                   token:(NSString *)token;
+ (NSDictionary *)getSessionInfoWithSessionId:(NSString *)sessionId
                                   token:(NSString *)token
                       apiServerHostname:(NSString *)apiServerHostname;

+ (NSString *)getSubscriberIdWithMediaServerHostname:(NSString *)mediaServerHostname
                                            streamId:(NSString *)streamId
                                        connectionId:(NSString *)connectionId;

+ (void)setCongestionLevelWithMediaServerHostname:(NSString *)mediaServerHostname
                                     subscriberId:(NSString *)subscriberId
                                  congestionLevel:(CongestionLevel)congestionLevel;

+ (BOOL)isP2PSession:(NSString *)sessionId;

@end
