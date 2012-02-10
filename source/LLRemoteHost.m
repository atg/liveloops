//
//  LLRemoteHost.m
//  CAPlayThrough
//
//  Created by Alex Gordon on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "LLRemoteHost.h"
#import "LLLoop.h"

@implementation LLRemoteHost

@synthesize hostname;
@synthesize needsDataUpdate;
@synthesize writer;

- (void)didChangeLocalLoop:(LLLoop*)loop {
    [writer writeData:[loop packIntoASCII]];
    needsDataUpdate = NO;
}

@end
