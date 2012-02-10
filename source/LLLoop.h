//
//  LLLoop.h
//  CAPlayThrough
//
//  Created by Alex Gordon on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLLoop : NSObject {
    double currentLoopOffset;
    NSData* currentLoopPCM;
}

@property (assign) double currentLoopOffset;
@property (copy) NSData* currentLoopPCM;

- (void)unpackFromASCII:(NSData*)ascii;
- (NSData*)packIntoASCII;

@end
