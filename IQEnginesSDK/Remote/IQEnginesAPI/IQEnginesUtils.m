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

#import "IQEnginesUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation IQEnginesUtils

+ (NSString*) hmac:(NSString*)secret data:(NSString*)str
{
    const char* cStr       = [str    UTF8String];
    const char* cStrSecret = [secret UTF8String];
    unsigned char mac[CC_SHA1_DIGEST_LENGTH];
    
    // Stateless, one-shot HMAC function.
    CCHmac(kCCHmacAlgSHA1, cStrSecret, strlen(cStrSecret), cStr, strlen(cStr), mac);
    
    // Convert in to string.
    NSMutableString* strTemp = [[NSMutableString alloc] initWithCapacity: CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [strTemp appendFormat: @"%02x", mac[i]];

    NSString* output = [strTemp copy];
    [strTemp release];
    
    return [output autorelease];
}

+ (NSString*) sha1:(NSString*)str
{
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

+ (NSString*) getCurrentTimeString
{
    char time_string[260] = {0};
    
    long current_time = time(0);
    strftime(time_string, 14, "%Y%m%d%H%M%S", gmtime(&current_time));
    NSString* time = [NSString stringWithCString:time_string encoding:NSASCIIStringEncoding];

    return time;
}

+ (UIImage*)scaleImage:(UIImage*)image maxDimension1:(NSUInteger)maxDimension1 maxDimension2:(NSUInteger)maxDimension2
{
    CGSize inputSize = image.size;
    
    // Determine max size.
    NSUInteger biggerMaxDimension  = (maxDimension1 > maxDimension2) ? maxDimension1 : maxDimension2;
    NSUInteger smallerMaxDimension = (maxDimension1 > maxDimension2) ? maxDimension2 : maxDimension1;
    
    CGSize maxSize;
    if (inputSize.width > inputSize.height)
        maxSize = CGSizeMake(biggerMaxDimension, smallerMaxDimension);
    else
        maxSize = CGSizeMake(smallerMaxDimension, biggerMaxDimension);
    
    // Determine final size.
    CGSize finalSize = inputSize;
    if ((finalSize.width > maxSize.width) || (finalSize.height > maxSize.height))
    {
        if (finalSize.width > maxSize.width)
        {
            CGSize oldSize   = finalSize;
            finalSize.width  = maxSize.width;
            finalSize.height = (finalSize.width * oldSize.height) / oldSize.width;
        }
        
        if (finalSize.height > maxSize.height)
        {
            CGSize oldSize   = finalSize;
            finalSize.height = maxSize.height;
            finalSize.width  = (finalSize.height * oldSize.width) / oldSize.height;
        }
        
        finalSize.width  = ceilf(finalSize.width);
        finalSize.height = ceilf(finalSize.height);
    }
    
    // Make scaled image.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)finalSize.width,
                                                 (size_t)finalSize.height,
                                                 8,
                                                 4 * ((size_t)finalSize.width),
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    CGRect outputRect = CGRectZero;
    outputRect.size   = finalSize;
    
    CGContextDrawImage(context, outputRect, [image CGImage]);
    
    CGImageRef outputCGImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage* output = [UIImage imageWithCGImage:outputCGImage];
    CGImageRelease(outputCGImage);
    
    return output;
}

+ (UIImage*)fixImageRotation:(UIImage*)image
{
    CGImageRef cgImage      = [image CGImage];
    CGFloat    width        = CGImageGetWidth(cgImage);
    CGFloat    height       = CGImageGetHeight(cgImage);
    CGRect     bounds       = CGRectMake(0, 0, width, height);
    CGSize     imageSize    = CGSizeMake(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
    CGFloat    boundsHeight = 0.0;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    UIImageOrientation orientation = image.imageOrientation;
    switch (orientation)
    {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, (float)M_PI);
            break;
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundsHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width  = boundsHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0f * (float)M_PI / 2.0f);
            break;
        case UIImageOrientationLeft: //EXIF = 6
            boundsHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width  = boundsHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0f * (float)M_PI / 2.0f);
            break;
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundsHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width  = boundsHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, (float)M_PI / 2.0f);
            break;
        case UIImageOrientationRight: //EXIF = 8
            boundsHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width  = boundsHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, (float)M_PI / 2.0f);
            break;
        default:
            NSLog(@"Unknown orientation: %d", orientation);
            return image;
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (orientation == UIImageOrientationRight || orientation == UIImageOrientationLeft)
    {
        CGContextScaleCTM(context, -1.0, 1.0);
        CGContextTranslateCTM(context, -height, 0);
    }
    else 
    {
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), cgImage);
    
    UIImage* fixedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return fixedImage;
}

+ (NSString*) urlEncodeValue:(NSString*)strValue
{
    NSString* encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                  (CFStringRef)strValue,
                                                                                  NULL,
                                                                                  (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                  kCFStringEncodingUTF8);
    return [encodedString autorelease];    
}

@end
