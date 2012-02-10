/*	Copyright � 2007 Apple Inc. All Rights Reserved.
	
	Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
			Apple Inc. ("Apple") in consideration of your agreement to the
			following terms, and your use, installation, modification or
			redistribution of this Apple software constitutes acceptance of these
			terms.  If you do not agree with these terms, please do not use,
			install, modify or redistribute this Apple software.
			
			In consideration of your agreement to abide by the following terms, and
			subject to these terms, Apple grants you a personal, non-exclusive
			license, under Apple's copyrights in this original Apple software (the
			"Apple Software"), to use, reproduce, modify and redistribute the Apple
			Software, with or without modifications, in source and/or binary forms;
			provided that if you redistribute the Apple Software in its entirety and
			without modifications, you must retain this notice and the following
			text and disclaimers in all such redistributions of the Apple Software. 
			Neither the name, trademarks, service marks or logos of Apple Inc. 
			may be used to endorse or promote products derived from the Apple
			Software without specific prior written permission from Apple.  Except
			as expressly stated in this notice, no other rights or licenses, express
			or implied, are granted by Apple herein, including but not limited to
			any patent rights that may be infringed by your derivative works or by
			other works in which the Apple Software may be incorporated.
			
			The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
			MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
			THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
			FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
			OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
			
			IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
			OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
			SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
			INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
			MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
			AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
			STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
			POSSIBILITY OF SUCH DAMAGE.
*/

#import <TCMPortMapper/TCMPortMapper.h>
#import "CAPlayThroughController.h"

#import "LLRemoteHost.h"
#import "LLRemoteClient.h"
#import "LLLoop.h"

@implementation CAPlayThroughController
static void	BuildDeviceMenu(AudioDeviceList *devlist, NSPopUpButton *menu, AudioDeviceID initSel);

- (id)init
{
	mInputDeviceList = new AudioDeviceList(true);
	mOutputDeviceList = new AudioDeviceList(false);
	return self;
}

- (void)awakeFromNib
{
	UInt32 propsize=0;
    AudioObjectPropertyAddress aopa;
    		
	propsize = sizeof(AudioDeviceID);

    aopa.mSelector = kAudioHardwarePropertyDefaultInputDevice;
    aopa.mScope = kAudioObjectPropertyScopeGlobal;
    aopa.mElement = kAudioObjectPropertyElementMaster;
    verify_noerr(AudioObjectGetPropertyData(kAudioObjectSystemObject, &aopa, 0, NULL, &propsize, &inputDevice));

	propsize = sizeof(AudioDeviceID);
    aopa.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
    aopa.mScope = kAudioObjectPropertyScopeGlobal;
    aopa.mElement = kAudioObjectPropertyElementMaster;
    verify_noerr(AudioObjectGetPropertyData(kAudioObjectSystemObject, &aopa, 0, NULL, &propsize, &outputDevice));
	
	BuildDeviceMenu(mInputDeviceList, mInputDevices, inputDevice);
	BuildDeviceMenu(mOutputDeviceList, mOutputDevices, outputDevice);
	
	playThroughHost = new CAPlayThroughHost(inputDevice,outputDevice);
	if(!playThroughHost)
	{
		NSLog(@"ERROR: playThroughHost init failed!");
		exit(1);
	}
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // Find out our host
        NSString* str = [[NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://whatismyip.akamai.com/"] encoding:NSUTF8StringEncoding error:NULL] copy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [listenHost setStringValue:[str autorelease]];
        });
    });
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(portMapperDidFinishWork:) name:TCMPortMapperDidFinishWorkNotification object:[TCMPortMapper sharedInstance]];
}
- (void)disconnect {
    [NSApp terminate:nil];
}
- (IBAction)connect:(id)sender {
    NSLog(@"[sender state] = %d", [sender state]);
//    if (![sender state]) {
        //[self disconnect];
//        return;
//    }
    
    // We want to listen on our host port
    NSLog(@"[arrayController content] = %@", [arrayController content]);
    for (NSDictionary* remoteHost in [arrayController content]) {
        if (![[remoteHost valueForKey:@"host"] length])
            continue;
        
        int port = [[remoteHost valueForKey:@"port"] integerValue] ?: 6292;
        NSString* host = [[remoteHost valueForKey:@"host"] copy];
        [[MAAsyncHost hostWithName:host] connectToPort:port callback:^(MAAsyncReader *reader, MAAsyncWriter *writer, NSError *error) {
            
            if (error) {
                NSLog(@"error = %@", error);
                return;
            }
            
            LLRemoteHost* newserver = [[LLRemoteHost alloc] init];
            newserver.hostname = host;
            newserver.needsDataUpdate = YES;
            [host release];
            
            [serversQueue addOperationWithBlock:^{
                [remoteServers addObject:newserver];
                [newserver release];
            }];
        }];
    }
    
    // Listen away
    int port = [listenPort intValue];
    
    TCMPortMapper *pm = [TCMPortMapper sharedInstance];
    [pm addPortMapping:[TCMPortMapping portMappingWithLocalPort:port desiredExternalPort:port transportProtocol:TCMPortMappingTransportProtocolTCP userInfo:nil]];
    [pm start];
    if (![pm isAtWork]) {
        [self portMapperDidFinishWork:nil];
    }
}
- (void)removeServer:(LLRemoteHost*)server {
    [serversQueue addOperationWithBlock:^{
        [remoteServers removeObject:server];
    }];
}
- (void)removeClient:(LLRemoteClient*)client {
    [clientsQueue addOperationWithBlock:^{
        [remoteClients removeObject:client];
    }];
}

