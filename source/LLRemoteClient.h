//
//  LLRemoteClient.h
//  CAPlayThrough
//
//  Created by Alex Gordon on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAAsyncIO.h"

@class LLLoop;

@interface LLRemoteClient : NSObject {
    NSData* peeraddress;
    
    LLLoop* loop;
    
    MAAsyncReader* reader;
}

@property (copy) NSData* peeraddress;
@property (retain) LLLoop* loop;
@property (retain) MAAsyncReader* reader;

- (void)disconnect;

@end
