//
//  TestXMLNode.m
//  opentok-ios-sdk-tests
//
//  Created by Christopher Brew on 4/25/13.
//  Copyright (c) 2013 TokBox. All rights reserved.
//

#import "TestXMLNode.h"

@interface TestXMLNode() <NSXMLParserDelegate> @end

@implementation TestXMLNode {
    NSString *name;
    NSString *text;
    NSDictionary *attributes;
    NSMutableArray *children;
    TestXMLNode *cursor;
    NSMutableArray *stack;
}

@synthesize name;
@synthesize text;
@synthesize attributes;
@synthesize children;

- (id)init {
    if (self = [super init]) {
        children = [[NSMutableArray alloc] init];
        name = nil;
        text = nil;
        cursor = nil;
        attributes = nil;
    }
    return self;
}

- (id)initWithParser:(NSXMLParser *)parser {
    if (self = [self init]) {
        stack = [[NSMutableArray alloc] init];
        [parser setDelegate:self];
        if (![parser parse]) {
            return nil;
        }
        stack = nil;
        cursor = nil;
    }
    return self;
}

- (NSString *)description {
    NSMutableString *string = [[NSMutableString alloc] init];
    TestXMLNode *node = self;
    if (node.attributes && node.attributes.count > 0) {
        NSMutableString *attributesStr = [[NSMutableString alloc] init];
        for (NSString *key in node.attributes) {
            [attributesStr appendFormat:@"%@=%@ ", key, [node.attributes valueForKey:key]];
        }
        [string appendFormat:@"<%@ %@>", node.name, attributesStr];
    } else {
        [string appendFormat:@"<%@>", node.name];
    }
    if (node.text) {
        [string appendString:node.text];
    }
    if (node.children.count > 0) {
        for (TestXMLNode *child in node.children) {
            [string appendString:[child description]];
        }
    }
    [string appendFormat:@"</%@>", node.name];
    return string;
}

- (TestXMLNode *)childNodeForName:(NSString *)nameStr {
    for (TestXMLNode *child in self.children) {
        if ([child.name isEqualToString:nameStr]) {
            return child;
        }
    }
    return nil;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if (!cursor) {
        self.name = elementName;
        self.attributes = attributeDict;
        cursor = self;
    } else {
        TestXMLNode *parent = cursor;
        [stack addObject:parent];
        cursor = [[TestXMLNode alloc] init];
        cursor.name = elementName;
        cursor.attributes = attributeDict;
        [parent.children addObject:cursor];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    assert([elementName isEqualToString:cursor.name]);
    cursor = [stack lastObject];
    [stack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    cursor.text = string;
}

+ (TestXMLNode *)newXmlNodeWithUTF8String:(NSString *)string {
    return [TestXMLNode newXmlNodeWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (TestXMLNode *)newXmlNodeWithData:(NSData *)data {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    return [[TestXMLNode alloc] initWithParser:parser];
}

@end