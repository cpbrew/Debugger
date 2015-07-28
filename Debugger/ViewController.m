//
//  ViewController.m
//  SampleApp
//
//  Created by Charley Robinson on 12/13/11.
//  Modified by Christopher Brew on 2/19/13.
//  Copyright (c) 2011 Tokbox, Inc. All rights reserved.
//

#import "ViewController.h"
#import <OpenTok/OpenTok.h>
#import "OptionsMenu.h"
#import "PublisherOptions.h"
#import "ServerUtils.h"
#import "StreamContainer.h"
#import "Utils.h"

@interface OTSession ()

+ (void)forceTurnOverTcp:(BOOL)value;
- (void)setApiRootURL:(NSURL *)aURL;

@end

@interface ViewController () <OTSessionDelegate, OTPublisherDelegate, OTPublisherKitAudioLevelDelegate, UIPopoverControllerDelegate> @end

@implementation ViewController {
    UIScrollView *_view;
    
    OTSession *_session;
    OTPublisher *_publisher;
    NSMutableDictionary *_streamContainers;
    
    UIButton *_connectButton;
    UIButton *_publishButton;
    UIButton *_optionsButton;
    PublisherOptions *_publisherOptions;
    UIPopoverController *_optionsPopover;
    UIButton *_killSwitch;
}

- (void)loadView {
    _view = [[UIScrollView alloc] init];
    self.view = _view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _connectButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    [_connectButton addTarget:self action:@selector(doConnect) forControlEvents:UIControlEventTouchUpInside];
    _connectButton.frame = CGRectMake(Utils.widgetWidth, 0, Utils.buttonWidth, Utils.buttonHeight);
    [self.view addSubview:_connectButton];
    
    _publishButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_publishButton setTitle:@"Publish" forState:UIControlStateNormal];
    [_publishButton addTarget:self action:@selector(doPublish) forControlEvents:UIControlEventTouchUpInside];
    _publishButton.enabled = NO;
    _publishButton.frame = CGRectMake(_connectButton.frame.origin.x,
                                      _connectButton.frame.origin.y + _connectButton.frame.size.height,
                                      Utils.buttonWidth,
                                      Utils.buttonHeight);
    [self.view addSubview:_publishButton];
    
    _publisherOptions = [[PublisherOptions alloc] init];
    
    _optionsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_optionsButton setTitle:@"Options" forState:UIControlStateNormal];
    [_optionsButton addTarget:self action:@selector(showPublisherOptions:) forControlEvents:UIControlEventTouchUpInside];
    _optionsButton.frame = CGRectMake(_publishButton.frame.origin.x,
                                      _publishButton.frame.origin.y + _publishButton.frame.size.height,
                                      Utils.buttonWidth,
                                      Utils.buttonHeight);
    [self.view addSubview:_optionsButton];
    
    _streamContainers = [NSMutableDictionary dictionary];
    
    _killSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
    [_killSwitch setImage:[UIImage imageNamed:@"radioactive.png"] forState:UIControlStateNormal];
    [_killSwitch addTarget:self action:@selector(killMe) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_killSwitch];
    
    if (Utils.autoConnect) [self doConnect];
}

- (void)viewWillLayoutSubviews {
    _killSwitch.frame = CGRectMake(self.view.bounds.size.width - 50, 0, 50, 50);
    [self repositionContainers];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - OpenTok methods

- (void)doConnect {
    if (_session != nil) return;
    
    _connectButton.enabled = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (Utils.testTurnTcp) [OTSession forceTurnOverTcp:YES];
        
        _session = [[OTSession alloc] initWithApiKey:Utils.apiKey sessionId:Utils.sessionId delegate:self];
        if (Utils.serviceUrl != nil) {
            [_session setApiRootURL:[NSURL URLWithString:Utils.serviceUrl]];
        }
        NSString *token = Utils.token;
        if (token == nil) {
            token = [ServerUtils generateTokenWithApiKey:Utils.apiKey
                                               apiSecret:Utils.apiSecret
                                               sessionId:Utils.sessionId
                                                    role:Moderator
                                              expireTime:[NSDate dateWithTimeIntervalSinceNow:SECONDS_PER_DAY]
                                          connectionData:nil];
        }
        
        OTError *error = nil;
        [_session connectWithToken:token error:&error];
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self session:_session didFailWithError:error];
            });
        }
    });
}

