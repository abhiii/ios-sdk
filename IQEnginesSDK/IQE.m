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
//  IQE.m
//
// --------------------------------------------------------------------------------

#import "IQE.h"
#import "IQEConfig.h"
#import "IQEDebug.h"
#import "IQEImageCapture.h"
#import "IQEnginesLocal.h"
#import "IQEnginesRemote.h"

#define IQEDATA_PATH @"iqedata"

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQE Private interface
// --------------------------------------------------------------------------------

@interface IQE () <IQEnginesLocalDelegate,
                   IQEnginesRemoteDelegate,
                   IQEImageCaptureDelegate>
@property(nonatomic, assign) IQESearchType    mSearchType;
@property(nonatomic, retain) NSString*        mApiKey;
@property(nonatomic, retain) NSString*        mApiSecret;
@property(nonatomic, assign) IQEnginesRemote* mIQEnginesRemote;
@property(nonatomic, assign) IQEnginesLocal*  mIQEnginesLocal;
@property(nonatomic, assign) IQEImageCapture* mIQEImageCapture;
@end

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQE implementation
// --------------------------------------------------------------------------------

@implementation IQE

// remote dictionary keys
NSString* const IQEKeyQID                 = @"qid";
NSString* const IQEKeyQIDData             = @"qid_data";
NSString* const IQEKeyColor               = @"color";
NSString* const IQEKeyISBN                = @"isbn";
NSString* const IQEKeyLabels              = @"labels";
NSString* const IQEKeySKU                 = @"sku";
NSString* const IQEKeyUPC                 = @"upc";
NSString* const IQEKeyURL                 = @"url";
NSString* const IQEKeyQRCode              = @"qrcode";
NSString* const IQEKeyMeta                = @"meta";
NSString* const IQEKeyObjId               = @"obj_id";
// local dictionary keys
NSString* const IQEKeyObjectId            = @"objectId";
NSString* const IQEKeyObjectName          = @"objectName";
NSString* const IQEKeyObjectMeta          = @"objectMeta";
NSString* const IQEKeyObjectImagePath     = @"objectImagePath";
NSString* const IQEKeyBarcodeData         = @"barcodeData";
NSString* const IQEKeyBarcodeType         = @"barcodeType";

NSString* const IQEBarcodeTypeCODE39      = @"CODE-39";
NSString* const IQEBarcodeTypeCODE93      = @"CODE-93";
NSString* const IQEBarcodeTypeCODE128     = @"CODE-128";
NSString* const IQEBarcodeTypeCOMPOSITE   = @"COMPOSITE";
NSString* const IQEBarcodeTypeDATABAR     = @"DataBar";
NSString* const IQEBarcodeTypeDATABAR_EXP = @"DataBar-Exp";
NSString* const IQEBarcodeTypeEAN2        = @"EAN-2";
NSString* const IQEBarcodeTypeEAN5        = @"EAN-5";
NSString* const IQEBarcodeTypeEAN8        = @"EAN-8";
NSString* const IQEBarcodeTypeEAN13       = @"EAN-13";
NSString* const IQEBarcodeTypeISBN10      = @"ISBN-10";
NSString* const IQEBarcodeTypeISBN13      = @"ISBN-13";
NSString* const IQEBarcodeTypeI25         = @"I2/5";
NSString* const IQEBarcodeTypePDF417      = @"PDF417";
NSString* const IQEBarcodeTypeQRCODE      = @"QR-Code";
NSString* const IQEBarcodeTypeUPCA        = @"UPC-A";
NSString* const IQEBarcodeTypeUPCE        = @"UPC-E";

@synthesize delegate = mDelegate;
@synthesize mSearchType;
@synthesize mApiKey;
@synthesize mApiSecret;
@synthesize mIQEnginesRemote;
@synthesize mIQEnginesLocal;
@synthesize mIQEImageCapture;
@synthesize autoDetection;

- (id)init
{
    return [self initWithParameters:IQESearchTypeAll];
}

- (id)initWithParameters:(IQESearchType)searchType
{
    return [self initWithParameters:searchType apiKey:nil apiSecret:nil];
}

