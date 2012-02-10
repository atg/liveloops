#import <TCMPortMapper/TCMPortMapper.h>
#import "CAPlayThroughController.h"

#include <math.h>

#import "LLRemoteHost.h"
#import "LLRemoteClient.h"
#import "LLLoop.h"
#import "constants.h"

#define LLTimestamp() ([NSDate timeIntervalSinceReferenceDate])

@implementation CAPlayThroughController

- (id)init
{
	return self;
}

- (void)awakeFromNib
{
    srandom(LLTimestamp());
    [self buildMenus];
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

- (NSString*)makeTemporaryFile {
    return [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"liveloops-temp-%ull", (unsigned long long)(random())]];
}
- (void)recordLoop {
    
    // Get the selected input device
    QTCaptureDevice* device = [[mInputDevices selectedItem] representedObject];
    if (!device)
        return;
    
    
    NSError* err = nil;
    [self stopCaptureSession];
    
    if (![device open:&err]) {
        NSLog(@"Could not open device: %@", err);
        return;
    }
    openedDevice = [device retain];
    
    QTCaptureDeviceInput* deviceinput = [[QTCaptureDeviceInput alloc] initWithDevice:device];
    session = [[QTCaptureSession alloc] init];
    if (![session addInput:deviceinput error:&err]) {
        NSLog(@"Error adding input: %@", err);
        return;
    }
    
    QTCaptureMovieFileOutput* fileout = [[QTCaptureMovieFileOutput alloc] init];
    captureSessionOutputPath = [[self makeTemporaryFile] copy];
    [fileout recordToOutputFileURL:[NSURL fileURLWithPath:captureSessionOutputPath isDirectory:NO]];
    
    if (![session addOutput:fileout error:&err]) {
        NSLog(@"Error adding output: %@", err);
        return;
    }
    
    captureSessionStart = LLTimestamp();
    [session startRunning];
    
    // Check back every 1/8 of a second
    [self checkOnCaptureSession];
}
- (void)stopCaptureSession {
    if (session) {
        
        
        [session stopRunning];
        [captureSessionOutputPath release];
        [session release];
        session = nil;
        captureSessionOutputPath = nil;
        [openedDevice close];
        [openedDevice release];
        openedDevice = nil;
    }
}
- (void)checkOnCaptureSession {
    NSLog(@"Checking capture session");
    if (captureSessionStart == 0)
        return;
    
    if (LLTimestamp() - captureSessionStart < 2.0) {
        [self performSelector:@selector(checkOnCaptureSession) withObject:nil afterDelay:0.125];
        return;
    }
    
    NSString* temppath = [[captureSessionOutputPath copy] autorelease];
    [self stopCaptureSession];
    
    if (loop) {
        [loop release];
        loop = nil;
    }
    loop = [[LLLoop alloc] init];
    loop.currentLoopOffset = fmod(captureSessionStart - playbackSessionStart, BAR_LENGTH);
    loop.audioData = [NSData dataWithContentsOfFile:temppath];
    [loop readMovie];
    
    if (loop.audioData && loop.movie)
        [self newInternalSamples];
    
    captureSessionStart = 0;
}

- (void)newInternalSamples {
    LLLoop* localloop = [loop retain];
    [serversQueue addOperationWithBlock:^{
        for (LLRemoteHost* host in remoteServers) {
            
            [host didChangeLocalLoop:localloop];
        }
        [localloop release];
    }];
    
    [self playLoop:localloop];
}
- (void)newExternalSamples {
    
}

- (void)stopLoop:(LLLoop*)liveloop {
    if (!liveloop)
        return;
    
    [[liveloop movie] stop];
}
- (void)playLoop:(LLLoop*)liveloop {
    [[liveloop movie] setAttribute:[NSNumber numberWithBool:YES] forKey:QTMovieLoopsAttribute];
    
    // Get the offset from the current bar
    // Both of these should be between 0 and BAR_LENGTH
    NSTimeInterval currentDistanceFromBar = fmod(LLTimestamp() - playbackSessionStart, BAR_LENGTH);
    NSTimeInterval wantedDistanceFromBar = liveloop.currentLoopOffset;
    
    
    QTTime qttime = QTMakeTimeWithTimeInterval(fmod(wantedDistanceFromBar - currentDistanceFromBar, BAR_LENGTH));
    [[liveloop movie] setCurrentTime:qttime];
    
    // Play!
    [[liveloop movie] play];
}



- (void) dealloc 
{

	[super dealloc];
}

- (void)start: (id)sender
{
}

- (void)stop: (id)sender
{
}

- (void)resetPlayThrough
{
}

- (IBAction)startStop:(id)sender
{
}

- (IBAction)record:(id)sender {
    
    [self recordLoop];
}

- (void)buildMenus {
    NSMenu* menu = [mInputDevices menu];
    [menu removeAllItems];
    
    for (QTCaptureDevice* inputdevice in [QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeSound]) {
        NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:[inputdevice localizedDisplayName] action:NULL keyEquivalent:@""];
        [item setRepresentedObject:inputdevice];
        [menu addItem:item];
    }
}
- (IBAction)inputDeviceSelected:(id)sender
{
    /*
	int val = [mInputDevices indexOfSelectedItem];
	AudioDeviceID newDevice =(mInputDeviceList->GetList())[val].mID;
	
	if(newDevice != inputDevice)
	{		
		[self stop:sender];
		inputDevice = newDevice;
		[self resetPlayThrough];
	}*/
}
/*
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
 */


@end

// QTKit capture class diagram
// https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/QTKitApplicationProgrammingGuide/UsingQTKit/UsingQTKit.html

// https://developer.apple.com/library/mac/#documentation/QuickTime/Reference/QTSampleBuffer_Ref/Introduction/Introduction.html
// https://developer.apple.com/library/mac/#samplecode/AudioDataOutputToAudioUnit/Listings/CaptureSessionController_m.html
// https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/QTKitApplicationProgrammingGuide/Introduction/Introduction.html
// http://stackoverflow.com/questions/2937720/using-qtkit-for-recording-audio
// https://developer.apple.com/library/mac/#samplecode/QTCaptureWidget/Listings/QTCapturePlugin_MyCaptureView_m.html#//apple_ref/doc/uid/DTS10004436-QTCapturePlugin_MyCaptureView_m-DontLinkElementID_4