- (void)doDisconnect {
    _connectButton.enabled = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        OTError *error = nil;
        [_session disconnect:&error];
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self session:_session didFailWithError:error];
            });
        }
    });
}

- (void)doPublish {
    _publishButton.enabled = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _publisher = [[OTPublisher alloc] initWithDelegate:self name:[[UIDevice currentDevice] name]];
//        [_publisher setAudioLevelDelegate:self];
        _publisherOptions.publisher = _publisher;
        _publisher.view.frame = CGRectMake(0, 0, Utils.widgetWidth, Utils.widgetHeight);
        [self.view addSubview:_publisher.view];
        OTError *error = nil;
        [_session publish:_publisher error:&error];
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self publisher:_publisher didFailWithError:error];
            });
        }
    });
}

- (void)doUnpublish {
    _publishButton.enabled = NO;
    if (_optionsPopover != nil) [_optionsPopover dismissPopoverAnimated:NO];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        OTError *error = nil;
        [_session unpublish:_publisher error:&error];
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self publisher:_publisher didFailWithError:error];
            });
        }
    });
}

#pragma mark - OTSessionDelegate

- (void)sessionDidConnect:(OTSession *)session {
    NSLog(@"sessionDidConnect:%@", session.sessionId);
    
    [_connectButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    [_connectButton removeTarget:self action:@selector(doConnect) forControlEvents:UIControlEventTouchUpInside];
    [_connectButton addTarget:self action:@selector(doDisconnect) forControlEvents:UIControlEventTouchUpInside];
    _connectButton.enabled = YES;
    
    _publishButton.enabled = YES;
    
    if (Utils.autoPublish && !_publisher) [self doPublish];
    
    if (Utils.testSignaling) {
        [self testSignalingWithConnection:nil];
        [self testSignalingWithConnection:session.connection];
    }
}

- (void)sessionDidDisconnect:(OTSession *)session {
    NSLog(@"sessionDidDisconnect:%@", session.sessionId);
    
    if (_publisher != nil) {
        if (_publisher.view != NULL) {
            [_publisher.view removeFromSuperview];
        }
        
        _publisherOptions.publisher = nil;
        _publisher = nil;
        
        _session = nil;
    }

    _session = nil;
    
    NSArray *streamIds = [[_streamContainers allKeys] copy];
    for (int i = 0; i < streamIds.count; i++) {
        [self removeStream:[streamIds objectAtIndex:i]];
    }
    
    [_connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    [_connectButton removeTarget:self action:@selector(doDisconnect) forControlEvents:UIControlEventTouchUpInside];
    [_connectButton addTarget:self action:@selector(doConnect) forControlEvents:UIControlEventTouchUpInside];
    _connectButton.enabled = YES;
    
    [_publishButton setTitle:@"Publish" forState:UIControlStateNormal];
    [_publishButton removeTarget:self action:@selector(doUnpublish) forControlEvents:UIControlEventTouchUpInside];
    [_publishButton addTarget:self action:@selector(doPublish) forControlEvents:UIControlEventTouchUpInside];
    _publishButton.enabled = NO;
}

- (void)session:(OTSession *)session didFailWithError:(OTError *)error {
    NSString *errorMessage = [NSString stringWithFormat:@"session:didFailWithError %ld: %@", (long)[error code], [error localizedDescription]];
    NSLog(@"%@", errorMessage);
    
    if (_publisher != nil) {
        if (_publisher.view != NULL) {
            [_publisher.view removeFromSuperview];
        }
        
        _publisherOptions.publisher = nil;
        _publisher = nil;
    }
    
    _session = nil;

    NSArray* streamIds = [[_streamContainers allKeys] copy];
    for (int i = 0; i < streamIds.count; i++) {
        [self removeStream:[streamIds objectAtIndex:i]];
    }

    [_connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    [_connectButton removeTarget:self action:@selector(doDisconnect) forControlEvents:UIControlEventTouchUpInside];
    [_connectButton addTarget:self action:@selector(doConnect) forControlEvents:UIControlEventTouchUpInside];
    _connectButton.enabled = YES;

    [_publishButton setTitle:@"Publish" forState:UIControlStateNormal];
    [_publishButton removeTarget:self action:@selector(doUnpublish) forControlEvents:UIControlEventTouchUpInside];
    [_publishButton addTarget:self action:@selector(doPublish) forControlEvents:UIControlEventTouchUpInside];
    _publishButton.enabled = NO;

    [self showAlert:errorMessage];
}

- (void)session:(OTSession *)session streamCreated:(OTStream *)stream {
    NSLog(@"session:streamCreated:%@", stream.streamId);

    StreamContainer *container = [[StreamContainer alloc] initWithStream:stream];
    [_streamContainers setObject:container forKey:stream.streamId];
    [self addChildViewController:container];
    [self.view performSelectorOnMainThread:@selector(addSubview:) withObject:container.view waitUntilDone:YES];
    [self repositionContainers];
}

- (void)session:(OTSession *)session streamDestroyed:(OTStream *)stream {
    NSLog(@"session:streamDestroyed:%@", stream.streamId);

    [self removeStream:stream.streamId];
    [self repositionContainers];
}

- (void)session:(OTSession *)session connectionCreated:(OTConnection *)connection {
    NSLog(@"session:connectionCreated:%@", connection.connectionId);
}

- (void)session:(OTSession *)session connectionDestroyed:(OTConnection *)connection {
    NSLog(@"session:connectionDestroyed:%@", connection.connectionId);
}

- (void)session:(OTSession *)session receivedSignalType:(NSString *)type fromConnection:(OTConnection *)connection withString:(NSString *)string {
    NSLog(@"session:receivedSignalType:%@ fromConnection:%@ withString:%@", type, connection.connectionId, string);
}

- (void)session:(OTSession *)session archiveStartedWithId:(NSString *)archiveId name:(NSString *)name {
    NSLog(@"session:archiveStartedWithId:%@ name:%@", archiveId, name);
}

- (void)session:(OTSession *)session archiveStoppedWithId:(NSString *)archiveId {
    NSLog(@"session:archiveStoppedWithId:%@", archiveId);
}

#pragma mark - OTPublisherDelegate

- (void)publisher:(OTPublisher *)publisher didFailWithError:(OTError *) error {
    NSString *errorMessage = [NSString stringWithFormat:@"publisher:didFailWithError %ld: %@", (long)[error code], [error localizedDescription]];
    NSLog(@"%@", errorMessage);
    
    if (_publisher.view != nil) {
        [_publisher.view removeFromSuperview];
    }
    
    _publisherOptions.publisher = nil;
    _publisher = nil;
    
    [_publishButton setTitle:@"Publish" forState:UIControlStateNormal];
    [_publishButton removeTarget:self action:@selector(doUnpublish) forControlEvents:UIControlEventTouchUpInside];
    [_publishButton addTarget:self action:@selector(doPublish) forControlEvents:UIControlEventTouchUpInside];
    if (_session.sessionConnectionStatus == OTSessionConnectionStatusConnected) _publishButton.enabled = YES;
    
    [self showAlert:errorMessage];
}

- (void)publisher:(OTPublisherKit *)publisher streamCreated:(OTStream *)stream {
    NSLog(@"publisher:streamCreated:%@", stream.streamId);
    
    [_publishButton setTitle:@"Unpublish" forState:UIControlStateNormal];
    [_publishButton removeTarget:self action:@selector(doPublish) forControlEvents:UIControlEventTouchUpInside];
    [_publishButton addTarget:self action:@selector(doUnpublish) forControlEvents:UIControlEventTouchUpInside];
    _publishButton.enabled = YES;
    
    [self session:publisher.session streamCreated:stream];
}

- (void)publisher:(OTPublisherKit *)publisher streamDestroyed:(OTStream *)stream {
    NSLog(@"publisher:streamDestroyed: %@", stream.streamId);
    
    if (_publisher.view != NULL) {
        [_publisher.view removeFromSuperview];
    }
    
    _publisherOptions.publisher = nil;
    _publisher = nil;
    
    [_publishButton setTitle:@"Publish" forState:UIControlStateNormal];
    [_publishButton removeTarget:self action:@selector(doUnpublish) forControlEvents:UIControlEventTouchUpInside];
    [_publishButton addTarget:self action:@selector(doPublish) forControlEvents:UIControlEventTouchUpInside];
    if (_session.sessionConnectionStatus == OTSessionConnectionStatusConnected) _publishButton.enabled = YES;
    
    [self session:publisher.session streamDestroyed:stream];
}

- (void)publisher:(OTPublisher *)publisher didChangeCameraPosition:(AVCaptureDevicePosition)position {
    _publisherOptions.cameraPosition = position;
}

#pragma mark - OTPublisherKitAudioLevelDelegate

- (void)publisher:(OTPublisherKit *)publisher audioLevelUpdated:(float)audioLevel {
    NSLog(@"publisher:audioLevelUpdated: %.2lf", audioLevel);
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    if (popoverController == _optionsPopover) {
        _optionsPopover = nil;
    }
}

#pragma mark - Misc

- (void)testSignalingWithConnection:(OTConnection *)connection {
    NSArray *types = @[@"foo", @""];
    NSArray *values = @[@"bar", @""];
    for (NSString *type in types) {
        for (NSString *value in values) {
            [self sendSignalWithType:type value:value connection:connection];
        }
        [self sendSignalWithType:type value:nil connection:connection];
    }
    for (NSString *value in values) {
        [self sendSignalWithType:nil value:value connection:connection];
    }
    [self sendSignalWithType:nil value:nil connection:connection];
}

- (void)sendSignalWithType:(NSString *)type value:(NSString *)value connection:(OTConnection *)connection {
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        OTError *error = nil;
        [_session signalWithType:type string:value connection:connection error:&error];
        if (error == nil) {
            NSLog(@"Signal sent successfully");
        } else {
            NSLog(@"Error sending signal: %@", [error localizedDescription]);
        }
    });
}

- (void)showPublisherOptions:(UIControl *)sender {
    OptionsMenu *menu = [_publisherOptions getMenu];
    
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

- (void)applicationDidEnterBackground:(UIApplication *)application {
    if (_publisher != nil) {
        _publisher.publishVideo = NO;
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    if (_publisher != nil) {
        _publisher.publishVideo = _publisherOptions.publishVideo;
    }
}

- (void)repositionContainers {
    StreamContainer *container;
    NSArray *streamIds = [_streamContainers allKeys];
    for (int i = 0; i < streamIds.count; i++) {
        container = [_streamContainers objectForKey:[streamIds objectAtIndex:i]];
        [container.view setFrame:CGRectMake(0,
                                            (i + 1) * Utils.widgetHeight, // + 1 for publisher
                                            self.view.bounds.size.width,
                                            Utils.widgetHeight)];
    }
    
    _view.contentSize = CGSizeMake(self.view.bounds.size.width, (streamIds.count + 1) * Utils.widgetHeight);
}

- (void)removeStream:(NSString *)streamId {
    StreamContainer *container = [_streamContainers objectForKey:streamId];
    [_streamContainers removeObjectForKey:streamId];
    
    [container close];
    [container.view performSelectorOnMainThread:@selector(removeFromSuperview) withObject:nil waitUntilDone:YES];
    [container removeFromParentViewController];
}

- (void)showAlert:(NSString*)string {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message from video session"
                                                    message:string
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)killMe {
    exit(0);
}

@end

