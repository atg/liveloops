- (void)createGraph
{
    OSStatus err;
    
    AUGraphStop(mGraph);
    AUGraphClose(mGraph);
    AUGraphUninitialize(mGraph);
    
    //Create the graph
    err = NewAUGraph(&mGraph);
    if(err) NSLog(@"NewAUGraph failed");
    
    //Open the graph
    err = AUGraphOpen(mGraph);
    if(err) NSLog(@"couldn't open graph");
    
    ComponentDescription desc;
    
    desc.componentType         = kAudioUnitType_Output;
    desc.componentSubType      = kAudioUnitSubType_DefaultOutput;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    desc.componentFlagsMask    = 0;
    desc.componentFlags        = 0;

    //Create the output node
    err = AUGraphAddNode(mGraph, (const AudioComponentDescription *)&desc, &mOutputNode);
    if(err) NSLog(@"couldn't create node for output unit");
    
    err = AUGraphNodeInfo(mGraph, mOutputNode, NULL, &mOutputUnit);
    if(err) NSLog(@"couldn't get output from node");
    
    
    desc.componentType = kAudioUnitType_Mixer;
    desc.componentSubType = kAudioUnitSubType_StereoMixer;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;

    //Create the mixer node
    err = AUGraphAddNode(mGraph, (const AudioComponentDescription *)&desc, &mMixerNode);
    if(err) NSLog(@"couldn't create node for file player");
    
    err = AUGraphNodeInfo(mGraph, mMixerNode, NULL, &mMixerUnit);
    if(err) NSLog(@"couldn't get player unit from node");

    desc.componentType = kAudioUnitType_FormatConverter;
    desc.componentSubType = kAudioUnitSubType_AUConverter;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    NSUInteger bufferCount = [gameCore soundBufferCount];
    
    for (int i = 0; i < bufferCount; ++i)
    {
        OEGameAudioContext *context = [OEGameAudioContext contextWithCore:gameCore bufferIndex:i];
        [self.contexts addObject:context];
        
        //Create the converter node
        err = AUGraphAddNode(mGraph, (const AudioComponentDescription *)&desc, &mConverterNode);
        if(err)  NSLog(@"couldn't create node for converter");
        
        err = AUGraphNodeInfo(mGraph, mConverterNode, NULL, &mConverterUnit);
        if(err) NSLog(@"couldn't get player unit from converter");
        
        
        AURenderCallbackStruct renderStruct;
        renderStruct.inputProc = RenderCallback;
        renderStruct.inputProcRefCon = context;
        
        err = AudioUnitSetProperty(mConverterUnit, kAudioUnitProperty_SetRenderCallback,
                                   kAudioUnitScope_Input, 0, &renderStruct, sizeof(AURenderCallbackStruct));
        if(err) DLog(@"Couldn't set the render callback");
        else DLog(@"Set the render callback");
        
        AudioStreamBasicDescription mDataFormat;
        NSUInteger channelCount = ((bufferCount == 1) ? [gameCore channelCount] : [gameCore channelCountForBuffer:i]);
        mDataFormat.mSampleRate       = (bufferCount == 1) ? [gameCore frameSampleRate] : [gameCore frameSampleRateForBuffer:i];
        mDataFormat.mFormatID         = kAudioFormatLinearPCM;
        mDataFormat.mFormatFlags      = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian;
        mDataFormat.mBytesPerPacket   = 2 * channelCount;
        mDataFormat.mFramesPerPacket  = 1; // this means each packet in the AQ has two samples, one for each channel -> 4 bytes/frame/packet
        mDataFormat.mBytesPerFrame    = 2 * channelCount;
        mDataFormat.mChannelsPerFrame = channelCount;
        mDataFormat.mBitsPerChannel   = 16;
        
        err = AudioUnitSetProperty(mConverterUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &mDataFormat, sizeof(AudioStreamBasicDescription));
        if(err) NSLog(@"couldn't set player's input stream format");
        
        err = AUGraphConnectNodeInput(mGraph, mConverterNode, 0, mMixerNode, i);
        if(err) NSLog(@"Couldn't connect the converter to the mixer");
    }
    // connect the player to the output unit (stream format will propagate)
         
    err = AUGraphConnectNodeInput(mGraph, mMixerNode, 0, mOutputNode, 0);
    if(err) NSLog(@"Could not connect the input of the output");
    
    
    //AudioUnitSetParameter(mOutputUnit, kAudioUnitParameterUnit_LinearGain, kAudioUnitScope_Global, 0, [[[GameDocumentController sharedDocumentController] preferenceController] volume] ,0);
    AudioUnitSetParameter(mOutputUnit, kAudioUnitParameterUnit_LinearGain, kAudioUnitScope_Global, 0, 1.0 ,0);
    
    err = AUGraphInitialize(mGraph);
    if(err) NSLog(@"couldn't initialize graph");
    
    err = AUGraphStart(mGraph);
    if(err) NSLog(@"couldn't start graph");
	
    
    NSLog(@"****Hello****");
    //    CFShow(mGraph);
    [self setVolume:[self volume]];
}