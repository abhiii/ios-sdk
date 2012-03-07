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
//  IQEnginesRemote.m
//
// --------------------------------------------------------------------------------

#import "IQEnginesRemote.h"
#import "IQEnginesMisc.h"
#import "IQEDebug.h"

// PERSISTANT_UPDATE keeps Update call going no matter what.
#define PERSISTANT_UPDATE TRUE

#define TIMER_SEARCHING    5.0
#define TIMER_UPDATEDELAY 10.0

@interface IQEnginesRemote () <IQEnginesAPIDelegate>
- (void) applicationDidEnterBackground;
- (void) applicationWillEnterForeground;
- (void) searchTimeout:(id)object;
- (void) updateAfterDelay;
- (void) callIQEnginesUpdate;
@property(nonatomic, retain) IQEnginesAPI*   mIQEngines;
@property(nonatomic, retain) NSMutableArray* mQIDs;
@property(nonatomic, assign) BOOL            mUpdating;
@end

// --------------------------------------------------------------------------------
#pragma mark -
// --------------------------------------------------------------------------------

@implementation IQEnginesRemote

@synthesize delegate = mDelegate;
@synthesize mIQEngines;
@synthesize mQIDs;
@synthesize mUpdating;

- (id)initWithKey:(NSString *)apiKey secret:(NSString *)secret
{
    self = [super init];
    if (self)
    {
        // mUpdating keeps track of update state, so update won't be called if there is an existing call.
        mUpdating = NO;
        
        //
        // Set up notifications for multitasking.
        //
        
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
        &&  [[UIDevice currentDevice] isMultitaskingSupported])
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationDidEnterBackground)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationWillEnterForeground)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];
        }
        
        //
        // Initialize IQ Engines API.
        //
        
        NSString* deviceID = [IQEnginesMisc uniqueDeviceIdentifier];
        
        mIQEngines = [[IQEnginesAPI alloc] initWithKey:apiKey
                                                secret:secret
                                              deviceID:deviceID];
        mIQEngines.delegate = self;
        
        mQIDs = [[NSMutableArray alloc] initWithCapacity:0];

        //
        // Start Update.
        //
        
        if (mQIDs.count > 0 || PERSISTANT_UPDATE)
            [self callIQEnginesUpdate];
    }
    return self;
}

- (void)dealloc
{
    IQEDebugLog(@"%s", __func__);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [mQIDs release];
    
    mIQEngines.delegate = nil;
    [mIQEngines closeConnection];
    [mIQEngines release];
    
    [super dealloc];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEnginesRemote
// --------------------------------------------------------------------------------

- (NSString*)searchWithImage:(UIImage*)image
{
    CLLocationCoordinate2D location;
    
    location.latitude  = MAXFLOAT;
    location.longitude = MAXFLOAT;
    
    return [self searchWithImage:image atLocation:location];
}

- (NSString*)searchWithImage:(UIImage*)image atLocation:(CLLocationCoordinate2D)location;
{
    //
    // Perform remote Search with the image and location coordinates.
    //
    
    NSString* qid = [mIQEngines Query:image
                             latitude:location.latitude
                            longitude:location.longitude
                             altitude:MAXFLOAT];
    
    if (qid == nil || [qid isEqualToString:@""])
        return nil;
    
    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:statusDidChange:forQID:)])
        [mDelegate iqEnginesRemote:self statusDidChange:IQEnginesRemoteStatusUploading forQID:qid];
    
    if ([mQIDs indexOfObject:qid] == NSNotFound)
        [mQIDs addObject:qid];
    
    return qid;
}

- (void)searchWithQID:(NSString*)qid
{
    if (qid == nil || [qid isEqualToString:@""])
        return;
    
    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:statusDidChange:forQID:)])
        [mDelegate iqEnginesRemote:self statusDidChange:IQEnginesRemoteStatusSearching forQID:qid];

    if ([mQIDs indexOfObject:qid] == NSNotFound)
        [mQIDs addObject:qid];
    
    [mIQEngines Result:qid];
}

- (void)searchWithUPC:(NSString*)upc
{
    if (upc == nil || [upc isEqualToString:@""])
        return;

    [mIQEngines Barcode:upc];
}