- (void)portMapperDidFinishWork:(NSNotification *)aNotification {
    
    NSError* err = nil;
    listener = [MAAsyncSocketListener listenerWith4and6WithPortRange: NSMakeRange([listenPort intValue], 1) tryRandom:NO error:&err];
    NSLog(@"Creating listener: %@ / %@", listener, err);
    
    [listener setAcceptCallback: ^(MAAsyncReader *reader, MAAsyncWriter *writer, NSData *peerAddress) {
        
        LLRemoteClient* newclient = [[LLRemoteClient alloc] init];
        newclient.peeraddress = peerAddress;
        newclient.reader = reader;
        
        [clientsQueue addOperationWithBlock:^{
            [remoteClients addObject:newclient];
            [newclient release];
        }];
    }];
}
- (void)applicationWillTerminate:(id)t {
    [[TCMPortMapper sharedInstance] stopBlocking];
}


- (void)newInternalSamples {
    
}
- (void)newExternalSamples {
    
}


- (void) dealloc 
{
	delete playThroughHost;			
	playThroughHost =0;

	delete mInputDeviceList;
	delete mOutputDeviceList;

	[super dealloc];
}

- (void)start: (id)sender
{
	if( !playThroughHost->IsRunning())
	{
		[mStartButton setTitle:@" Press to Stop"];
		playThroughHost->Start();
		[mProgress setHidden: NO];
		[mProgress startAnimation:sender];
	}
}

- (void)stop: (id)sender
{
	if( playThroughHost->IsRunning())
	{	
		[mStartButton setTitle:@"Start Play Through"];
		playThroughHost->Stop();
		[mProgress setHidden: YES];
		[mProgress stopAnimation:sender];
	}
}

- (void)resetPlayThrough
{
	if(playThroughHost->PlayThroughExists())
		playThroughHost->DeletePlayThrough();
	
	playThroughHost->CreatePlayThrough(inputDevice, outputDevice);
}

- (IBAction)startStop:(id)sender
{

	if(!playThroughHost->PlayThroughExists())
	{
		playThroughHost->CreatePlayThrough(inputDevice, outputDevice);
	}
		
	if( !playThroughHost->IsRunning())
		[self start:sender];
	
	else
		[self stop:sender];
}

- (IBAction)inputDeviceSelected:(id)sender
{
	int val = [mInputDevices indexOfSelectedItem];
	AudioDeviceID newDevice =(mInputDeviceList->GetList())[val].mID;
	
	if(newDevice != inputDevice)
	{		
		[self stop:sender];
		inputDevice = newDevice;
		[self resetPlayThrough];
	}
}

- (IBAction)outputDeviceSelected:(id)sender
{
	int val = [mOutputDevices indexOfSelectedItem];
	AudioDeviceID newDevice = (mOutputDeviceList->GetList())[val].mID;
	
	if(newDevice != outputDevice)
	{ 
		[self stop:sender];
		outputDevice = newDevice;
		[self resetPlayThrough];
	}
}

static void	BuildDeviceMenu(AudioDeviceList *devlist, NSPopUpButton *menu, AudioDeviceID initSel)
{
	[menu removeAllItems];

	AudioDeviceList::DeviceList &thelist = devlist->GetList();
	int index = 0;
	for (AudioDeviceList::DeviceList::iterator i = thelist.begin(); i != thelist.end(); ++i, ++index) {
		while([menu itemWithTitle:[NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding]] != nil) {
			strcat((*i).mName, " ");
		}

		if([menu itemWithTitle:[NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding]] == nil) {
			[menu insertItemWithTitle: [NSString stringWithCString: (*i).mName encoding:NSASCIIStringEncoding] atIndex:index];

		if (initSel == (*i).mID)
			[menu selectItemAtIndex: index];
		}
	}
}

@end
