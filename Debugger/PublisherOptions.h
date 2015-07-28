//
//  PublisherOptions.h
//  Debugger
//
//  Created by Christopher Brew on 6/21/13.
//
//

#import <AVFoundation/AVFoundation.h>

@class OTPublisher;
@class OptionsMenu;

@interface PublisherOptions : NSObject

@property (nonatomic) bool publishAudio;
@property (nonatomic) bool publishVideo;
@property (nonatomic) AVCaptureDevicePosition cameraPosition;

@property (nonatomic, weak) OTPublisher *publisher;

- (OptionsMenu *)getMenu;

@end
