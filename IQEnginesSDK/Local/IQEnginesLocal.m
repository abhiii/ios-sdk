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
//  IQEnginesLocal.m
//
//  The purpose of this file is to provide an IQEnginesLocal implementation
//  when libIQEnginesLocal.a is not present in the project.
//
// --------------------------------------------------------------------------------

#import "IQEnginesLocal.h"
#import "IQEnginesMisc.h"
#import "IQEConfig.h"

#if IQENGINES_LOCAL_LIB == FALSE

NSString* const IQEnginesLocalKeyObjectId        = @"objectId";
NSString* const IQEnginesLocalKeyObjectName      = @"objectName";
NSString* const IQEnginesLocalKeyObjectMeta      = @"objectMeta";
NSString* const IQEnginesLocalKeyObjectImagePath = @"objectImagePath";
NSString* const IQEnginesLocalKeyBarcodeData     = @"barcodeData";
NSString* const IQEnginesLocalKeyBarcodeType     = @"barcodeType";

NSString* const IQEnginesLocalBarcodeCODE39      = @"CODE-39";
NSString* const IQEnginesLocalBarcodeCODE93      = @"CODE-93";
NSString* const IQEnginesLocalBarcodeCODE128     = @"CODE-128";
NSString* const IQEnginesLocalBarcodeCOMPOSITE   = @"COMPOSITE";
NSString* const IQEnginesLocalBarcodeDATABAR     = @"DataBar";
NSString* const IQEnginesLocalBarcodeDATABAR_EXP = @"DataBar-Exp";
NSString* const IQEnginesLocalBarcodeEAN2        = @"EAN-2";
NSString* const IQEnginesLocalBarcodeEAN5        = @"EAN-5";
NSString* const IQEnginesLocalBarcodeEAN8        = @"EAN-8";
NSString* const IQEnginesLocalBarcodeEAN13       = @"EAN-13";
NSString* const IQEnginesLocalBarcodeISBN10      = @"ISBN-10";
NSString* const IQEnginesLocalBarcodeISBN13      = @"ISBN-13";
NSString* const IQEnginesLocalBarcodeI25         = @"I2/5";
NSString* const IQEnginesLocalBarcodePDF417      = @"PDF417";
NSString* const IQEnginesLocalBarcodeQRCODE      = @"QR-Code";
NSString* const IQEnginesLocalBarcodeUPCE        = @"UPC-E";
NSString* const IQEnginesLocalBarcodeUPCA        = @"UPC-A";
NSString* const IQEnginesLocalBarcodeDATAMATRIX  = @"DataMatrix";

// --------------------------------------------------------------------------------
#pragma mark -
// --------------------------------------------------------------------------------

@implementation IQEnginesLocal

@synthesize delegate = mDelegate;

- (id)init
{
    return [self initWithParameters:IQEnginesLocalSearchTypeAll dataPath:nil];
}

- (id)initWithParameters:(IQEnginesLocalSearchType)searchType dataPath:(NSString*)path
{
    self = [super init];
    if (self)
    {
        mSearchType = searchType;
    }
    return self;
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEnginesLocal
// --------------------------------------------------------------------------------

+ (NSString*)uniqueQueryID
{
    NSString* qid = nil;
    
    CFUUIDRef   uuid    = CFUUIDCreate(NULL);
    CFStringRef uuidStr = CFUUIDCreateString(NULL, uuid);
    
    qid = [IQEnginesMisc sha1:(NSString*)uuidStr];
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return qid;
}

- (void)searchWithImage:(UIImage*)image qid:(NSString*)qid
{
    if ([mDelegate respondsToSelector:@selector(iqEnginesLocal:didCompleteSearch:withResults:forQID:)])
    {
        if (mSearchType & IQEnginesLocalSearchTypeBarCode)
        {
            [mDelegate iqEnginesLocal:self
                    didCompleteSearch:IQEnginesLocalSearchTypeBarCode
                          withResults:nil
                               forQID:qid];
        }

        if (mSearchType & IQEnginesLocalSearchTypeObjectSearch)
        {
            [mDelegate iqEnginesLocal:self
                    didCompleteSearch:IQEnginesLocalSearchTypeObjectSearch
                          withResults:nil
                               forQID:qid];
        }
    }
}

- (NSInteger)searchWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    return 0;
}

@end

// --------------------------------------------------------------------------------

#endif
