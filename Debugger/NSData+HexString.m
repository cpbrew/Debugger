//
//  NSData+HexString.m
//  opentok-ios-sdk-tests
//
//  Created by Christopher Brew on 4/25/13.
//  Copyright (c) 2013 TokBox. All rights reserved.
//

#import "NSData+HexString.h"

@implementation NSData (HexString)
- (NSString*)hexString {
    const unsigned char* bytes = (const unsigned char*)[self bytes];
    NSUInteger nbBytes = [self length];
    NSUInteger strLen = 2*nbBytes;
    
    NSMutableString* hex = [[NSMutableString alloc] initWithCapacity:strLen];
    for(NSUInteger i=0; i<nbBytes; ) {
        [hex appendFormat:@"%02x", bytes[i]];
        //We need to increment here so that the every-n-bytes computations are right.
        ++i;
    }
    return hex;
}

@end
