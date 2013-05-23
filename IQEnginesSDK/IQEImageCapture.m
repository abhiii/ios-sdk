/*
 Copyright (c) 2011-2012 IQ Engines, Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
*/

// --------------------------------------------------------------------------------
//
//  IQEImageCapture.m
//
// --------------------------------------------------------------------------------

#import "IQEImageCapture.h"
#import "IQEnginesMisc.h"
#import "IQEDebug.h"

#define MAXIMAL_DIMENSION   640
#define MINIMAL_DIMENSION   480

@interface IQEImageCapture ()
- (void)                      addVideoPreviewLayer;
- (void)                      addVideoInput;
- (void)                      addVideoDataOutput;
- (void)                      addStillImageOutput;
- (AVCaptureVideoOrientation) cameraOrientation;
- (UIImage*)                  scaleImage:(UIImage*)uiImage maxDimension1:(NSUInteger)maxDimension1 maxDimension2:(NSUInteger)maxDimension2;
- (void)                      onCaptureSessionRuntimeError:(NSNotification*)n;
@property(retain)            AVCaptureSession*          mCaptureSession;
@property(nonatomic, retain) AVCaptureVideoDataOutput*  mVideoOut;
@property(nonatomic, retain) AVCaptureStillImageOutput* mStillImageOutput;
@property(nonatomic, retain) NSString*                  mSessionPreset;
@property(nonatomic, retain) NSString*                  mSessionPresetStill;
@end

// --------------------------------------------------------------------------------
#pragma mark -
// --------------------------------------------------------------------------------

@implementation IQEImageCapture

@synthesize delegate       = mDelegate;
@synthesize previewLayer   = mPreviewLayer;
@synthesize mCaptureSession;
@synthesize mVideoOut;
@synthesize mStillImageOutput;
@synthesize mSessionPreset;
@synthesize mSessionPresetStill;

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEImageCapture lifecycle
// --------------------------------------------------------------------------------

- (id)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onCaptureSessionRuntimeError:)
                                                     name:AVCaptureSessionRuntimeErrorNotification
                                                   object:nil];
        
        mCaptureSession = [[AVCaptureSession alloc] init];
        
        // configure capture session
        [self addVideoInput];
        [self addVideoDataOutput];
        [self addStillImageOutput];
        
        // Set up video preview layer
        [self addVideoPreviewLayer];
        
        /*
        Preset                                3G        3GS     4 back  4 front
        AVCaptureSessionPresetHigh       400x304    640x480   1280x720  640x480
        AVCaptureSessionPresetMedium     400x304    480x360    480x360  480x360
        AVCaptureSessionPresetLow        400x304    192x144    192x144  192x144
        AVCaptureSessionPreset640x480         NA    640x480    640x480  640x480
        AVCaptureSessionPreset1280x720        NA         NA   1280x720       NA
        AVCaptureSessionPresetPhoto    1600x1200  2048x1536  2592x1936  640x480
        */
        
        /*
        if ([mCaptureSession canSetSessionPreset:AVCaptureSessionPresetPhoto])    NSLog(@"canSetSessionPreset AVCaptureSessionPresetPhoto");
        if ([mCaptureSession canSetSessionPreset:AVCaptureSessionPresetLow])      NSLog(@"canSetSessionPreset AVCaptureSessionPresetLow");
        if ([mCaptureSession canSetSessionPreset:AVCaptureSessionPresetMedium])   NSLog(@"canSetSessionPreset AVCaptureSessionPresetMedium");
        if ([mCaptureSession canSetSessionPreset:AVCaptureSessionPresetHigh])     NSLog(@"canSetSessionPreset AVCaptureSessionPresetHigh");
        if ([mCaptureSession canSetSessionPreset:AVCaptureSessionPreset640x480])  NSLog(@"canSetSessionPreset AVCaptureSessionPreset640x480");
        if ([mCaptureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) NSLog(@"canSetSessionPreset AVCaptureSessionPreset1280x720");
        */
        
        self.mSessionPreset      = mCaptureSession.sessionPreset;
        self.mSessionPresetStill = mCaptureSession.sessionPreset;
        
        // iPhone 3G == iPhone1,2
        // Need bigger image than 400x304 to return a 640x480 size for still frames.
        
        if ([[IQEnginesMisc platform] isEqualToString:@"iPhone1,2"])
        {
            if ([mCaptureSession canSetSessionPreset:AVCaptureSessionPresetPhoto])
                self.mSessionPresetStill = AVCaptureSessionPresetPhoto;
            
            if ([mCaptureSession canSetSessionPreset:AVCaptureSessionPresetHigh])
                self.mSessionPreset = AVCaptureSessionPresetHigh;
        }
        else
        {
            if ([mCaptureSession canSetSessionPreset:AVCaptureSessionPreset640x480])
            {
                self.mSessionPreset      = AVCaptureSessionPreset640x480;
                self.mSessionPresetStill = AVCaptureSessionPreset640x480;
            }
        }
        
        if ([mCaptureSession canSetSessionPreset:self.mSessionPreset])
            mCaptureSession.sessionPreset = self.mSessionPreset;
        else
            NSLog(@"Can not set AVCaptureSession sessionPreset, using default %@", mCaptureSession.sessionPreset);
        
        IQEDebugLog(@"AVCaptureSession sessionPreset %@", mCaptureSession.sessionPreset);
    }

    return self;
}

