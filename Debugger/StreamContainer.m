//
//  StreamContainer.m
//  Debugger
//
//  Created by Christopher Brew on 3/6/13.
//
//

#import "StreamContainer.h"
#import <OpenTok/OpenTok.h>
#import "OptionsMenu.h"
#import "SubscriberOptions.h"
#import "Utils.h"

@interface StreamContainer () <OTSubscriberDelegate, OTSubscriberKitAudioLevelDelegate, UIPopoverControllerDelegate> @end

@implementation StreamContainer {
    BOOL _ownStream;
    OTStream *_stream;
    OTSubscriber *_subscriber;
    
    UILabel *_label;
    UIButton *_subscribeButton;
    UIButton *_optionsButton;
    SubscriberOptions *_subscriberOptions;
    UIPopoverController *_optionsPopover;
}

- (id)initWithStream:(OTStream *)stream {
    return [self initWithStream:stream ownStream:[stream.connection.connectionId isEqualToString:stream.session.connection.connectionId]];
}

- (id)initWithStream:(OTStream *)stream ownStream:(BOOL)ownStream {
    if (self = [super init]) {
        _stream = stream;
        _ownStream = ownStream;
        
        NSString *title = [NSString stringWithFormat:@"%@", _stream.streamId];
        if (_ownStream) {
            title = [NSString stringWithFormat:@"SELF - %@", title];
        }
        
        _label = [[UILabel alloc] initWithFrame:CGRectMake(Utils.widgetWidth, 0, Utils.buttonWidth, Utils.buttonHeight)];
        [_label setText:title];
        
        _subscribeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_subscribeButton setTitle:@"Subscribe" forState:UIControlStateNormal];
        [_subscribeButton addTarget:self action:@selector(doSubscribe) forControlEvents:UIControlEventTouchUpInside];
        _subscribeButton.frame = CGRectMake(_label.frame.origin.x,
                                            _label.frame.origin.y + _label.frame.size.height,
                                            Utils.buttonWidth,
                                            Utils.buttonHeight);
        
        _subscriberOptions = [[SubscriberOptions alloc] init];
        
        _optionsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_optionsButton setTitle:@"Options" forState:UIControlStateNormal];
        [_optionsButton addTarget:self action:@selector(showSubscriberOptions:) forControlEvents:UIControlEventTouchUpInside];
        _optionsButton.frame = CGRectMake(_subscribeButton.frame.origin.x,
                                          _subscribeButton.frame.origin.y + _subscribeButton.frame.size.height,
                                          Utils.buttonWidth,
                                          Utils.buttonHeight);
    }
    
    return self;
}

- (void)viewDidLoad {
    [self.view addSubview:_label];
    [self.view addSubview:_subscribeButton];
    [self.view addSubview:_optionsButton];
    
    if (Utils.autoSubscribe && !_ownStream) [self doSubscribe];
}

- (NSUInteger)supportedInterfaceOrientations {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        return UIInterfaceOrientationMaskAllButUpsideDown;
    else
        return UIInterfaceOrientationMaskAll;
}

#pragma mark - OpenTok methods

- (void)doSubscribe {
    _subscribeButton.enabled = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _subscriber = [[OTSubscriber alloc] initWithStream:_stream delegate:self];
//        [_subscriber setAudioLevelDelegate:self];
        _subscriberOptions.subscriber = _subscriber;
        _subscriber.view.frame = CGRectMake(0, 0, Utils.widgetWidth, Utils.widgetHeight);
        [self.view addSubview:_subscriber.view];
        OTError *error = nil;
        [_subscriber.stream.session subscribe:_subscriber error:&error];
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self subscriber:_subscriber didFailWithError:error];
            });
        }
    });
}

- (void)doUnsubscribe {
    [_subscribeButton setTitle:@"Subscribe" forState:UIControlStateNormal];
    [_subscribeButton removeTarget:self action:@selector(doUnsubscribe) forControlEvents:UIControlEventTouchUpInside];
    [_subscribeButton addTarget:self action:@selector(doSubscribe) forControlEvents:UIControlEventTouchUpInside];
    
    if (_optionsPopover != nil) [_optionsPopover dismissPopoverAnimated:NO];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        OTError *error = nil;
        [_subscriber.stream.session unsubscribe:_subscriber error:&error];
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self subscriber:_subscriber didFailWithError:error];
            });
        }
        [_subscriber.view removeFromSuperview];
    
        _subscriber = nil;
        _subscriberOptions.subscriber = nil;
    });
}

