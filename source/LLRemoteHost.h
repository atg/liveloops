//
//  LLRemoteHost.h
//  CAPlayThrough
//
//  Created by Alex Gordon on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MAAsyncIO.h"

@class LLLoop;

@interface LLRemoteHost : NSObject {
    NSString* hostname;
    
    BOOL needsDataUpdate;
    
    MAAsyncWriter* writer;
}

@property (copy) NSString* hostname;

@property (assign) BOOL needsDataUpdate;

@property (retain) MAAsyncWriter* writer;

- (void)didChangeLocalLoop:(LLLoop*)loop;

@end