- (void)updateResults:(NSDictionary *)results forQID:(NSString *)qid
{
    if (qid == nil || [qid isEqualToString:@""])
        return;
    
    // Feedback api does labels only AFAIK.
    NSString* labels = [results objectForKey:IQEnginesKeyLabels];
    if (labels == nil)
        return;
    
    [mIQEngines Feedback:qid labels:labels];
}

- (void)closeConnection
{
    [mIQEngines closeConnection];
    
    mUpdating = NO;
    
    [mQIDs removeAllObjects];
    
    // Remove all delayed performSelector:, they retain self.
    // Decrements retain count on self. Could call dealloc.
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)setDelegate:(id<IQEnginesRemoteDelegate>)delegate
{
    if (mDelegate == delegate)
        return;
    
    mDelegate = delegate;
    
    //
    // Cancel timed selector since there is no delegate to report status to.
    //
    
    if (mDelegate == nil)
    {
        // Remove all delayed performSelector:, they retain self.
        // Decrements retain count on self. Could call dealloc.
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    }
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Application lifecycle
// --------------------------------------------------------------------------------

- (void)applicationDidEnterBackground
{
    [self retain];
    
    //
    // Network connections stay open in the background which causes problems
    // when results become available. If the app doesn't process updates in
    // the background, the server will think the app is getting updates.
    // Those results will not be available from that point via the upadte call.
    // Closing the connection tells the server that the client is not accepting updates.
    //
    // This can be removed if there is code is written to handle updates in the background.
    //
    
    [self closeConnection];
    
    [self release];
}

- (void)applicationWillEnterForeground
{
    if (mQIDs.count > 0 || PERSISTANT_UPDATE)
        [self callIQEnginesUpdate];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private methods
// --------------------------------------------------------------------------------

- (void)searchTimeout:(id)object
{
    NSString* qid = object;
    
    if ([mQIDs indexOfObject:qid] != NSNotFound)
    {
        if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:statusDidChange:forQID:)])
            [mDelegate iqEnginesRemote:self statusDidChange:IQEnginesRemoteStatusNotReady forQID:qid];
    }
}

- (void)updateAfterDelay
{
    if (mQIDs.count > 0 || PERSISTANT_UPDATE)
        [self callIQEnginesUpdate];
}

- (void)callIQEnginesUpdate
{
    if (mUpdating == NO)
    {
        mUpdating = YES;
        
        [mIQEngines Update];
    }
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <IQEnginesAPIDelegate> implementation
// --------------------------------------------------------------------------------

// --------------------------------------------------------------------------------
// Query
// --------------------------------------------------------------------------------

- (void)queryComplete:(NSString*)qid
{
    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:statusDidChange:forQID:)])
        [mDelegate iqEnginesRemote:self statusDidChange:IQEnginesRemoteStatusSearching forQID:qid];
    
    //
    // Image uploaded successfully, call Update to wait for a result.
    //
    
    if ([mQIDs indexOfObject:qid] != NSNotFound)
    {
        // Start timer here to change status from searching to not ready if Update takes "too long".
        // Increments retain count on self.
        [self performSelector:@selector(searchTimeout:) withObject:qid afterDelay:TIMER_SEARCHING];
        
        [self callIQEnginesUpdate];
    }
}

- (void)query:(NSString*)qid failedWithError:(NSError*)error
{
    NSLog(@"query:%@ failedWithError:%@", qid, error.localizedDescription);
    
    [mQIDs removeObject:qid];
    
    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:statusDidChange:forQID:)])
        [mDelegate iqEnginesRemote:self statusDidChange:IQEnginesRemoteStatusError forQID:qid];
    
    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:failedWithError:)])
        [mDelegate iqEnginesRemote:self failedWithError:error];
}

// --------------------------------------------------------------------------------
// Update
// --------------------------------------------------------------------------------

