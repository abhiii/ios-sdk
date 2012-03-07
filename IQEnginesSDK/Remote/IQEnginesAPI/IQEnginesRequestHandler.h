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

@class IQEnginesRequestHandler;

@protocol IQEnginesRequestHandlerDelegate
- (void)request:(IQEnginesRequestHandler *)request responseCompleteWithData:(NSData *)xmldata;
- (void)request:(IQEnginesRequestHandler *)request responseFailedWithError:(NSError *)error;
@end

@interface IQEnginesRequestHandler : NSObject
{
    id<IQEnginesRequestHandlerDelegate> mDelegate;
    NSDictionary*    mArguments;
    NSDictionary*    mAdditionalArguments;
    NSString*        mRequestURL;
    NSUInteger       mTimeOut;
    NSURLConnection* mConnection;
    NSMutableData*   mConnectionData;
    id               mUserData;
    NSString*        mSecret;
    NSString*        mSignature;
    NSInteger        mStatusCode;
}

@property(nonatomic, assign) id<IQEnginesRequestHandlerDelegate> delegate;
@property(nonatomic, retain) NSString*        secret;
@property(nonatomic, retain) NSString*        url;
@property(nonatomic, retain) NSDictionary*    arguments;            // arguments will be calculated within api_sig
@property(nonatomic, retain) NSDictionary*    additionalArguments;  // arguments will be calculated without api_sig
@property(nonatomic, assign) NSUInteger       timeout;
@property(nonatomic, retain) NSURLConnection* connection;
@property(nonatomic, retain) NSMutableData*   connectionData;
@property(nonatomic, retain) id               userData;
@property(nonatomic, copy)   NSString*        signature;
@property(nonatomic, assign) NSInteger        statusCode;

- (NSString*)startRequest;
- (void)     closeConnection;

@end