- (id)initWithParameters:(IQESearchType)searchType apiKey:(NSString*)key apiSecret:(NSString*)secret
{
    self = [super init];
    if (self)
    {
        mSearchType     = searchType;
        self.mApiKey    = key;
        self.mApiSecret = secret;
        autoDetection   = YES;
        
        //
        // Init local search.
        //
        
        if (mSearchType & IQESearchTypeBarCode
        ||  mSearchType & IQESearchTypeObjectSearch)
        {
            IQEnginesLocalSearchType localSearchType = 0;
        
            localSearchType |= (mSearchType & IQESearchTypeBarCode     ) ? IQEnginesLocalSearchTypeBarCode      : 0;
            localSearchType |= (mSearchType & IQESearchTypeObjectSearch) ? IQEnginesLocalSearchTypeObjectSearch : 0;
        
            NSString* dataPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:IQEDATA_PATH];

            mIQEnginesLocal = [[IQEnginesLocal alloc] initWithParameters:localSearchType dataPath:dataPath];
            
            mIQEnginesLocal.delegate = self;
        }
        
        //
        // Init remote search.
        //
        
        if (mSearchType & IQESearchTypeRemoteSearch)
        {
            mIQEnginesRemote = [[IQEnginesRemote alloc] initWithKey:mApiKey secret:mApiSecret];
            
            mIQEnginesRemote.delegate = self;
        }
        
        //
        // Init IQEImageCapture.
        //

        mIQEImageCapture = nil;
        
#if IQE_IMAGE_CAPTURE
        if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iPhoneOS_3_2)
        {
            mIQEImageCapture = [[IQEImageCapture alloc] init];
            
            mIQEImageCapture.delegate = self;

            if ((mSearchType & IQESearchTypeBarCode || mSearchType & IQESearchTypeObjectSearch)
            &&  autoDetection == YES)
                [mIQEImageCapture startCapture];
            else
                [mIQEImageCapture stopCapture];
        }
#endif
    }
    return self;
}