- (void)dealloc
{
    IQEDebugLog(@"%s", __func__);

    if (mCaptureSession.running)
        [mCaptureSession stopRunning];
    
    if ([mCaptureSession.outputs containsObject:mVideoOut])
        [mCaptureSession removeOutput:mVideoOut];
    
    [mVideoOut setSampleBufferDelegate:nil queue:nil];
    [mVideoOut release];
    mVideoOut = nil;
    
    [mPreviewLayer       release];
    [mStillImageOutput   release];
    [mCaptureSession     release];
    [mSessionPreset      release];
    [mSessionPresetStill release];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEImageCapture
// --------------------------------------------------------------------------------

- (void)captureStillFrame
{
    AVCaptureConnection* videoConnection = nil;
    
    for (AVCaptureConnection* connection in mStillImageOutput.connections)
    {
        for (AVCaptureInputPort* port in connection.inputPorts)
        {
            if ([port.mediaType isEqual:AVMediaTypeVideo])
            {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection)
            break;
    }
    
    if (videoConnection == nil)
        return;
    
    if ([videoConnection isVideoOrientationSupported])
        [videoConnection setVideoOrientation:[self cameraOrientation]];
    
    [mStillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection 
                       completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError* error)
        {
            if (imageSampleBuffer != nil)
            {
                NSData*  imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
                UIImage* image     = [[UIImage alloc] initWithData:imageData];
                
                IQEDebugLog(@"AVCaptureStillImageOutput: %@", NSStringFromCGSize(image.size));
                
                //
                // Resize image if it is bigger than expected.
                //
                
                if ((image.size.width > MAXIMAL_DIMENSION || image.size.height > MINIMAL_DIMENSION)
                &&  (image.size.width > MINIMAL_DIMENSION || image.size.height > MAXIMAL_DIMENSION))
                {
                    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

                    UIImage* resizedImage = [self scaleImage:image
                                               maxDimension1:MAXIMAL_DIMENSION
                                               maxDimension2:MINIMAL_DIMENSION];
                    
                    IQEDebugLog(@"AVCaptureStillImageOutput image resized from %@ to %@",
                             NSStringFromCGSize(image.size),
                             NSStringFromCGSize(resizedImage.size));
                    
                    [image release];
                    
                    [mDelegate didCaptureStillFrame:resizedImage];
                    [pool drain];
                }
                else
                {
                    [mDelegate didCaptureStillFrame:image];
                    [image release];
                }
            }
            else
            {
                NSLog(@"%s error: %@", __func__, error);
            }
        }
    ];
}

- (void) startCamera
{
    if (mCaptureSession.running == NO)
        [mCaptureSession startRunning];
}

- (void) stopCamera
{
    if (mCaptureSession.running)
        [mCaptureSession stopRunning];
}

- (void) startCapture
{
    if ([mCaptureSession.outputs containsObject:mVideoOut] == YES)
        return;
    
    BOOL wasRunning = NO;
    
    if (mCaptureSession.running)
    {
        wasRunning = YES;
        [mCaptureSession stopRunning];
    }
    
    [mCaptureSession beginConfiguration];
    {
        if ([mCaptureSession.outputs containsObject:mVideoOut] == NO)
        {
            if ([mCaptureSession canAddOutput:mVideoOut])
               [mCaptureSession addOutput:mVideoOut];
        }
        
        if ([mCaptureSession canSetSessionPreset:mSessionPreset]
        &&  mCaptureSession.sessionPreset != mSessionPreset)
            mCaptureSession.sessionPreset = mSessionPreset;
    }
    [mCaptureSession commitConfiguration];
    
    if (mCaptureSession.running == NO && wasRunning == YES)
        [mCaptureSession startRunning];
}

- (void) stopCapture
{
    if ([mCaptureSession.outputs containsObject:mVideoOut] == NO)
        return;
    
    BOOL wasRunning = NO;
    
    if (mCaptureSession.running)
    {
        wasRunning = YES;
        [mCaptureSession stopRunning];
    }
    
    [mCaptureSession beginConfiguration];
    {
        if ([mCaptureSession.outputs containsObject:mVideoOut])
            [mCaptureSession removeOutput:mVideoOut];
        
        if ([mCaptureSession canSetSessionPreset:mSessionPresetStill]
        &&  mCaptureSession.sessionPreset != mSessionPresetStill)
            mCaptureSession.sessionPreset = mSessionPresetStill;
    }
    [mCaptureSession commitConfiguration];
    
    if (mCaptureSession.running == NO && wasRunning == YES)
        [mCaptureSession startRunning];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private methods
// --------------------------------------------------------------------------------

#pragma mark Capture Session Configuration

- (void)addVideoPreviewLayer
{
    mPreviewLayer              = [[AVCaptureVideoPreviewLayer alloc] initWithSession:mCaptureSession];
    mPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void)addStillImageOutput
{
    self.mStillImageOutput = [[[AVCaptureStillImageOutput alloc] init] autorelease];
    
    NSDictionary* outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    AVVideoCodecJPEG,
                                    AVVideoCodecKey,
                                    nil];
    
    [mStillImageOutput setOutputSettings:outputSettings];
    
    [mCaptureSession addOutput:mStillImageOutput];
}

- (void)addVideoInput
{
    AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (videoDevice)
    {
        NSError* error;
        AVCaptureDeviceInput* videoIn = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (!error)
        {
            if ([mCaptureSession canAddInput:videoIn])
                [mCaptureSession addInput:videoIn];
            else
                NSLog(@"Couldn't add video input");
        }
        else
        {
            NSLog(@"Couldn't create video input:%@", error.localizedDescription);
        }
    }
    else
    {
        NSLog(@"Couldn't create video capture device");
    }
}

- (void)addVideoDataOutput
{
    self.mVideoOut = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
    
    mVideoOut.alwaysDiscardsLateVideoFrames = YES;
    mVideoOut.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                          forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    dispatch_queue_t my_queue = dispatch_queue_create("com.iqengines.IQEImageCapture", NULL);
    [mVideoOut setSampleBufferDelegate:self queue:my_queue];
    dispatch_release(my_queue);
}

- (AVCaptureVideoOrientation)cameraOrientation
{
    UIDeviceOrientation       deviceOrientation = [UIDevice currentDevice].orientation;
    AVCaptureVideoOrientation newOrientation;
    
    // AVCapture and UIDevice have opposite meanings for landscape left and right
    // (AVCapture orientation is the same as UIInterfaceOrientation)
    if (deviceOrientation == UIDeviceOrientationPortrait)           newOrientation = AVCaptureVideoOrientationPortrait;           else
    if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown) newOrientation = AVCaptureVideoOrientationPortraitUpsideDown; else
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft)      newOrientation = AVCaptureVideoOrientationLandscapeRight;     else
    if (deviceOrientation == UIDeviceOrientationLandscapeRight)     newOrientation = AVCaptureVideoOrientationLandscapeLeft;      else
    if (deviceOrientation == UIDeviceOrientationUnknown)            newOrientation = AVCaptureVideoOrientationPortrait;           else
                                                                    newOrientation = AVCaptureVideoOrientationPortrait;
    return newOrientation;
}

