//
//  NetReceiveTest.m
//  Audio Unit Tests
//
//  Created by Kok Chen on 11/17/07.

#import "NetReceiveTest.h"
#import "Oscilloscope.h"


@implementation NetReceiveTest

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		//  don't set service name yet, until awakeFromNib finds it from the UI
		netreceive = [ [ NetReceive alloc ] initWithService:nil delegate:self samplesPerBuffer:512 ] ;
	}
	return self ;
}

- (void)serviceChanged
{
	[ netreceive setServiceName:[ service stringValue ] ] ;
}

- (void)awakeFromNib
{
	//  Set the initial service name from UI
	[ self serviceChanged ] ;
	//  ... and Monitor if user changes service
	[ service setAction:@selector(serviceChanged) ] ;
	[ service setTarget:self ] ;
}

- (void)dealloc 
{
	[ netreceive stopSampling ] ;
	[ netreceive release ] ;
	[ super dealloc ] ;
}

- (void)startSampling
{
	[ netreceive startSampling ] ;
}

- (void)stopSampling
{
	[ netreceive stopSampling ] ;
}

- (IBAction)openNetReceive:(id)sender
{
	[ self startSampling ] ;
}

- (IBAction)stopNetReceive:(id)sender
{
	[ self stopSampling ] ;
}

//  delgates to NetReceive
- (void)netReceive:(NetReceive*)aNetReceive newSamples:(int)samplesPerBuffer left:(const float*)leftBuffer right:(const float*)rightBuffer
{
	int i ;
	
	if ( scope ) {	
		for ( i = 0; i < 512; i++ ) doubleBuffer[i] = leftBuffer[i] ;
		[ scope addData:doubleBuffer ] ;
	}
}

- (void)netReceive:(NetReceive*)aNetReceive addressChanged:(const char*)address port:(int)inPort
{
	//  update UI
	[ ip setStringValue:[ NSString stringWithFormat:@"%s", address ] ] ;
	[ port setIntValue:inPort ] ;
}


@end