#pragma mark - OTSubscriberDelegate

- (void)subscriberDidConnectToStream:(OTSubscriberKit *)subscriber {
    NSLog(@"subscriberDidConnectToStream:%@", subscriber.stream.streamId);
    
    [_subscribeButton setTitle:@"Unsubscribe" forState:UIControlStateNormal];
    [_subscribeButton removeTarget:self action:@selector(doSubscribe) forControlEvents:UIControlEventTouchUpInside];
    [_subscribeButton addTarget:self action:@selector(doUnsubscribe) forControlEvents:UIControlEventTouchUpInside];
    _subscribeButton.enabled = YES;
}

- (void)subscriber:(OTSubscriberKit *)subscriber didFailWithError:(OTError *)error {
    NSLog(@"subscriber:%@ didFailWithError:%ld: %@", subscriber.stream.streamId, (long)error.code, error.localizedDescription);
    
    _subscriber = nil;
    _subscriberOptions.subscriber = nil;
    
    [_subscribeButton setTitle:@"Subscribe" forState:UIControlStateNormal];
    [_subscribeButton removeTarget:self action:@selector(doUnsubscribe) forControlEvents:UIControlEventTouchUpInside];
    [_subscribeButton addTarget:self action:@selector(doSubscribe) forControlEvents:UIControlEventTouchUpInside];
    _subscribeButton.enabled = YES;
}

- (void)subscriberVideoDisabled:(OTSubscriberKit *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    NSLog(@"subscriber video was diabled because %@", [self getReasonStr:reason]);
}

- (void)subscriberVideoEnabled:(OTSubscriberKit *)subscriber reason:(OTSubscriberVideoEventReason)reason {
    NSLog(@"subscriber video was enabled because %@", [self getReasonStr:reason]);
}

- (void)subscriberVideoDataReceived:(OTSubscriber *)subscriber {
    //    NSLog(@"subscriberVideoDataReceived:%@", subscriber.stream.streamId);
}

- (void)subscriberVideoDisableWarning:(OTSubscriberKit *)subscriber {
    NSLog(@"subscriberVideoDisableWarning: %@", subscriber.stream.streamId);
}

- (void)subscriberVideoDisableWarningLifted:(OTSubscriberKit *)subscriber {
    NSLog(@"subscriberVideoDisableWarningLifted: %@", subscriber.stream.streamId);
}

#pragma mark - OTSubscriberKitAudioLevelDelegate

- (void)subscriber:(OTSubscriberKit *)subscriber audioLevelUpdated:(float)audioLevel {
    NSLog(@"subscriber %@ audio level: %.2lf", subscriber.stream.streamId, audioLevel);
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    if (popoverController == _optionsPopover) {
        _optionsPopover = nil;
    }
}

#pragma mark - Misc

- (void)showSubscriberOptions:(UIControl *)sender {
    OptionsMenu *menu = [_subscriberOptions getMenu];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        _optionsPopover = [[UIPopoverController alloc] initWithContentViewController:menu];
        _optionsPopover.delegate = self;
        [_optionsPopover presentPopoverFromRect:sender.frame inView:sender.superview permittedArrowDirections:(UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown) animated:YES];
    } else {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:menu];
        navController.navigationBar.topItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissViewController)];
        [self presentViewController:navController animated:YES completion:nil];
    }
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)close {
    dispatch_block_t block = ^{
        if (_optionsPopover != nil) [_optionsPopover dismissPopoverAnimated:NO];
        if (_subscriber) {
            OTError *error = nil;
            [_subscriber.stream.session unsubscribe:_subscriber error:&error];
            if (error != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self subscriber:_subscriber didFailWithError:error];
                });
            }
            [_subscriber.view performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
            
            _subscriber = nil;
            _subscriberOptions.subscriber = nil;
        }
    };
    
    if ([NSThread isMainThread])
        block();
    else
        dispatch_sync(dispatch_get_main_queue(), block);
}

- (NSString *)getReasonStr:(OTSubscriberVideoEventReason)reason {
    switch (reason) {
        case OTSubscriberVideoEventPublisherPropertyChanged:
            return @"publisher property changed";
            break;
            
        case OTSubscriberVideoEventSubscriberPropertyChanged:
            return @"subscriber property changed";
            break;
            
        case OTSubscriberVideoEventQualityChanged:
            return @"quality changed";
            break;
            
        default:
            return @"dunno";
            break;
    }
    
}

@end
