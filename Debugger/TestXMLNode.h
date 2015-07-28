//
//  TestXMLNode.h
//  opentok-ios-sdk-tests
//
//  Created by Christopher Brew on 4/25/13.
//  Copyright (c) 2013 TokBox. All rights reserved.
//

@interface TestXMLNode : NSObject

@property (copy) NSString *name;
@property (copy) NSString *text;
@property (strong) NSDictionary *attributes;
@property (strong) NSMutableArray *children;

- (TestXMLNode *)childNodeForName:(NSString *)name;

+ (TestXMLNode *)newXmlNodeWithUTF8String:(NSString *)string;
+ (TestXMLNode *)newXmlNodeWithData:(NSData *)data;

@end
