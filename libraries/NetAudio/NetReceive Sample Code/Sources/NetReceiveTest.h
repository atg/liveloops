//
//  NetReceiveTest.h
//  Audio Unit Tests
//
//  Created by Kok Chen on 11/12/07.

	#import <Cocoa/Cocoa.h>
	#import <NetAudio/NetReceive.h>


	@interface NetReceiveTest : NSObject {
	
		IBOutlet id ip ;
		IBOutlet id port ;
		IBOutlet id service ;
		IBOutlet id scope ;
		
		NetReceive *netreceive ;
		float doubleBuffer[512] ;
	}

	- (IBAction)openNetReceive:(id)sender ;
	- (IBAction)stopNetReceive:(id)sender ;
	
	@end
