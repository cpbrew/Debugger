//
//  Utils.h
//  Debugger
//
//  Created by Christopher Brew on 3/6/13.
//
//

@interface OpenTokObjC : NSObject
+ (void)setLogBlockQueue:(dispatch_queue_t)queue;
+ (void)setLogBlockArgument:(void*)argument;
+ (void)setLogBlock:(void (^)(NSString* message, void* argument))logBlock;
@end

@interface Utils : NSObject

+ (double)widgetHeight;
+ (double)widgetWidth;

+ (double)buttonHeight;
+ (double)buttonWidth;

+ (BOOL)autoConnect;
+ (BOOL)autoPublish;
+ (BOOL)autoSubscribe;
+ (BOOL)testSignaling;
+ (BOOL)testTurnTcp;
+ (BOOL)debugLogging;

+ (NSString *)serviceUrl;
+ (NSString *)apiKey;
+ (NSString *)apiSecret;
+ (NSString *)sessionId;
+ (NSString *)token;

@end