- (void)updateCompleteWithResults:(NSArray*)results
{
    mUpdating = NO;
    
    for (NSDictionary* result in results)
    {
        NSString* qid = [result objectForKey:IQEnginesKeyQID];

        if (([mQIDs indexOfObject:qid] != NSNotFound) || PERSISTANT_UPDATE)
        {
            // Cancel timed call for this qid that sets status to not ready.
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(searchTimeout:) object:qid];

            NSDictionary* qidData = [result objectForKey:IQEnginesKeyQIDData];
            
            if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:statusDidChange:forQID:)])
                [mDelegate iqEnginesRemote:self statusDidChange:IQEnginesRemoteStatusComplete forQID:qid];

            if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:didCompleteSearch:forQID:)])
                [mDelegate iqEnginesRemote:self didCompleteSearch:qidData forQID:qid];

            [mQIDs removeObject:qid];
        }
    }
    
    //
    // Didn't find all our qids in these results, start another Update call
    // and wait to get some more results.
    //
    
    if (mQIDs.count > 0 || PERSISTANT_UPDATE)
        [self callIQEnginesUpdate];
}

- (void)updateFailedWithError:(NSError*)error
{
    mUpdating = NO;
    
    if (  error.code == NSURLErrorTimedOut
    &&  ([error.domain isEqualToString:NSURLErrorDomain]
    ||   [error.domain isEqualToString:IQEnginesErrorDomain]))
    {
        //
        // Update timed out, Ok. Start another update call.
        //
        
        if (mQIDs.count > 0 || PERSISTANT_UPDATE)
            [self callIQEnginesUpdate];
    }
    else
    {
        NSLog(@"%s %@", __func__, error.localizedDescription);
        
        if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:failedWithError:)])
            [mDelegate iqEnginesRemote:self failedWithError:error];
        
        //
        // Retry Update after a delay if there are qids waiting for results.
        //
        
        if (mQIDs.count > 0 || PERSISTANT_UPDATE)
            [self performSelector:@selector(updateAfterDelay) withObject:nil afterDelay:TIMER_UPDATEDELAY];
    }
}

// --------------------------------------------------------------------------------
// Result
// --------------------------------------------------------------------------------

- (void)result:(NSString*)qid completeNotAvailable:(NSString*)comment
{
    NSLog(@"result:%@ completeNotAvailable:%@", qid, comment);
    
    //
    // Result not ready. Start Update call to get result when it is.
    //
  
    if ([mQIDs indexOfObject:qid] != NSNotFound)
    {
        // Start timer here to change status to not ready if Update takes "too long".
        [self performSelector:@selector(searchTimeout:) withObject:qid afterDelay:TIMER_SEARCHING];
        
        [self callIQEnginesUpdate];
    }
}

- (void)result:(NSString*)qid completeWithResult:(NSDictionary*)result
{
    [mQIDs removeObject:qid];

    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:statusDidChange:forQID:)])
        [mDelegate iqEnginesRemote:self statusDidChange:IQEnginesRemoteStatusComplete forQID:qid];

    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:didCompleteSearch:forQID:)])
        [mDelegate iqEnginesRemote:self didCompleteSearch:result forQID:qid];
}

- (void)result:(NSString*)qid failedWithError:(NSError*)error
{
    NSLog(@"result:%@ failedWithError:%@", qid, error.localizedDescription);
    
    [mQIDs removeObject:qid];
    
    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:statusDidChange:forQID:)])
        [mDelegate iqEnginesRemote:self statusDidChange:IQEnginesRemoteStatusError forQID:qid];

    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:failedWithError:)])
        [mDelegate iqEnginesRemote:self failedWithError:error];
}

// --------------------------------------------------------------------------------
// Barcode
// --------------------------------------------------------------------------------

- (void)barcode:(NSString*)upc completeWithResult:(NSString*)label
{
    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:didCompleteSearch:forUPC:)])
        [mDelegate iqEnginesRemote:self didCompleteSearch:label forUPC:upc];
}

- (void)barcode:(NSString*)upc failedWithError:(NSError*)error
{
    NSLog(@"barcode:%@ failedWithError:%@", upc, error.localizedDescription);
    
    if ([mDelegate respondsToSelector:@selector(iqEnginesRemote:failedWithError:)])
        [mDelegate iqEnginesRemote:self failedWithError:error];
}

// --------------------------------------------------------------------------------
// Feedback
// --------------------------------------------------------------------------------

- (void)feedbackComplete:(NSString*)qid
{
    // Ignore.
}

- (void)feedback:(NSString *)qid failedWithError:(NSError*)error
{
    NSLog(@"feedback:%@ failedWithError:%@", qid, error.localizedDescription);

    // Ignore.
}

@end

// --------------------------------------------------------------------------------
