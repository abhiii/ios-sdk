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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class IQEnginesAPI;
@class IQEnginesRequestHandler;

// --------------------------------------------------------------------------------
//
// IQEnginesAPI Delegate 
//
// --------------------------------------------------------------------------------

@protocol IQEnginesAPIDelegate <NSObject>
@optional
- (void) queryComplete:(NSString*)qid;
- (void) query:(NSString*)qid failedWithError:(NSError*)error;
- (void) updateCompleteWithResults:(NSArray*)results;
- (void) updateFailedWithError:(NSError*)error;
- (void) result:(NSString*)qid completeNotAvailable:(NSString*)comment;
- (void) result:(NSString*)qid completeWithResult:(NSDictionary*)result;
- (void) result:(NSString*)qid failedWithError:(NSError*)error;
- (void) barcode:(NSString*)c completeWithResult:(NSString*)results;
- (void) barcode:(NSString*)c failedWithError:(NSError*)error;
- (void) feedbackComplete:(NSString*)qid;
- (void) feedback:(NSString*)qid failedWithError:(NSError*)error;
@end

// --------------------------------------------------------------------------------
//
// IQEnginesAPI
//
// The IQEnginesAPI class provides an objective c interface for IQ Engines image
// recognition server API.
//
// See http://www.iqengines.com/apidocs
//
// --------------------------------------------------------------------------------

@interface IQEnginesAPI : NSObject
{
    id<IQEnginesAPIDelegate> mDelegate;
    
    NSString* mAPIKey;
    NSString* mSecret;
    NSString* mDeviceID;
    
@private
    NSMutableArray*          mQueryRequestHandlers;
    NSMutableArray*          mResultRequestHandlers;
    NSMutableArray*          mBarcodeRequestHandlers;
    NSMutableArray*          mFeedbackRequestHandlers;
    IQEnginesRequestHandler* mUpdateRequestHandler;
}

@property(nonatomic, assign) id<IQEnginesAPIDelegate> delegate;

- (id)initWithKey:(NSString*)apiKey secret:(NSString*)secret;
- (id)initWithKey:(NSString*)apiKey secret:(NSString*)secret deviceID:(NSString*)deviceID;

- (NSString*) Query:(UIImage*)image;
- (NSString*) Query:(UIImage*)image latitude:(CLLocationDegrees)lat longitude:(CLLocationDegrees)lon altitude:(CLLocationDistance)alt;
- (void)      Update;
- (void)      Result:(NSString*)qid;
- (void)      Barcode:(NSString*)c;
- (void)      Feedback:(NSString*)qid labels:(NSString*)labels;

- (void) closeConnection;

@end

// --------------------------------------------------------------------------------

// Dictionary keys
extern NSString* const IQEnginesKeyQID;
extern NSString* const IQEnginesKeyQIDData;
extern NSString* const IQEnginesKeyColor;
extern NSString* const IQEnginesKeyISBN;
extern NSString* const IQEnginesKeyLabels;
extern NSString* const IQEnginesKeySKU;
extern NSString* const IQEnginesKeyUPC;
extern NSString* const IQEnginesKeyURL;
extern NSString* const IQEnginesKeyQRCode;
extern NSString* const IQEnginesKeyMeta;
extern NSString* const IQEnginesKeyObjId;

extern NSString* const IQEnginesErrorDomain;

// --------------------------------------------------------------------------------