- (void)dealloc
{
    IQEDebugLog(@"%s", __func__);
    
    [mApiKey    release];
    [mApiSecret release];
    
    mIQEnginesRemote.delegate = nil;
    mIQEnginesLocal.delegate  = nil;
    mIQEImageCapture.delegate = nil;
    
    [mIQEImageCapture stopCamera];
    
    [mIQEImageCapture release];
    [mIQEnginesRemote release];
    [mIQEnginesLocal  release];
    
    [super dealloc];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQE
// --------------------------------------------------------------------------------

- (void)startCamera
{
    [mIQEImageCapture startCamera];
}

- (void)stopCamera
{
    [mIQEImageCapture stopCamera];
}

- (void)captureStillFrame
{
    [mIQEImageCapture captureStillFrame];
}

- (NSString*)searchWithImage:(UIImage*)image
{
    CLLocationCoordinate2D location;
    
    location.latitude  = MAXFLOAT;
    location.longitude = MAXFLOAT;
    
    return [self searchWithImage:image atLocation:location];
}

- (NSString*)searchWithImage:(UIImage*)image atLocation:(CLLocationCoordinate2D)location
{
    /* 
     Which search to do depends on how IQE is configured.
     Start a remote search first since it may take longer than local search.
     Use the same qid from the remote for the local search.
     */
    
    NSString* qid = nil;
    
    if (mSearchType & IQESearchTypeRemoteSearch)
        qid = [mIQEnginesRemote searchWithImage:image atLocation:location];
    
    if ((self.autoDetection == NO)
    && (mSearchType & IQESearchTypeBarCode
    ||  mSearchType & IQESearchTypeObjectSearch))
    {
        if (qid == nil)
            qid = [IQEnginesLocal uniqueQueryID];
        
        [mIQEnginesLocal searchWithImage:image qid:qid];
    }
    
    return qid;
}

- (void) searchWithQID:(NSString*)qid
{
    [mIQEnginesRemote searchWithQID:qid];
}

- (void) updateResults:(NSDictionary*)results forQID:(NSString*)qid
{
    [mIQEnginesRemote updateResults:results forQID:qid];
}

- (CALayer*) previewLayer
{
    return mIQEImageCapture.previewLayer;
}

- (void) setAutoDetection:(BOOL)detectionOn
{
    if (self.autoDetection == detectionOn)
        return;
    
    autoDetection = detectionOn;
    
    if (self.autoDetection == YES)
        [mIQEImageCapture startCapture];
    else
        [mIQEImageCapture stopCapture];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private methods
// --------------------------------------------------------------------------------

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <IQEnginesRemoteDelegate> implementation
// --------------------------------------------------------------------------------

- (void)iqEnginesRemote:(IQEnginesRemote*)iqe didCompleteSearch:(NSDictionary*)results forQID:(NSString *)qid
{
    if ([mDelegate respondsToSelector:@selector(iqEngines:didCompleteSearch:withResults:forQID:)])
        [mDelegate iqEngines:self didCompleteSearch:IQESearchTypeRemoteSearch withResults:results forQID:qid];
}

- (void)iqEnginesRemote:(IQEnginesRemote*)iqe didCompleteSearch:(NSString*)results forUPC:(NSString *)upc
{
    if ([mDelegate respondsToSelector:@selector(iqEngines:didFindBarcodeDescription:forUPC:)])
        [mDelegate iqEngines:self didFindBarcodeDescription:results forUPC:upc];
}

- (void)iqEnginesRemote:(IQEnginesRemote*)iqe statusDidChange:(IQEnginesRemoteStatus)status forQID:(NSString*)qid
{
    if ([mDelegate respondsToSelector:@selector(iqEngines:statusDidChange:forQID:)])
    {
        IQEStatus iqeStatus = IQEStatusUnknown;
        
        switch (status)
        {
            case IQEnginesRemoteStatusUnknown:   iqeStatus = IQEStatusUnknown;   break;
            case IQEnginesRemoteStatusError:     iqeStatus = IQEStatusError;     break;
            case IQEnginesRemoteStatusUploading: iqeStatus = IQEStatusUploading; break;
            case IQEnginesRemoteStatusSearching: iqeStatus = IQEStatusSearching; break;
            case IQEnginesRemoteStatusNotReady:  iqeStatus = IQEStatusNotReady;  break;
            case IQEnginesRemoteStatusComplete:  iqeStatus = IQEStatusComplete;  break;
                
            default:
                break;
        }

        [mDelegate iqEngines:self statusDidChange:iqeStatus forQID:qid];
    }
}

- (void)iqEnginesRemote:(IQEnginesRemote*)iqe failedWithError:(NSError*)error
{
    NSLog(@"iqEnginesRemote:failedWithError %@", error.localizedDescription);
    
    if ([mDelegate respondsToSelector:@selector(iqEngines:failedWithError:)])
        [mDelegate iqEngines:self failedWithError:error];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <IQEnginesLocalDelegate> implementation
// --------------------------------------------------------------------------------

- (void)iqEnginesLocal:(IQEnginesLocal*)iqe
     didCompleteSearch:(IQEnginesLocalSearchType)type
           withResults:(NSDictionary*)results
                forQID:(NSString*)qid
{
    if (type == IQEnginesLocalSearchTypeBarCode)
    {
        if ([mDelegate respondsToSelector:@selector(iqEngines:didCompleteSearch:withResults:forQID:)])
            [mDelegate iqEngines:self didCompleteSearch:IQESearchTypeBarCode withResults:results forQID:qid];
        
        // Not found. Don't do label retrieval.
        if (results.count == 0)
            return;
        
        //
        // Get label for barcode from remote IQE server.
        //
        
        NSString* barData     = [results objectForKey:IQEnginesLocalKeyBarcodeData];
        NSString* barTypeName = [results objectForKey:IQEnginesLocalKeyBarcodeType];
        
        if ([barTypeName isEqualToString:IQEnginesLocalBarcodeQRCODE] == NO)
        {
            if (mIQEnginesRemote == nil && mApiKey && mApiSecret)
            {
                mIQEnginesRemote = [[IQEnginesRemote alloc] initWithKey:mApiKey secret:mApiSecret];
                
                mIQEnginesRemote.delegate = self;
            }
            
            [mIQEnginesRemote searchWithUPC:barData];
        }
    }
    else
    if (type == IQEnginesLocalSearchTypeObjectSearch)
    {
        if ([mDelegate respondsToSelector:@selector(iqEngines:didCompleteSearch:withResults:forQID:)])
            [mDelegate iqEngines:self didCompleteSearch:IQESearchTypeObjectSearch withResults:results forQID:qid];
    }
}

- (void)iqEnginesLocal:(IQEnginesLocal*)iqe failedWithError:(NSError*)error
{
    NSLog(@"iqEnginesLocal:failedWithError %@", error.localizedDescription);

    if ([mDelegate respondsToSelector:@selector(iqEngines:failedWithError:)])
        [mDelegate iqEngines:self failedWithError:error];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <IQEImageCaptureDelegate> implementation
// --------------------------------------------------------------------------------

- (void)didCaptureStillFrame:(UIImage*)image
{
    // Single frame capture. Pass up to IQE delegate.
    if ([mDelegate respondsToSelector:@selector(iqEngines:didCaptureStillFrame:)])
        [mDelegate iqEngines:self didCaptureStillFrame:image];
}

- (void)didCaptureSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // Process images from the image capture queue locally.
    [mIQEnginesLocal searchWithSampleBuffer:sampleBuffer];
}

@end

// --------------------------------------------------------------------------------

