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

#import "IQEnginesRequestHandler.h"
#import "IQEnginesUtils.h"

#define NETWORK_TIMEOUT  30
#define API_TIMEOUT      60

#define KEY_TIME_STAMP   @"time_stamp"
#define KEY_API_SIG      @"api_sig"
#define KEY_API_IMG      @"img"

static NSString* PostBoundary = @"0xKhTmLbOuNdArY";

static NSInteger SortKeyByName(id item1, id item2, void* context)
{
    NSString* string1 = item1;
    NSString* string2 = item2;
    
    return [string1 compare:string2 options:NSCaseInsensitiveSearch | NSLiteralSearch];
}

@interface IQEnginesRequestHandler (Private)
- (NSData*) generateFormData:(NSDictionary*)variables;
- (void)    checkAPIReturn;
@end

@implementation IQEnginesRequestHandler

@synthesize delegate            = mDelegate;
@synthesize url                 = mRequestURL;
@synthesize secret              = mSecret;
@synthesize arguments           = mArguments;
@synthesize additionalArguments = mAdditionalArguments;
@synthesize timeout             = mTimeOut;
@synthesize connection          = mConnection;
@synthesize connectionData      = mConnectionData;
@synthesize userData            = mUserData;
@synthesize signature           = mSignature;
@synthesize statusCode          = mStatusCode;

- (id)init 
{
    self = [super init];
    if (self)
    {
        mTimeOut    = NETWORK_TIMEOUT;
        mStatusCode = 0;
    }
    
    return self;    
}

- (void)dealloc
{
    //NSLog(@"%s", __func__);
    
    [self closeConnection];
    
    [mRequestURL          release];
    [mArguments           release];
    [mAdditionalArguments release];
    [mUserData            release];
    [mSignature           release];
    [mSecret              release];
    
    [super dealloc];
}

- (NSString*)startRequest
{    
    NSString* time_stamp = [IQEnginesUtils getCurrentTimeString];

    NSURL*               url     = [NSURL URLWithString:mRequestURL];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:url
                                                                cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                            timeoutInterval:mTimeOut];
    [request setHTTPMethod:@"POST"];
    
    NSString* contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", PostBoundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];    
    
    //
    // Calculate signature using arguments.
    //
    
    NSMutableDictionary* arguments = [NSMutableDictionary dictionaryWithDictionary:mArguments];
    
    [arguments setObject:time_stamp forKey:KEY_TIME_STAMP];

    if (mUserData != nil)
        [arguments setObject:mUserData forKey:KEY_API_IMG];

    NSArray*         keys        = [arguments allKeys];
    NSArray*         sorted_keys = [keys sortedArrayUsingFunction:SortKeyByName context:nil];
    NSMutableString* sig_content = [NSMutableString stringWithCapacity:0];
    
    for (NSString* key in sorted_keys)
    {
        NSString* val = [arguments objectForKey:key];
        [sig_content appendFormat:@"%@%@", key, val];
    }
    
    NSString* api_sig = [IQEnginesUtils hmac:mSecret data:sig_content];
    self.signature = api_sig;
    
    //
    // Fields. Arguments + signature + additional arguments.
    //
    
    NSMutableDictionary* fields = [NSMutableDictionary dictionaryWithDictionary:mArguments];
    
    [fields setObject:time_stamp forKey:KEY_TIME_STAMP];
    [fields setObject:api_sig    forKey:KEY_API_SIG];
    
    [fields setValuesForKeysWithDictionary:mAdditionalArguments];

    /*
    NSLog(@"fields: %@", fields);
    NSLog(@"raw data: %@", sig_content);
    NSLog(@"api_sig: %@", api_sig);
    */

    NSData* postData = [self generateFormData:fields];
    [request setHTTPBody:postData];
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    [request release];
    
    return api_sig;
}

- (void)closeConnection
{
    [mConnection cancel];
    
    [mConnectionData release];
    mConnectionData = nil;
    
    [mConnection release];
    mConnection = nil;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"{\n\
    url = \"%@\";\n\
    signature = \"%@\";\n\
}",
    mRequestURL,
    mSignature];
}

#pragma mark Private methods implementation

- (NSData*)generateFormData:(NSDictionary*)variables
{
    NSMutableData* result = [[NSMutableData new] autorelease];    
    for (NSString* key in variables)
    {
        id value = [variables valueForKey:key];
        [result appendData:[[NSString stringWithFormat:@"--%@\r\n", PostBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        if ([value isKindOfClass:[NSString class]])
        {
            [result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [result appendData:[[NSString stringWithFormat:@"%@",value] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        else
        if ([value isKindOfClass:[NSData class]])
        {
            [result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", key, mUserData] dataUsingEncoding:NSUTF8StringEncoding]];
            [result appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
            [result appendData:value];
        }
        [result appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [result appendData:[[NSString stringWithFormat:@"--%@--\r\n", PostBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return result;
}

#pragma mark NSURLConnection delegate implementation

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    [mConnectionData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    NSData* xmlData = [[mConnectionData retain] autorelease];
    [self closeConnection];
    [mDelegate request:self responseCompleteWithData:xmlData];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    [mDelegate request:self responseFailedWithError:error];
    [self closeConnection];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // Get HTTP response code for this request.
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
        mStatusCode = [httpResponse statusCode];
    }
    
    self.connectionData = [NSMutableData dataWithLength:0];
}

@end
