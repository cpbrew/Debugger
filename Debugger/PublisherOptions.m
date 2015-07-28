//
//  PublisherOptions.m
//  Debugger
//
//  Created by Christopher Brew on 6/21/13.
//
//

#import "PublisherOptions.h"
#import <OpenTok/OpenTok.h>
#import "OptionsMenu.h"

#define PUBLISH_AUDIO_KEY       @"publishAudio"
#define PUBLISH_VIDEO_KEY       @"publishVideo"
#define CAMERA_POSITION_KEY     @"cameraPosition"
#define CAMERA_POSITION_FRONT   @"front"
#define CAMERA_POSITION_BACK    @"back"

@interface PublisherOptions () <OptionsMenuDelegate> @end

@implementation PublisherOptions {
    bool _publishAudio;
    bool _publishVideo;
    AVCaptureDevicePosition _cameraPosition;
    
    OTPublisher *_publisher;
}

@dynamic publishAudio;
@dynamic publishVideo;
@dynamic cameraPosition;

@dynamic publisher;

- (id)init {
    if (self = [super init]) {
        _publishAudio = true;
        _publishVideo = true;
        _cameraPosition = AVCaptureDevicePositionFront;
    }
    return self;
}

- (bool)publishAudio {
    return _publishAudio;
}

- (void)setPublishAudio:(bool)publishAudio {
    _publishAudio = publishAudio;
    _publisher.publishAudio = _publishAudio;
}

- (bool)publishVideo {
    return _publishVideo;
}

- (void)setPublishVideo:(bool)publishVideo {
    _publishVideo = publishVideo;
    _publisher.publishVideo = _publishVideo;
}

- (AVCaptureDevicePosition)cameraPosition {
    return _cameraPosition;
}

- (void)setCameraPosition:(AVCaptureDevicePosition)cameraPosition {
    _cameraPosition = cameraPosition;
    if (_publisher.cameraPosition != _cameraPosition) {
        _publisher.cameraPosition = _cameraPosition;
    }
}

- (void)setPublisher:(OTPublisher *)publisher {
    _publisher = publisher;
    
    if (_publisher != nil) {
        _publisher.publishAudio = _publishAudio;
        _publisher.publishVideo = _publishVideo;
        _cameraPosition = _publisher.cameraPosition;
    }
}

- (OptionsMenu *)getMenu {
    OptionsMenuBoolItem *publishAudioOption = [[OptionsMenuBoolItem alloc] initWithKey:PUBLISH_AUDIO_KEY initialValue:_publishAudio delegate:self];
    OptionsMenuBoolItem *publishVideoOption = [[OptionsMenuBoolItem alloc] initWithKey:PUBLISH_VIDEO_KEY initialValue:_publishVideo delegate:self];
    
    NSArray *cameraPositions = [NSArray arrayWithObjects:CAMERA_POSITION_FRONT, CAMERA_POSITION_BACK, nil];
    NSString *currentCameraPosition = _cameraPosition == AVCaptureDevicePositionFront ? CAMERA_POSITION_FRONT : CAMERA_POSITION_BACK;
    OptionsMenuSegmentedItem *cameraPositionOption = [[OptionsMenuSegmentedItem alloc] initWithKey:CAMERA_POSITION_KEY items:cameraPositions initialValue:currentCameraPosition delegate:self];
    
    NSArray *options = [NSArray arrayWithObjects:publishAudioOption, publishVideoOption, cameraPositionOption, nil];
    return [[OptionsMenu alloc] initWithOptions:options];
}

#pragma mark - OptionsMenuDelegate

- (void)option:(NSString *)option wasSwitchedTo:(id)value {
    if ([option isEqualToString:PUBLISH_AUDIO_KEY]) {
        self.publishAudio = [value boolValue];
    } else if ([option isEqualToString:PUBLISH_VIDEO_KEY]) {
        self.publishVideo = [value boolValue];
    } else if ([option isEqualToString:CAMERA_POSITION_KEY]) {
        if ([value isEqualToString:CAMERA_POSITION_FRONT])
            self.cameraPosition = AVCaptureDevicePositionFront;
        else if ([value isEqualToString:CAMERA_POSITION_BACK])
            self.cameraPosition = AVCaptureDevicePositionBack;
        else
            @throw [NSException exceptionWithName:@"UnsupportedCameraPosition" reason:@"wtf" userInfo:nil];
    } else {
        @throw [NSException exceptionWithName:@"UnrecognizedOption" reason:@"wtf" userInfo:nil];
    }
}

@end
