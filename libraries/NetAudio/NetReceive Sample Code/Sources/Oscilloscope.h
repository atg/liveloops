//
//  Oscilloscope.h
//  cocoaModem
//
//  Created by Kok Chen on Fri May 21 2004.
//

#ifndef _OSCILLOSCOPE_H_
	#define _OSCILLOSCOPE_H_

	#import <AppKit/AppKit.h>
	
	@interface Oscilloscope : NSView {
	
		NSRect bounds ;
		int width, height ;
		int plotWidth ;
		int plotOffset ;
		float timeStorage[512] ;
		float ySat ;
		const float *waveform ;
		
		NSColor *plotColor, *scaleColor, *backgroundColor ;
		NSBezierPath *path, *scale, *background ;
		NSLock *pathLock ;
		NSLock *drawLock ;
		
		Boolean busy ;
		
		NSThread *thread ;
	}

	- (void)addData:(const float*)stream ;
	
	@end

#endif
