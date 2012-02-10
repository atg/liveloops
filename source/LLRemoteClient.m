//
//  LLRemoteClient.m
//  CAPlayThrough
//
//  Created by Alex Gordon on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LLRemoteClient.h"
#import "LLLoop.h"

@implementation LLRemoteClient

@synthesize peeraddress;

@synthesize loop;

@synthesize reader;

- (void)read {
    [reader readUntilCString:"\0" callback:^(NSData *data, BOOL prematureEOF) {
        if (prematureEOF) {
            [self disconnect];
            return;
        }
        
        [loop unpackFromASCII:data];
        [self read];
    }];
}
- (void)disconnect {
    
}

@end
