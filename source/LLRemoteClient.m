//
//  LLRemoteClient.m
//  CAPlayThrough
//
//  Created by Alex Gordon on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LLRemoteClient.h"
#import "LLLoop.h"
#import "CAPlayThroughController.h"

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
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [[CAPlayThroughController sharedInstance] stopLoop:self.loop];
            self.loop = nil;
            self.loop = [[LLLoop alloc] init];
            [self.loop unpackFromASCII:data];
            [[CAPlayThroughController sharedInstance] playLoop:self.loop];
        });
        
        [self read];
    }];
}
- (void)disconnect {
    
}

@end
