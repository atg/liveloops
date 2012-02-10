//
//  LLLoop.h
//  CAPlayThrough
//
//  Created by Alex Gordon on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QTKit/QTKit.h>

@interface LLLoop : NSObject {
    double currentLoopOffset;
    NSData* audioData;
    QTMovie* movie;
}

@property (assign) double currentLoopOffset;
@property (copy) NSData* audioData;
@property (retain) QTMovie* movie;

- (void)unpackFromASCII:(NSData*)ascii;
- (NSData*)packIntoASCII;
- (void)readMovie;

@end
