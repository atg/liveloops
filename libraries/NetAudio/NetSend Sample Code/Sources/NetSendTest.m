//
//  NetSendTest.m
//  Audio Unit Tests
//
//  Created by Kok Chen on 11/12/07.

#import "NetSendTest.h"


@implementation NetSendTest


- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		phase = 0 ;
		netsend = [ [ NetSend alloc ] initWithService:@"NetSend Test" delegate:self samplesPerBuffer:512 ] ;
		[ netsend setDelegate:self ] ;
	}
	return self ;
}

- (void)dealloc 
{
	[ netsend stopSampling ] ;
	[ netsend release ] ;
	[ super dealloc ] ;
}

- (void)netSend:(NetSend*)aNetSend needSamples:(int)samplesPerBuffer left:(float*)leftBuffer right:(float*)rightBuffer
{
	int i, n ;
	
	for ( i = 0; i < samplesPerBuffer; i++ ) {
		*leftBuffer++ = sin( phase ) ;
		phase += 0.06 ;
	}
	n = phase/(2*3.1415926535 ) ;
	phase -= n*2*3.1415926535 ;
}

- (IBAction)openNetSend:(id)sender
{
	if ( netsend ) [ netsend startSampling ] ;
}

- (IBAction)stopNetSend:(id)sender
{
	if ( netsend ) [ netsend stopSampling ] ;
}

@end
