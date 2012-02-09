//
//  NetSendTest.h
//  Audio Unit Tests
//
//  Created by Kok Chen on 11/12/07.

	#import <Cocoa/Cocoa.h>
	#import <NetAudio/NetSend.h>

	@interface NetSendTest : NSObject {
		NetSend *netsend ;
		float phase ;
	}

	- (IBAction)openNetSend:(id)sender ;
	- (IBAction)stopNetSend:(id)sender ;
	
	@end
