//
//  LLLoop.m
//  CAPlayThrough
//
//  Created by Alex Gordon on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LLLoop.h"

@implementation LLLoop

@synthesize currentLoopOffset;
@synthesize currentLoopPCM;

- (void)unpackFromASCII:(NSData*)ascii {
    
    // Does this start or end with ascii?
    NSRange range = NSMakeRange(0, [ascii length]);
    if (range.length > 0 && ((const char*)[ascii bytes])[range.length - 1] == 0)
        range.length -= 1;
    else
        return;
    
    if (range.length > 0 && ((const char*)[ascii bytes])[0] == 0) {
        range.location += 1;
        range.length -= 1;
    }
    else
        return;
    
    if (range.length == 0)
        return;
    
    NSDictionary* plist = [NSPropertyListSerialization propertyListWithData:[ascii subdataWithRange:range] options:NSPropertyListImmutable format:NULL error:NULL];
    self.currentLoopOffset = [[plist valueForKey:@"offset"] doubleValue];
    self.currentLoopPCM = [plist valueForKey:@"pcm"];
}
- (NSData*)packIntoASCII {
    
    if (![currentLoopPCM length])
        return nil;
    
    NSMutableDictionary* plist = [NSMutableDictionary dictionary];
    [plist setValue:[NSNumber numberWithDouble:self.currentLoopOffset] forKey:@"offset"];
    [plist setValue:[[self.currentLoopPCM copy] autorelease] forKey:@"pcm"];
    NSMutableData* data = [[[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL] mutableCopy] autorelease];
    // Add a null terminator
    [data setLength:[data length] + 1];
    return data;
}

- (void)dealloc {
    
    self.currentLoopPCM = nil;
    
    [super dealloc];
}

@end
