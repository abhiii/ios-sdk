/*
 Copyright (c) 2010-2012 IQ Engines, Inc.
 
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

#import "IQEnginesAPI.h"
#import "IQEnginesRequestHandler.h"
#import "IQEnginesQueryResultParser.h"
#import "IQEnginesUpdateResultParser.h"
#import "IQEnginesResultResultParser.h"
#import "IQEnginesBarcodeResultParser.h"
#import "IQEnginesFeedbackResultParser.h"
#import "IQEnginesUtils.h"

#define UPDATE_INTERVAL     300
#define RESULT_TIMEOUT       30

#define MINIMAL_DIMENSION   320
#define MAXIMAL_DIMENSION   427

#define JPEG_QUALITY        0.6

NSString* const IQEnginesKeyQID      = @"qid";
NSString* const IQEnginesKeyQIDData  = @"qid_data";
NSString* const IQEnginesKeyColor    = @"color";
NSString* const IQEnginesKeyISBN     = @"isbn";
NSString* const IQEnginesKeyLabels   = @"labels";
NSString* const IQEnginesKeySKU      = @"sku";
NSString* const IQEnginesKeyUPC      = @"upc";
NSString* const IQEnginesKeyURL      = @"url";
NSString* const IQEnginesKeyQRCode   = @"qrcode";
NSString* const IQEnginesKeyMeta     = @"meta";
NSString* const IQEnginesKeyObjId    = @"obj_id";

NSString* const IQEnginesErrorDomain = @"IQEnginesAPIErrorDomain";

static NSString* const IQEnginesKeyAPIKey       = @"api_key";
static NSString* const IQEnginesKeyDeviceID     = @"device_id";
static NSString* const IQEnginesKeyGPSLatitude  = @"gps_latitude";
static NSString* const IQEnginesKeyGPSLongitude = @"gps_longitude";
static NSString* const IQEnginesKeyGPSAltitude  = @"gps_altitude";
static NSString* const IQEnginesKeyImg          = @"img";
static NSString* const IQEnginesKeyC            = @"c";

static NSString* const QueryApiUrl    = @"http://api.iqengines.com/v1.2/query/?";
static NSString* const UpdateApiUrl   = @"http://api.iqengines.com/v1.2/update/?";
static NSString* const ResultApiUrl   = @"http://api.iqengines.com/v1.2/result/?";
static NSString* const BarcodeApiUrl  = @"http://api.iqengines.com/v1.2/barcode/?";
static NSString* const FeedbackApiUrl = @"http://api.iqengines.com/v1.2/feedback/?";

@interface IQEnginesAPI () <IQEnginesRequestHandlerDelegate>
- (void) handleQueryResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata;
- (void) handleUpdateResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata;
- (void) handleResultResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata;
- (void) handleBarcodeResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata;
- (void) handleFeedbackResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata;
@end

// --------------------------------------------------------------------------------
#pragma mark -
// --------------------------------------------------------------------------------

@implementation IQEnginesAPI

@synthesize delegate = mDelegate;

- (id)initWithKey:(NSString *)apiKey secret:(NSString *)secret
{
    self = [super init];
    if (self)
    {
        mAPIKey = [apiKey copy];
        mSecret = [secret copy];
    }
    return self;
}

- (id)initWithKey:(NSString*)apiKey secret:(NSString*)secret deviceID:(NSString*) deviceID
{
    self = [self initWithKey:apiKey secret:secret];
    if (self)
    {
        mDeviceID = [deviceID copy];
    }
    return self;
}

- (void)dealloc
{
    for (IQEnginesRequestHandler* requestHandler in mQueryRequestHandlers)
    {
        requestHandler.delegate = nil;
        [requestHandler closeConnection];
    }
    [mQueryRequestHandlers release];
    
    for (IQEnginesRequestHandler* requestHandler in mResultRequestHandlers)
    {
        requestHandler.delegate = nil;
        [requestHandler closeConnection];
    }
    [mResultRequestHandlers release];

    for (IQEnginesRequestHandler* requestHandler in mBarcodeRequestHandlers)
    {
        requestHandler.delegate = nil;
        [requestHandler closeConnection];
    }
    [mBarcodeRequestHandlers release];
    
    for (IQEnginesRequestHandler* requestHandler in mFeedbackRequestHandlers)
    {
        requestHandler.delegate = nil;
        [requestHandler closeConnection];
    }
    [mFeedbackRequestHandlers release];
    
    mUpdateRequestHandler.delegate = nil;
    [mUpdateRequestHandler closeConnection];
    [mUpdateRequestHandler release];
    
    [mAPIKey   release];
    [mSecret   release];
    [mDeviceID release];
    
    [super dealloc];
}

- (void) closeConnection
{
    for (IQEnginesRequestHandler* requestHandler in mQueryRequestHandlers)
        [requestHandler closeConnection];

    for (IQEnginesRequestHandler* requestHandler in mResultRequestHandlers)
        [requestHandler closeConnection];
    
    for (IQEnginesRequestHandler* requestHandler in mBarcodeRequestHandlers)
        [requestHandler closeConnection];
    
    for (IQEnginesRequestHandler* requestHandler in mFeedbackRequestHandlers)
        [requestHandler closeConnection];
    
    [mUpdateRequestHandler closeConnection];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEngines API methods
// --------------------------------------------------------------------------------

- (NSString*) Query:(UIImage*)image
{
    return [self Query:image latitude:MAXFLOAT longitude:MAXFLOAT altitude:MAXFLOAT];
}

- (NSString*) Query:(UIImage*)image
           latitude:(CLLocationDegrees)lat
          longitude:(CLLocationDegrees)lon
           altitude:(CLLocationDistance)alt;
{
    if (image == nil)
        return nil;
    
    //
    // Resize image.
    //
    
    UIImage* queryImage = [IQEnginesUtils scaleImage:[IQEnginesUtils fixImageRotation:image]
                              maxDimension1:MINIMAL_DIMENSION
                              maxDimension2:MAXIMAL_DIMENSION];

    //
    // Arguments.
    //
    
    NSString* gpsLatitude  = [NSString stringWithFormat:@"%.4f", lat];
    NSString* gpsLongitude = [NSString stringWithFormat:@"%.4f", lon];
    NSString* gpsAltitude  = [NSString stringWithFormat:@"%.4f", alt];
    
    NSMutableDictionary* arguments = [NSMutableDictionary dictionaryWithCapacity:0];
    
    [arguments setObject:mAPIKey forKey:IQEnginesKeyAPIKey];
    if (lat       != MAXFLOAT) [arguments setObject:gpsLatitude  forKey:IQEnginesKeyGPSLatitude];
    if (lon       != MAXFLOAT) [arguments setObject:gpsLongitude forKey:IQEnginesKeyGPSLongitude];
    if (alt       != MAXFLOAT) [arguments setObject:gpsAltitude  forKey:IQEnginesKeyGPSAltitude];
    if (mDeviceID != nil)      [arguments setObject:mDeviceID    forKey:IQEnginesKeyDeviceID];
    
    //
    // Additional arguments. Not used in signature calculation.
    //
    
    NSMutableDictionary* additionalArguments = [NSMutableDictionary dictionaryWithCapacity:0];
    
    NSData* imgData = UIImageJPEGRepresentation(queryImage, JPEG_QUALITY);
    if (imgData == nil)
    {
        NSLog(@"UIImageJPEGRepresentation error");
        return nil;
    }
    
    [additionalArguments setObject:imgData forKey:IQEnginesKeyImg];
    
    //
    // Start request.
    //
    
    IQEnginesRequestHandler* queryRequestHandler = [[IQEnginesRequestHandler alloc] init];
    
    queryRequestHandler.secret              = mSecret;
    queryRequestHandler.url                 = QueryApiUrl;
    queryRequestHandler.delegate            = self;
    queryRequestHandler.arguments           = arguments;
    queryRequestHandler.additionalArguments = additionalArguments;
    queryRequestHandler.userData            = [NSString stringWithFormat:@"%f.jpg", [NSDate timeIntervalSinceReferenceDate]];

    if (mQueryRequestHandlers == nil)
        mQueryRequestHandlers = [[NSMutableArray alloc] initWithCapacity:1];

    [mQueryRequestHandlers addObject:queryRequestHandler];
    
    // Return signature as qid.
    
    NSString* qid = [queryRequestHandler startRequest];
    [queryRequestHandler release];
    
    return qid;
}

- (void)Update
{
    //
    // Arguments.
    //
    
    NSMutableDictionary* arguments = [NSMutableDictionary dictionaryWithCapacity:0];
    
    [arguments setObject:mAPIKey       forKey:IQEnginesKeyAPIKey];
    if (mDeviceID != nil)
        [arguments setObject:mDeviceID forKey:IQEnginesKeyDeviceID];

    //
    // Start request.
    //
    
    [mUpdateRequestHandler closeConnection];
    [mUpdateRequestHandler release];
    mUpdateRequestHandler = [[IQEnginesRequestHandler alloc] init];
    
    mUpdateRequestHandler.secret              = mSecret;
    mUpdateRequestHandler.delegate            = self;
    mUpdateRequestHandler.timeout             = UPDATE_INTERVAL;
    mUpdateRequestHandler.url                 = UpdateApiUrl;
    mUpdateRequestHandler.arguments           = arguments;
    mUpdateRequestHandler.additionalArguments = nil;
    
    [mUpdateRequestHandler startRequest];
}

- (void)Result:(NSString*)qid
{
    //
    // Arguments.
    //
    
    if (qid == nil)
        return;

    NSMutableDictionary* arguments = [NSMutableDictionary dictionaryWithCapacity:0];
    
    [arguments setObject:mAPIKey forKey:IQEnginesKeyAPIKey];
    [arguments setObject:qid     forKey:IQEnginesKeyQID];

    //
    // Start request.
    //
    
    IQEnginesRequestHandler* resultRequestHandler = [[IQEnginesRequestHandler alloc] init];
    
    resultRequestHandler.secret              = mSecret;
    resultRequestHandler.delegate            = self;
    resultRequestHandler.timeout             = RESULT_TIMEOUT;
    resultRequestHandler.url                 = ResultApiUrl;
    resultRequestHandler.arguments           = arguments;
    resultRequestHandler.additionalArguments = nil;
    
    if (mResultRequestHandlers == nil)
        mResultRequestHandlers = [[NSMutableArray alloc] initWithCapacity:1];
    
    [mResultRequestHandlers addObject:resultRequestHandler];

    [resultRequestHandler startRequest];
    [resultRequestHandler release];
}

- (void)Barcode:(NSString *)c
{
    //
    // Arguments.
    //

    if (c == nil)
        return;
    
    NSMutableDictionary* arguments = [NSMutableDictionary dictionaryWithCapacity:0];
    
    [arguments setObject:mAPIKey forKey:IQEnginesKeyAPIKey];
    [arguments setObject:c       forKey:IQEnginesKeyC];
    
    //
    // Start request.
    //
    
    IQEnginesRequestHandler* barcodeRequestHandler = [[IQEnginesRequestHandler alloc] init];
    
    barcodeRequestHandler.secret              = mSecret;
    barcodeRequestHandler.delegate            = self;
    barcodeRequestHandler.timeout             = RESULT_TIMEOUT;
    barcodeRequestHandler.url                 = BarcodeApiUrl;
    barcodeRequestHandler.arguments           = arguments;
    barcodeRequestHandler.additionalArguments = nil;
    
    if (mBarcodeRequestHandlers == nil)
        mBarcodeRequestHandlers = [[NSMutableArray alloc] initWithCapacity:1];
    
    [mBarcodeRequestHandlers addObject:barcodeRequestHandler];
    
    [barcodeRequestHandler startRequest];
    [barcodeRequestHandler release];
}

- (void)Feedback:(NSString*)qid labels:(NSString*)labels
{
    //
    // Arguments.
    //
    
    if (qid == nil || labels == nil)
        return;
    
    NSMutableDictionary* arguments = [NSMutableDictionary dictionaryWithCapacity:0];
    
    [arguments setObject:mAPIKey forKey:IQEnginesKeyAPIKey];
    [arguments setObject:qid     forKey:IQEnginesKeyQID];
    [arguments setObject:labels  forKey:IQEnginesKeyLabels];
    
    //
    // Start request.
    //
    
    IQEnginesRequestHandler* feedbackRequestHandler = [[IQEnginesRequestHandler alloc] init];
    
    feedbackRequestHandler.secret              = mSecret;
    feedbackRequestHandler.delegate            = self;
    feedbackRequestHandler.timeout             = RESULT_TIMEOUT;
    feedbackRequestHandler.url                 = FeedbackApiUrl;
    feedbackRequestHandler.arguments           = arguments;
    feedbackRequestHandler.additionalArguments = nil;
    
    if (mFeedbackRequestHandlers == nil)
        mFeedbackRequestHandlers = [[NSMutableArray alloc] initWithCapacity:1];
    
    [mFeedbackRequestHandlers addObject:feedbackRequestHandler];
    
    [feedbackRequestHandler startRequest];
    [feedbackRequestHandler release];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <IQEnginesRequestHandlerDelegate> implementation
// --------------------------------------------------------------------------------

- (void)request:(IQEnginesRequestHandler*)request responseCompleteWithData:(NSData*)xmldata
{
#ifdef IQE_DEBUG
    if (xmldata.length != 0)
        NSLog(@"response =\n%@\n", [[[NSString alloc] initWithBytes:xmldata.bytes
                                                             length:xmldata.length
                                                           encoding:NSUTF8StringEncoding]
                                    autorelease]);
#endif
    
    if ([mQueryRequestHandlers containsObject:request])
    {
        [self handleQueryResult:request data:xmldata];
        
        request.delegate = nil;
        [request closeConnection];
        [mQueryRequestHandlers removeObject:request];
    }
    else
    if ([mResultRequestHandlers containsObject:request])
    {
        [self handleResultResult:request data:xmldata];
        
        request.delegate = nil;
        [request closeConnection];
        [mResultRequestHandlers removeObject:request];
    }
    else
    if ([mBarcodeRequestHandlers containsObject:request])
    {
        [self handleBarcodeResult:request data:xmldata];
            
        request.delegate = nil;
        [request closeConnection];
        [mBarcodeRequestHandlers removeObject:request];
    }
    else
    if ([mFeedbackRequestHandlers containsObject:request])
    {
        [self handleFeedbackResult:request data:xmldata];
        
        request.delegate = nil;
        [request closeConnection];
        [mFeedbackRequestHandlers removeObject:request];
    }
    else
    if (request == mUpdateRequestHandler)
        [self handleUpdateResult:request data:xmldata];
}

- (void)request:(IQEnginesRequestHandler*)request responseFailedWithError:(NSError*)error
{
    NSLog(@"IQEngines responseFailedWithError =\n%@", error);
    
    if ([mQueryRequestHandlers containsObject:request])
    {
        NSString* qid = request.signature;

        if ([mDelegate respondsToSelector:@selector(query:failedWithError:)])
            [mDelegate query:qid failedWithError:error];
        
        request.delegate = nil;
        [request closeConnection];
        [mQueryRequestHandlers removeObject:request];
    }
    else 
    if ([mResultRequestHandlers containsObject:request])
    {
        NSString* qid = [request.arguments objectForKey:IQEnginesKeyQID];
        
        if ([mDelegate respondsToSelector:@selector(result:failedWithError:)])
            [mDelegate result:qid failedWithError:error];

        request.delegate = nil;
        [request closeConnection];
        [mResultRequestHandlers removeObject:request];
    }
    else
    if ([mBarcodeRequestHandlers containsObject:request])
    {
        NSString* c = [request.arguments objectForKey:IQEnginesKeyC];
        
        if ([mDelegate respondsToSelector:@selector(barcode:failedWithError:)])
            [mDelegate barcode:c failedWithError:error];
        
        request.delegate = nil;
        [request closeConnection];
        [mBarcodeRequestHandlers removeObject:request];
    }
    else
    if ([mFeedbackRequestHandlers containsObject:request])
    {
        NSString* qid = [request.arguments objectForKey:IQEnginesKeyQID];
        
        if ([mDelegate respondsToSelector:@selector(feedback:failedWithError:)])
            [mDelegate feedback:qid failedWithError:error];
        
        request.delegate = nil;
        [request closeConnection];
        [mFeedbackRequestHandlers removeObject:request];
    }
    else
    if (request == mUpdateRequestHandler)
    {
        if ([mDelegate respondsToSelector:@selector(updateFailedWithError:)])
            [mDelegate updateFailedWithError:error];
    }
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private methods
// --------------------------------------------------------------------------------

- (void) handleQueryResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata
{
    NSString* qid = request.signature;

    IQEnginesQueryResultParser* response = [[IQEnginesQueryResultParser alloc] initWithXMLData:xmldata];
    if (!response)
    {
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:-1 userInfo:nil];
        
        if ([mDelegate respondsToSelector:@selector(query:failedWithError:)])
            [mDelegate query:qid failedWithError:error];
    }
    else
    if (!response.found || response.errorCode != 0)
    {
        NSDictionary* dict = [NSDictionary dictionaryWithObject:NSLocalizedString(response.comment, @"")
                                                         forKey:NSLocalizedDescriptionKey];
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:response.errorCode userInfo:dict];
        
        if ([mDelegate respondsToSelector:@selector(query:failedWithError:)])
            [mDelegate query:qid failedWithError:error];
    }
    else
    {
        if ([mDelegate respondsToSelector:@selector(queryComplete:)])
            [mDelegate queryComplete:qid];
    }
    
    [response release];
}

- (void) handleUpdateResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata
{
    if (request.statusCode == 504  // Gateway Timeout
    ||  request.statusCode == 408  // Request Timeout
    ||  xmldata.length     == 0)   // Update returns successfully with no data
    {
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:NSURLErrorTimedOut userInfo:nil];
        
        if ([mDelegate respondsToSelector:@selector(updateFailedWithError:)])
            [mDelegate updateFailedWithError:error];
        return;
    }
    
    IQEnginesUpdateResultParser* response = [[IQEnginesUpdateResultParser alloc] initWithXMLData:xmldata];
    if (!response)
    {
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:-1 userInfo:nil];
        
        if ([mDelegate respondsToSelector:@selector(updateFailedWithError:)])
            [mDelegate updateFailedWithError:error];
    }
    else
    if (!response.found || response.errorCode != 0)
    {
        NSDictionary* dict = [NSDictionary dictionaryWithObject:NSLocalizedString(response.comment, @"")
                                                         forKey:NSLocalizedDescriptionKey];
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:response.errorCode userInfo:dict];
        
        if ([mDelegate respondsToSelector:@selector(updateFailedWithError:)])
            [mDelegate updateFailedWithError:error];
    }
    else
    {
        if ([mDelegate respondsToSelector:@selector(updateCompleteWithResults:)])
            [mDelegate updateCompleteWithResults:response.results];
    }
    
    [response release];
}

- (void) handleResultResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata
{
    NSString* qid = [request.arguments objectForKey:IQEnginesKeyQID];
    
    IQEnginesResultResultParser* response = [[IQEnginesResultResultParser alloc] initWithXMLData:xmldata];
    if (!response)
    {
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:-1 userInfo:nil];
        
        if ([mDelegate respondsToSelector:@selector(result:failedWithError:)])
            [mDelegate result:qid failedWithError:error];
    }
    else
    if (!response.found || response.errorCode != 0)
    {
        NSDictionary* dict = [NSDictionary dictionaryWithObject:NSLocalizedString(response.comment, @"")
                                                         forKey:NSLocalizedDescriptionKey];
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:response.errorCode userInfo:dict];
        
        if ([mDelegate respondsToSelector:@selector(result:failedWithError:)])
            [mDelegate result:qid failedWithError:error];
    }
    else
    {
        if (response.results != nil)
        {
            if ([mDelegate respondsToSelector:@selector(result:completeWithResult:)])
                [mDelegate result:qid completeWithResult:response.results];
        }
        else
        {
            if ([mDelegate respondsToSelector:@selector(result:completeNotAvailable:)])
                [mDelegate result:qid completeNotAvailable:response.comment];         
        }
    }
    
    [response release];
}

- (void) handleBarcodeResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata
{
    NSString* c = [request.arguments objectForKey:IQEnginesKeyC];
    
    IQEnginesBarcodeResultParser* response = [[IQEnginesBarcodeResultParser alloc] initWithXMLData:xmldata];
    if (!response)
    {
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:-1 userInfo:nil];
        
        if ([mDelegate respondsToSelector:@selector(barcode:failedWithError:)])
            [mDelegate barcode:c failedWithError:error];
    }
    else
    if (!response.found || response.errorCode != 0)
    {
        NSDictionary* dict = [NSDictionary dictionaryWithObject:NSLocalizedString(response.comment, @"")
                                                         forKey:NSLocalizedDescriptionKey];
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:response.errorCode userInfo:dict];
        
        if ([mDelegate respondsToSelector:@selector(barcode:failedWithError:)])
            [mDelegate barcode:c failedWithError:error];
    }
    else
    {
        if ([mDelegate respondsToSelector:@selector(barcode:completeWithResult:)])
            [mDelegate barcode:c completeWithResult:response.results];
    }
    
    [response release];
}

- (void) handleFeedbackResult:(IQEnginesRequestHandler*)request data:(NSData*)xmldata
{
    NSString* qid = [request.arguments objectForKey:IQEnginesKeyQID];
    
    IQEnginesFeedbackResultParser* response = [[IQEnginesFeedbackResultParser alloc] initWithXMLData:xmldata];
    if (!response)
    {
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:-1 userInfo:nil];
        
        if ([mDelegate respondsToSelector:@selector(feedback:failedWithError:)])
            [mDelegate feedback:qid failedWithError:error];
    }
    else
    if (!response.found || response.errorCode != 0)
    {
        NSDictionary* dict = [NSDictionary dictionaryWithObject:NSLocalizedString(response.comment, @"")
                                                         forKey:NSLocalizedDescriptionKey];
        NSError* error = [NSError errorWithDomain:IQEnginesErrorDomain code:response.errorCode userInfo:dict];
        
        if ([mDelegate respondsToSelector:@selector(feedback:failedWithError:)])
            [mDelegate feedback:qid failedWithError:error];
    }
    else
    {
        if ([mDelegate respondsToSelector:@selector(feedbackComplete:)])
            [mDelegate feedbackComplete:qid];
    }
    
    [response release];
}

@end
