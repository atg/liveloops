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
@synthesize audioData;
@synthesize movie;

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
    self.audioData = [plist valueForKey:@"pcm"];
}
- (NSData*)packIntoASCII {
    
    if (![audioData length])
        return nil;
    
    NSMutableDictionary* plist = [NSMutableDictionary dictionary];
    [plist setValue:[NSNumber numberWithDouble:self.currentLoopOffset] forKey:@"offset"];
    [plist setValue:[[self.audioData copy] autorelease] forKey:@"pcm"];
    NSMutableData* data = [[[NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL] mutableCopy] autorelease];
    // Add a null terminator
    [data setLength:[data length] + 1];
    return data;
}
- (void)readMovie {
    NSError* err = nil;
    self.movie = [[[QTMovie alloc] initWithData:audioData error:&err] autorelease];
    if (!movie) {
        NSLog(@"Error reading movie: %@", err);
    }
}




- (void)dealloc {
    
    self.audioData = nil;
    self.movie = nil;
    
    [super dealloc];
}

@end