- (UIImage*)scaleImage:(UIImage*)uiImage maxDimension1:(NSUInteger)maxDimension1 maxDimension2:(NSUInteger)maxDimension2
{
    CGSize inputSize = CGSizeMake(CGImageGetWidth(uiImage.CGImage), CGImageGetHeight(uiImage.CGImage));
    
    // Determine max size.
    NSUInteger biggerMaxDimension  = (maxDimension1 > maxDimension2) ? maxDimension1 : maxDimension2;
    NSUInteger smallerMaxDimension = (maxDimension1 > maxDimension2) ? maxDimension2 : maxDimension1;
    
    CGSize maxSize;
    if (inputSize.width > inputSize.height)
        maxSize = CGSizeMake(biggerMaxDimension, smallerMaxDimension);
    else
        maxSize = CGSizeMake(smallerMaxDimension, biggerMaxDimension);
    
    // Determine final size.
    CGSize finalSize = inputSize;
    if ((finalSize.width > maxSize.width) || (finalSize.height > maxSize.height))
    {
        if (finalSize.width > maxSize.width)
        {
            CGSize oldSize   = finalSize;
            finalSize.width  = maxSize.width;
            finalSize.height = (finalSize.width * oldSize.height) / oldSize.width;
        }
        
        if (finalSize.height > maxSize.height)
        {
            CGSize oldSize   = finalSize;
            finalSize.height = maxSize.height;
            finalSize.width  = (finalSize.height * oldSize.width) / oldSize.height;
        }
        
        finalSize.width  = ceilf(finalSize.width);
        finalSize.height = ceilf(finalSize.height);
    }
    
    // Make scaled image.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)finalSize.width,
                                                 (size_t)finalSize.height,
                                                 8,
                                                 4 * ((size_t)finalSize.width),
                                                 colorSpace,
                                                 kCGImageAlphaNoneSkipLast);
    CGColorSpaceRelease(colorSpace);
    
    CGRect outputRect = CGRectZero;
    outputRect.size   = finalSize;
    
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextDrawImage(context, outputRect, uiImage.CGImage);
    
    CGImageRef outputCGImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage* output = [UIImage imageWithCGImage:outputCGImage
                                          scale:uiImage.scale
                                    orientation:uiImage.imageOrientation];
    CGImageRelease(outputCGImage);
    
    return output;
}

- (void)onCaptureSessionRuntimeError:(NSNotification*)n
{
    NSError* error = [n.userInfo objectForKey:AVCaptureSessionErrorKey];
    
    NSLog(@"AVCaptureSessionRuntimeError: %@", error);
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <AVCaptureVideoDataOutputSampleBufferDelegate> implementation
// --------------------------------------------------------------------------------

- (void)captureOutput:(AVCaptureOutput*)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection*)connection
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    [mDelegate retain];
    [mDelegate didCaptureSampleBuffer:sampleBuffer];
    [mDelegate release];
    
    [pool drain];
}

@end

// --------------------------------------------------------------------------------
