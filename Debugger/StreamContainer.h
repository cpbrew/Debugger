//
//  StreamContainer.h
//  Debugger
//
//  Created by Christopher Brew on 3/6/13.
//
//

@class OTStream;

@interface StreamContainer : UIViewController

- (id)initWithStream:(OTStream *)stream;
- (void)close;

@end
