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
//  IQEnginesMisc.m
//
// --------------------------------------------------------------------------------

#import "IQEnginesMisc.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

@interface IQEnginesMisc ()
+ (NSString*) macAddress;
+ (NSString*) getSysInfoByName:(char *)typeSpecifier;
@end

// --------------------------------------------------------------------------------
#pragma mark -
// --------------------------------------------------------------------------------

@implementation IQEnginesMisc

+ (NSString*) sha1:(NSString*)str
{
    if (str == nil || str.length <= 0)
        return nil;
    
    const char* cStr = [str UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(cStr, strlen(cStr), result);
    
    NSMutableString * strTemp = [[NSMutableString alloc] initWithCapacity: CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [strTemp appendFormat: @"%02x", result[i]];
    
    NSString* output = [strTemp copy];
    [strTemp release];
    
    return [output autorelease];
}

+ (NSString*) uniqueDeviceIdentifier
{
    NSString* macAddress = [self macAddress];
    NSString* identifier = [self sha1:macAddress];
    
    return identifier;
}

+ (NSString*) platform
{
    return [self getSysInfoByName:"hw.machine"];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private methods
// --------------------------------------------------------------------------------

+ (NSString*)macAddress
{    
    int    mib[6];
    size_t len;
    char*  buf;
    
    // Setup the management Information Base (mib)
    mib[0] = CTL_NET;       // Network subsystem
    mib[1] = AF_ROUTE;      // Routing table
    mib[2] = 0;
    mib[3] = AF_LINK;       // Link layer information
    mib[4] = NET_RT_IFLIST; // Request all configured interfaces
    
    mib[5] = if_nametoindex("en0");
    if (mib[5] == 0)
    {
        NSLog(@"Error: if_nametoindex error");
        return nil;
    }
    
    // Get the size of the data available
    if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
    {
        NSLog(@"Error: sysctl: errno:%d", errno);
        return nil;
    }
    
    buf = malloc(len);
    if (buf == NULL)
    {
        NSLog(@"Error: Could not allocate memory");
        return nil;
    }
    
    // Get system information, store in buf
    if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
    {
        NSLog(@"Error: sysctl: errno:%d", errno);
        free(buf);
        return nil;
    }
    
    struct if_msghdr*   ifm = (struct if_msghdr *)buf;
    struct sockaddr_dl* sdl = (struct sockaddr_dl *)(ifm + 1);
    unsigned char*      ptr = (unsigned char *)LLADDR(sdl);
    
    NSString* outstring = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                           *ptr, *(ptr + 1), *(ptr + 2), *(ptr + 3), *(ptr + 4), *(ptr + 5)];
    free(buf);
    
    return outstring;
}

+ (NSString*) getSysInfoByName:(char *)name
{
    int result = 0;
    size_t len = 0;
    
    result = sysctlbyname(name, NULL, &len, NULL, 0);
    if (result != 0)
    {
        NSLog(@"Error: sysctlbyname: errno:%d", errno);
        return nil;
    }
    
    char* buf = malloc(len);
    if (buf == NULL)
    {
        NSLog(@"Error: Could not allocate memory");
        return nil;
    }
    
    result = sysctlbyname(name, buf, &len, NULL, 0);
    if (result != 0)
    {
        NSLog(@"Error: sysctlbyname: errno:%d", errno);
        free(buf);
        return nil;
    }
    
    NSString* outstring = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
    
    free(buf);
    
    return outstring;
}

@end

// --------------------------------------------------------------------------------
