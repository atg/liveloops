//
//  Oscilloscope.m
//  modified from cocoaModem
//
//  Created by Kok Chen on Fri May 21 2004.
//

#import "Oscilloscope.h"

@implementation Oscilloscope

- (id)initWithFrame:(NSRect)frame 
{
	NSSize size ;
	float y, closedash[2] = { 1.0, 1.0 } ;
	
    self = [ super initWithFrame:frame ] ;
    if ( self ) {
		bounds = [ self bounds ] ;
		size = bounds.size ;
		width = size.width ;
		height = size.height ;
		plotWidth = 512 ;
		plotOffset = 4 ;
		
		path = nil ;
		pathLock = [ [ NSLock alloc ] init ] ;
		drawLock = [ [ NSLock alloc ] init ] ;
		background = [ [ NSBezierPath alloc ] init ] ;
		[ background appendBezierPathWithRect:bounds ] ;
		[ ( backgroundColor = [ NSColor colorWithDeviceRed:0 green:0.1 blue:0 alpha:1 ] ) retain ] ;
		
		//  set up waveform scale
		[ ( plotColor = [ NSColor colorWithCalibratedRed:0 green:1 blue:0.1 alpha:1 ] ) retain ] ;
		[ ( scaleColor = [ NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0 alpha:1 ] ) retain ] ;

		scale = [ [ NSBezierPath alloc ] init ] ;
		[ scale setLineDash:closedash count:2 phase:0 ] ;
		y = height/2 + 0.5 ;
		[ scale moveToPoint:NSMakePoint( plotOffset, y ) ] ;
		[ scale lineToPoint:NSMakePoint( plotWidth+plotOffset, y ) ] ;
		y = ( ( int )( height*0.125 ) ) + 0.5 ;
		[ scale moveToPoint:NSMakePoint( plotOffset, y ) ] ;
		[ scale lineToPoint:NSMakePoint( plotWidth+plotOffset, y ) ] ;
		y = ( ( int )( height*0.875 ) ) + 0.5 ;
		[ scale moveToPoint:NSMakePoint( plotOffset, y ) ] ;
		[ scale lineToPoint:NSMakePoint( plotWidth+plotOffset, y ) ] ;
		
		busy = NO ;
		
		thread = [ NSThread currentThread ] ;
    }
    return self ;
}

- (BOOL)isOpaque
{
	return YES ;
}

- (void)drawRect:(NSRect)frame
{
	if ( [ pathLock tryLock ] ) {
		//  clear background
		[ backgroundColor set ] ;
		[ background fill ] ;
		//  insert scale
		[ scaleColor set ] ;
		[ scale stroke ] ;
		//  insert graph
		if ( path ) {
			[ plotColor set ] ;
			[ path stroke ] ;
		}
		[ pathLock unlock ] ;
	}
}

//  local
- (void)displayInMainThread
{
	[ self setNeedsDisplay:YES ] ;
}

/* local */
- (void)newWaveform
{
	int i, plotSamples ;
	float yoffset, ygain, x, y ;
	
	if ( !waveform ) return ;
	plotSamples = plotWidth ;
	
	//  create new plot
	yoffset = height/2 ;
	ygain = -yoffset*0.75 ;
		
	if ( path ) [ path release ] ;
	path = [ [ NSBezierPath alloc ] init ] ;
	for ( i = 0; i < plotSamples; i++ ) {
		x = plotOffset + i ;
		y = yoffset - waveform[i]*ygain ;
		if ( y >= height ) y = height-1 ; else if ( y < 0 ) y = 0 ;
		if ( i == 0 ) [ path moveToPoint:NSMakePoint( x, y ) ] ; else [ path lineToPoint:NSMakePoint( x, y ) ] ;
	}
	[ self setNeedsDisplay:YES ] ;
}

- (void)addData:(const float*)stream
{
	if ( busy ) return ;
	
	if ( [ drawLock tryLock ] ) {
		busy = YES ;
		waveform = stream ;
		[ self performSelectorOnMainThread:@selector(newWaveform) withObject:nil waitUntilDone:NO ] ;
		busy = NO ;
		[ drawLock unlock ] ;
	}
}

@end
