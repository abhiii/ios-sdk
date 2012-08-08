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
//  IQEnginesRemote.h
//
// --------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "IQEnginesAPI.h"

@class IQEnginesRemote;

typedef enum
{
    IQEnginesRemoteStatusUnknown,
    IQEnginesRemoteStatusError,
    IQEnginesRemoteStatusUploading,
    IQEnginesRemoteStatusSearching,
    IQEnginesRemoteStatusNotReady,
    IQEnginesRemoteStatusComplete,
} IQEnginesRemoteStatus;

// --------------------------------------------------------------------------------
//
// IQEnginesRemote Delegate 
//
// --------------------------------------------------------------------------------

@protocol IQEnginesRemoteDelegate <NSObject>
@optional

// Called when an image search has completed successfully.
// Results for the image search are contained in the results dictionary parameter.
// The result dictionary keys are defined in IQEnginesAPI.h.
- (void) iqEnginesRemote:(IQEnginesRemote*)iqe didCompleteSearch:(NSArray*)results forQID:(NSString*)qid;

// Called when a search for a UPC label has completed successfully.
- (void) iqEnginesRemote:(IQEnginesRemote*)iqe didCompleteSearch:(NSString*)label forUPC:(NSString*)upc;

// Status changes for a particular query ID are returned with this message.
- (void) iqEnginesRemote:(IQEnginesRemote*)iqe statusDidChange:(IQEnginesRemoteStatus)status forQID:(NSString*)qid;

// Called when a search has failed.
- (void) iqEnginesRemote:(IQEnginesRemote*)iqe failedWithError:(NSError*)error;

@end

// --------------------------------------------------------------------------------
//
// IQEnginesRemote
//
// The IQEnginesRemote class provides an interface for IQ Engines image recognition.
// Remote databases can be used to search for image information.
//
// --------------------------------------------------------------------------------

@interface IQEnginesRemote : NSObject
{
    id<IQEnginesRemoteDelegate> mDelegate;

@private
    IQEnginesAPI* mIQEngines;
}

// The designated initializer.
// IQ Engines key and secret parameters are required.

- (id) initWithKey:(NSString*)apiKey secret:(NSString*)secret;

// Perform an image recognition search on an image. Returns a query ID string. 
// On success, results are returned to the delegate asynchronously with the
// iqEnginesRemote:didCompleteSearch:forQID: messsage.
// iqEnginesRemote:failedWithError: is called on failure.
// Location information can be provided to enhance results using the location parameter.

- (NSString*) searchWithImage:(UIImage*)image;
- (NSString*) searchWithImage:(UIImage*)image atLocation:(CLLocationCoordinate2D)location;

// Retrieves results for a previous image search.
- (void) searchWithQID:(NSString*)qid;

// Search for a description/label given a UPC code.
- (void) searchWithUPC:(NSString*)upc;

// Called to update user modified results for a particular query ID.
- (void) updateResults:(NSDictionary*)results forQID:(NSString*)qid;

// Disconnect from the IQEngines server.
- (void) closeConnection;

@property(nonatomic, assign) id<IQEnginesRemoteDelegate> delegate;

@end

// --------------------------------------------------------------------------------

