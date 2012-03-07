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
//  IQEnginesLocal.h
//
// --------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <CoreMedia/CMSampleBuffer.h>

@class IQEnginesLocal;

typedef enum
{
    IQEnginesLocalSearchTypeObjectSearch = 1 << 0,
    IQEnginesLocalSearchTypeBarCode      = 1 << 1,
    IQEnginesLocalSearchTypeAll          = 0xFFFFFFFF,
} IQEnginesLocalSearchType;

// --------------------------------------------------------------------------------
//
// IQEnginesLocal Delegate 
//
// --------------------------------------------------------------------------------

@protocol IQEnginesLocalDelegate <NSObject>

// Called when an image search has completed successfully.
// Results for the image search are contained in the results dictionary parameter.
// The result dictionary keys are defined below.
- (void) iqEnginesLocal:(IQEnginesLocal*)iqe didCompleteSearch:(IQEnginesLocalSearchType)type withResults:(NSDictionary*)result forQID:(NSString*)qid;

// Called when a search has failed.
- (void) iqEnginesLocal:(IQEnginesLocal*)iqe failedWithError:(NSError*)error;

@end

// --------------------------------------------------------------------------------
//
// IQEnginesLocal
//
// The IQEnginesLocal class provides an interface for IQ Engines image recognition.
// Local databases and bar/qr codes can be used to search for image information.
//
// --------------------------------------------------------------------------------

@interface IQEnginesLocal : NSObject
{
    id<IQEnginesLocalDelegate> mDelegate;

@private
    IQEnginesLocalSearchType mSearchType;
}

// The designated initializer.
// dataPath is location of the objects.json file and associated files.

- (id) initWithParameters:(IQEnginesLocalSearchType)searchType dataPath:(NSString*)path;

// Create a unique ID to track image search.
+ (NSString*) uniqueQueryID;

// Perform an image recognition search on an image. 
// On success, results are returned to the delegate asynchronously with the
// iqEnginesLocal:didCompleteSearch:withResults:forQID: messsage.
// iqEnginesLocal:failedWithError: is called on failure.

- (void) searchWithImage:(UIImage*)image qid:(NSString*)qid;

// Perform an image recognition search on an image in CMSampleBuffer format.
// Intended for use with AVCaptureVideoDataOutput dispatch queue.
// On success, results are returned to the delegate with the
// iqEnginesLocal:didCompleteSearch:withResults:forQID: messsage.
// iqEnginesLocal:failedWithError: is called on failure.
// Returns the number of items found.

- (NSInteger) searchWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@property(nonatomic, assign) id<IQEnginesLocalDelegate> delegate;

@end

// --------------------------------------------------------------------------------

// Dictionary keys for iqEnginesLocal:didCompleteSearch:withResults:forQID:
extern NSString* const IQEnginesLocalKeyObjectId;
extern NSString* const IQEnginesLocalKeyObjectName;
extern NSString* const IQEnginesLocalKeyObjectMeta;
extern NSString* const IQEnginesLocalKeyObjectImagePath;
extern NSString* const IQEnginesLocalKeyBarcodeData;
extern NSString* const IQEnginesLocalKeyBarcodeType;

// IQEnginesLocalKeyBarcodeType
extern NSString* const IQEnginesLocalBarcodeCODE39;
extern NSString* const IQEnginesLocalBarcodeCODE93;
extern NSString* const IQEnginesLocalBarcodeCODE128;
extern NSString* const IQEnginesLocalBarcodeCOMPOSITE;
extern NSString* const IQEnginesLocalBarcodeDATABAR;
extern NSString* const IQEnginesLocalBarcodeDATABAR_EXP;
extern NSString* const IQEnginesLocalBarcodeEAN2;
extern NSString* const IQEnginesLocalBarcodeEAN5;
extern NSString* const IQEnginesLocalBarcodeEAN8;
extern NSString* const IQEnginesLocalBarcodeEAN13;
extern NSString* const IQEnginesLocalBarcodeI25;
extern NSString* const IQEnginesLocalBarcodeISBN10;
extern NSString* const IQEnginesLocalBarcodeISBN13;
extern NSString* const IQEnginesLocalBarcodePDF417;
extern NSString* const IQEnginesLocalBarcodeQRCODE;
extern NSString* const IQEnginesLocalBarcodeUPCE;
extern NSString* const IQEnginesLocalBarcodeUPCA;

// --------------------------------------------------------------------------------
