//
//  Utils.m
//  Debugger
//
//  Created by Christopher Brew on 3/6/13.
//
//

#import "Utils.h"

#define CONFIG_FILE_NAME    @"config"
#define CONFIG_FILE_TYPE    @"plist"

#define ENV_KEY             @"env"
#define TYPE_KEY            @"type"

#define SERVICE_URL_KEY     @"service_url"
#define API_KEY_KEY         @"api_key"
#define API_SECRET_KEY      @"api_secret"
#define SESSION_ID_KEY      @"session_id"
#define TOKEN_KEY           @"token"

#define AUTO_CONNECT_KEY    @"auto_connect"
#define AUTO_PUBLISH_KEY    @"auto_publish"
#define AUTO_SUBSCRIBE_KEY  @"auto_subscribe"
#define TEST_SIGNALING_KEY  @"test_signaling"
#define TEST_TURN_TCP_KEY   @"test_turn_tcp"
#define DEBUG_LOGGING_KEY   @"debug_logging"

#define WIDGET_WIDTH_PAD    320.0
#define WIDGET_HEIGHT_PAD   240.0
#define WIDGET_WIDTH_PHONE  160.0
#define WIDGET_HEIGHT_PHONE 120.0

#define BUTTON_WIDTH_PAD    150.0
#define BUTTON_HEIGHT_PAD   80.0
#define BUTTON_WIDTH_PHONE  100.0
#define BUTTON_HEIGHT_PHONE 40.0

static NSDictionary *_sdkConfig;

@implementation Utils

+ (void)initialize {
    _sdkConfig = [NSMutableDictionary dictionary];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:CONFIG_FILE_NAME ofType:CONFIG_FILE_TYPE]];
    
    [_sdkConfig setValue:[config valueForKey:AUTO_CONNECT_KEY] forKey:AUTO_CONNECT_KEY];
    [_sdkConfig setValue:[config valueForKey:AUTO_PUBLISH_KEY] forKey:AUTO_PUBLISH_KEY];
    [_sdkConfig setValue:[config valueForKey:AUTO_SUBSCRIBE_KEY] forKey:AUTO_SUBSCRIBE_KEY];
    [_sdkConfig setValue:[config valueForKey:TEST_SIGNALING_KEY] forKey:TEST_SIGNALING_KEY];
    [_sdkConfig setValue:[config valueForKey:TEST_TURN_TCP_KEY] forKey:TEST_TURN_TCP_KEY];
    [_sdkConfig setValue:[config valueForKey:DEBUG_LOGGING_KEY] forKey:DEBUG_LOGGING_KEY];
    
    NSArray *params = @[SERVICE_URL_KEY, API_KEY_KEY, API_SECRET_KEY, SESSION_ID_KEY, TOKEN_KEY];
    NSString *env = [config valueForKey:ENV_KEY];
    NSString *type = [config valueForKey:TYPE_KEY];
    
    for (NSString *key in params) {
        id value = [config valueForKey:key];
        if (value != nil)
            [_sdkConfig setValue:value forKey:key];
    }
    
    NSDictionary *typeConfig = [config valueForKey:type];
    if (typeConfig != nil) {
        for (NSString *key in params) {
            id value = [typeConfig valueForKey:key];
            if (value != nil)
                [_sdkConfig setValue:value forKey:key];
        }
    }
    
    NSDictionary *envConfig = [config valueForKey:env];
    if (envConfig != nil) {
        for (NSString *key in params) {
            id value = [envConfig valueForKey:key];
            if (value != nil)
                [_sdkConfig setValue:value forKey:key];
        }
        
        NSDictionary *envTypeConfig = [envConfig valueForKey:type];
        if (envTypeConfig != nil) {
            for (NSString *key in params) {
                id value = [envTypeConfig valueForKey:key];
                if (value != nil)
                    [_sdkConfig setValue:value forKey:key];
            }
        }
    }
}

+ (double)widgetWidth {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return WIDGET_WIDTH_PAD;
    } else {
        return WIDGET_WIDTH_PHONE;
    }
}

+ (double)widgetHeight {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return WIDGET_HEIGHT_PAD;
    } else {
        return WIDGET_HEIGHT_PHONE;
    }
}

+ (double)buttonWidth {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return BUTTON_WIDTH_PAD;
    } else {
        return BUTTON_WIDTH_PHONE;
    }
}

+ (double)buttonHeight {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return BUTTON_HEIGHT_PAD;
    } else {
        return BUTTON_HEIGHT_PHONE;
    }
}


+ (BOOL)autoConnect {
    return [[_sdkConfig valueForKey:AUTO_CONNECT_KEY] boolValue];
}

+ (BOOL)autoPublish {
    return [[_sdkConfig valueForKey:AUTO_PUBLISH_KEY] boolValue];
}

+ (BOOL)autoSubscribe {
    return [[_sdkConfig valueForKey:AUTO_SUBSCRIBE_KEY] boolValue];
}

+ (BOOL)testSignaling {
    return [[_sdkConfig valueForKey:TEST_SIGNALING_KEY] boolValue];
}

+ (BOOL)testTurnTcp {
    return [[_sdkConfig valueForKey:TEST_TURN_TCP_KEY] boolValue];
}

+ (BOOL)debugLogging {
    return [[_sdkConfig valueForKey:DEBUG_LOGGING_KEY] boolValue];
}

+ (NSString *)serviceUrl {
    return [_sdkConfig objectForKey:SERVICE_URL_KEY];
}

+ (NSString *)apiKey {
    return [_sdkConfig objectForKey:API_KEY_KEY];
}

+ (NSString *)apiSecret {
    return [_sdkConfig objectForKey:API_SECRET_KEY];
}

+ (NSString *)sessionId {
    return [_sdkConfig objectForKey:SESSION_ID_KEY];
}

+ (NSString *)token {
    return [_sdkConfig objectForKey:TOKEN_KEY];
}

@end
