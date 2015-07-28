//
//  SubscriberOptions.h
//  Debugger
//
//  Created by Christopher Brew on 6/24/13.
//
//

#import "ServerUtils.h"

@class OTSubscriber;
@class OptionsMenu;

@interface SubscriberOptions : NSObject

@property (nonatomic) bool subscribeToAudio;
@property (nonatomic) bool subscribeToVideo;
@property (nonatomic) CongestionLevel congestionLevel;

@property (nonatomic, weak) OTSubscriber *subscriber;

- (OptionsMenu *)getMenu;

@end
