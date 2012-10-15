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
//  IQE.h
//
// --------------------------------------------------------------------------------

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreLocation/CoreLocation.h>

@class IQE;

typedef enum
{
    IQESearchTypeObjectSearch = 1 << 0,
    IQESearchTypeRemoteSearch = 1 << 1,
    IQESearchTypeBarCode      = 1 << 2,
    IQESearchTypeAll          = 0xFFFFFFFF,
} IQESearchType;

typedef enum
{
    IQEStatusUnknown,
    IQEStatusError,
    IQEStatusUploading,
    IQEStatusSearching,
    IQEStatusNotReady,
    IQEStatusComplete,
} IQEStatus;

// --------------------------------------------------------------------------------
//
// IQE Delegate 
//
// --------------------------------------------------------------------------------

@protocol IQEDelegate <NSObject>
@optional

// Called when an image search has completed successfully.
// The type parameter indicates what type of image was detected.
// Results for the image search are contained in the results array parameter. The keys are listed below.
- (void) iqEngines:(IQE*)iqe didCompleteSearch:(IQESearchType)type withResults:(NSArray*)results forQID:(NSString*)qid;

// Called when an image search has failed.
- (void) iqEngines:(IQE*)iqe failedWithError:(NSError*)error;

// Status changes for a particular query ID are returned with this message.
- (void) iqEngines:(IQE*)iqe statusDidChange:(IQEStatus)status forQID:(NSString*)qid;

// Called when a description becomes available for a barcode search type.
- (void) iqEngines:(IQE*)iqe didFindBarcodeDescription:(NSString*)desc forUPC:(NSString*)upc;

// Called in response to captureStillFrame:
- (void) iqEngines:(IQE*)iqe didCaptureStillFrame:(UIImage*)image;
@end

// --------------------------------------------------------------------------------
//
// IQE
//
// The IQE class provides an interface for IQ Engines image recognition.
// Remote and local databases can be used to search for image information.
// Encapsulates image capture from the default camera device. 
//
// --------------------------------------------------------------------------------

@interface IQE : NSObject
{
    id<IQEDelegate> mDelegate;
}

// The designated initializers.
// Provide your IQ Engines key and secret parameters when using the IQESearchTypeRemoteSearch type.

- (id)initWithParameters:(IQESearchType)searchType;
- (id)initWithParameters:(IQESearchType)searchType apiKey:(NSString*)key apiSecret:(NSString*)secret;

@property(nonatomic, assign) id<IQEDelegate> delegate;

@property(nonatomic, assign)   BOOL     autoDetection; // Automatic local detection. default is YES
@property(nonatomic, readonly) CALayer* previewLayer;  // Previews visual output of the camera device.

// Set key and secret pair after initialization.
- (void) setApiKey:(NSString*)key apiSecret:(NSString*)secret;

// Camera control. Use to start or stop camera when preview is visible or hidden, respectively.
- (void)startCamera;
- (void)stopCamera;

// Capture a single frame. The image is returned asynchronously through iqEngines:didCaptureStillFrame:
- (void)captureStillFrame;

// Perform an image recognition search on an image. Returns a query ID string. 
// On success, results are returned to the delegate asynchronously with the
// iqEngines:didCompleteSearch:withResults:forQID: messsage.
// iqEngines:failedWithError: is called on failure.
// Location information can be provided to enhance results using the location parameter.

- (NSString*)searchWithImage:(UIImage*)image;
- (NSString*)searchWithImage:(UIImage*)image atLocation:(CLLocationCoordinate2D)location;

// Retrieves results for a previous image search.
- (void)searchWithQID:(NSString*)qid;

// Called to update user modified results for a particular query ID.
- (void)updateResults:(NSDictionary*)results forQID:(NSString*)qid;

@end

// --------------------------------------------------------------------------------

// Dictionary keys for iqEngines:didCompleteSearch:withResults:forQID: results
extern NSString* const IQEKeyQID;
extern NSString* const IQEKeyQIDData;
extern NSString* const IQEKeyColor;
extern NSString* const IQEKeyISBN;
extern NSString* const IQEKeyLabels;
extern NSString* const IQEKeySKU;
extern NSString* const IQEKeyUPC;
extern NSString* const IQEKeyURL;
extern NSString* const IQEKeyQRCode;
extern NSString* const IQEKeyMeta;
extern NSString* const IQEKeyObjId;
extern NSString* const IQEKeyBoundingBox;

extern NSString* const IQEKeyObjectId;
extern NSString* const IQEKeyObjectName;
extern NSString* const IQEKeyObjectMeta;
extern NSString* const IQEKeyObjectImagePath;

extern NSString* const IQEKeyBarcodeData;
extern NSString* const IQEKeyBarcodeType;

// codeTypes for iqEngines:didDetectBarcode:codeType:
extern NSString* const IQEBarcodeTypeCODE39;
extern NSString* const IQEBarcodeTypeCODE93;
extern NSString* const IQEBarcodeTypeCODE128;
extern NSString* const IQEBarcodeTypeCOMPOSITE;
extern NSString* const IQEBarcodeTypeDATABAR;
extern NSString* const IQEBarcodeTypeDATABAR_EXP;
extern NSString* const IQEBarcodeTypeEAN2;
extern NSString* const IQEBarcodeTypeEAN5;
extern NSString* const IQEBarcodeTypeEAN8;
extern NSString* const IQEBarcodeTypeEAN13;
extern NSString* const IQEBarcodeTypeI25;
extern NSString* const IQEBarcodeTypeISBN10;
extern NSString* const IQEBarcodeTypeISBN13;
extern NSString* const IQEBarcodeTypePDF417;
extern NSString* const IQEBarcodeTypeQRCODE;
extern NSString* const IQEBarcodeTypeUPCA;
extern NSString* const IQEBarcodeTypeUPCE;
extern NSString* const IQEBarcodeTypeDATAMATRIX;

// --------------------------------------------------------------------------------
