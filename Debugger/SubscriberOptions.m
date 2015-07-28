//
//  SubscriberOptions.m
//  Debugger
//
//  Created by Christopher Brew on 6/24/13.
//
//

#import "SubscriberOptions.h"
#import <OpenTok/OpenTok.h>
#import "OptionsMenu.h"
#import "Utils.h"

#define SUBSCRIBE_TO_AUDIO_KEY  @"subscribeToAudio"
#define SUBSCRIBE_TO_VIDEO_KEY  @"subscribeToVideo"
#define CONGESTION_LEVEL_KEY    @"congestionLevel"
#define CONGESTION_LEVEL_AUTO   @"auto"
#define CONGESTION_LEVEL_NONE   @"none"
#define CONGESTION_LEVEL_LOW    @"low"
#define CONGESTION_LEVEL_HIGH   @"high"

@interface SubscriberOptions () <OptionsMenuDelegate> @end

@implementation SubscriberOptions {
    bool _subscribeToAudio;
    bool _subscribeToVideo;
    CongestionLevel _congestionLevel;
    
    OTSubscriber *_subscriber;
}

@dynamic subscribeToAudio;
@dynamic subscribeToVideo;
@dynamic congestionLevel;

@dynamic subscriber;

- (id)init {
    if (self = [super init]) {
        _subscribeToAudio = YES;
        _subscribeToVideo = YES;
        _congestionLevel = CongestionLevelAuto;
    }
    return self;
}

- (bool)subscribeToAudio {
    return _subscribeToAudio;
}

- (void)setSubscribeToAudio:(bool)subscribeToAudio {
    _subscribeToAudio = subscribeToAudio;
    _subscriber.subscribeToAudio = _subscribeToAudio;
}

- (bool)subscribeToVideo {
    return _subscribeToVideo;
}

- (void)setSubscribeToVideo:(bool)subscribeToVideo {
    _subscribeToVideo = subscribeToVideo;
    _subscriber.subscribeToVideo = _subscribeToVideo;
}

- (CongestionLevel)congestionLevel {
    return _congestionLevel;
}

- (void)setCongestionLevel:(CongestionLevel)congestionLevel {
    _congestionLevel = congestionLevel;
    
    NSString *token = Utils.token;
    if (token == nil) {
        token = [ServerUtils generateTokenWithApiKey:Utils.apiKey
                                           apiSecret:Utils.apiSecret
                                           sessionId:_subscriber.session.sessionId
                                                role:Moderator
                                          expireTime:[NSDate dateWithTimeIntervalSinceNow:SECONDS_PER_DAY]
                                      connectionData:nil];
    }
    NSDictionary *sessionInfo = nil;
    if (Utils.serviceUrl == nil) {
        sessionInfo = [ServerUtils getSessionInfoWithSessionId:_subscriber.session.sessionId
                                                         token:token];
    } else {
        sessionInfo = [ServerUtils getSessionInfoWithSessionId:_subscriber.session.sessionId
                                                         token:token
                                             apiServerHostname:Utils.serviceUrl];
    }
    NSString *mediaServerHostname = [sessionInfo objectForKey:@"media_server_hostname"];
    NSString *subscriberId = [ServerUtils getSubscriberIdWithMediaServerHostname:mediaServerHostname
                                                                        streamId:_subscriber.stream.streamId
                                                                    connectionId:_subscriber.session.connection.connectionId];
    [ServerUtils setCongestionLevelWithMediaServerHostname:mediaServerHostname
                                              subscriberId:subscriberId
                                           congestionLevel:_congestionLevel];
}

- (void)setSubscriber:(OTSubscriber *)subscriber {
    _subscriber = subscriber;
    
    _subscriber.subscribeToAudio = _subscribeToAudio;
    _subscriber.subscribeToVideo = _subscribeToVideo;
}

- (OptionsMenu *)getMenu {
    OptionsMenuBoolItem *subscribeToAudioOption = [[OptionsMenuBoolItem alloc] initWithKey:SUBSCRIBE_TO_AUDIO_KEY initialValue:_subscribeToAudio delegate:self];
    OptionsMenuBoolItem *subscribeToVideoOption = [[OptionsMenuBoolItem alloc] initWithKey:SUBSCRIBE_TO_VIDEO_KEY initialValue:_subscribeToVideo delegate:self];
    OptionsMenuSegmentedItem *congestionLevelOption = _subscriber == nil ? nil : [self getCongestionLevelOption];
    
    NSArray *options = [NSArray arrayWithObjects:subscribeToAudioOption, subscribeToVideoOption, congestionLevelOption, nil];
    return  [[OptionsMenu alloc] initWithOptions:options];
}

- (CongestionLevel)getCongestionValue:(NSString *)congestionLevelString {
    if ([CONGESTION_LEVEL_AUTO isEqualToString:congestionLevelString]) {
        return CongestionLevelAuto;
    } else if ([CONGESTION_LEVEL_NONE isEqualToString:congestionLevelString]) {
        return CongestionLevelNone;
    } else if ([CONGESTION_LEVEL_LOW isEqualToString:congestionLevelString]) {
        return CongestionLevelLow;
    } else {
        return CongestionLevelHigh;
    }
}

- (OptionsMenuSegmentedItem *)getCongestionLevelOption {
    NSArray *congestionLevels = [NSArray arrayWithObjects:CONGESTION_LEVEL_AUTO, CONGESTION_LEVEL_NONE, CONGESTION_LEVEL_LOW, CONGESTION_LEVEL_HIGH, nil];
    NSString *currentCongestionLevel = nil;
    switch (_congestionLevel) {
        case CongestionLevelAuto:
            currentCongestionLevel = CONGESTION_LEVEL_AUTO;
            break;
            
        case CongestionLevelNone:
            currentCongestionLevel = CONGESTION_LEVEL_NONE;
            break;
            
        case CongestionLevelLow:
            currentCongestionLevel = CONGESTION_LEVEL_LOW;
            break;
            
        case CongestionLevelHigh:
            currentCongestionLevel = CONGESTION_LEVEL_HIGH;
            break;
            
        default:
            NSLog(@"wtf?");
            @throw [NSException exceptionWithName:@"wtf" reason:@"invalid congestion level" userInfo:nil];
            break;
    }
    return [[OptionsMenuSegmentedItem alloc] initWithKey:CONGESTION_LEVEL_KEY items:congestionLevels initialValue:currentCongestionLevel delegate:self];
}

#pragma mark - OptionsMenuDelegate

- (void)option:(NSString *)option wasSwitchedTo:(id)value {
    if ([option isEqualToString:SUBSCRIBE_TO_AUDIO_KEY]) {
        self.subscribeToAudio = [value boolValue];
    } else if ([option isEqualToString:SUBSCRIBE_TO_VIDEO_KEY]) {
        self.subscribeToVideo = [value boolValue];
    } else if ([option isEqualToString:CONGESTION_LEVEL_KEY]) {
        self.congestionLevel = [self getCongestionValue:value];
    } else
        @throw [NSException exceptionWithName:@"wtf" reason:@"unrecognized option" userInfo:nil];
}

@end
