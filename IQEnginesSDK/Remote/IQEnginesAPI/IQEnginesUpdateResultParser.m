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

#import "IQEnginesUpdateResultParser.h"

/*

<?xml version="1.0" ?>
<data>
    <results>
        <qid_data>
            <color>Mostly black white, with some gray.</color>
            <labels>starbucks</labels>
        </qid_data>
        <qid>c840c66245eae70df429fbbbc3c1e9b3ae40a64f</qid>
        <meta>http://www.starbucks.com</meta>
    </results>
    <results>
        <qid_data>
            <color>Mostly black white, with some gray.</color>
            <labels>starbucks</labels>
        </qid_data>
        <qid>c10b823e6f1c187869283715d0c718d20a065a9c</qid>
        <meta>http://www.starbucks.com</meta>
    </results>
    <results>
        <qid_data>
            <color>Mostly black white, with some gray.</color>
            <labels>starbucks</labels>
        </qid_data>
        <qid>15d0c718d20a065a9cc10b823e6f1c1878692837</qid>
        <meta>http://www.starbucks.com</meta>
    </results>
    <error>0</error>
</data>

*/

@implementation IQEnginesUpdateResultParser

@synthesize errorCode = mErrorCode;
@synthesize found     = mFound;
@synthesize comment   = mComment;
@synthesize results   = mResults;

- (void)dealloc
{
    [mResults release];
    [mComment release];
    
    [super dealloc];
}

- (void)beforeParsing
{
    self.found     = NO;
    self.errorCode = 1;
    
    mResults = [[NSMutableArray alloc] initWithCapacity:0];
}

- (void)didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributes;
{
    if ([self xmlPathEndsWith:@"data", @"results", nil])
        mResultItem = [[NSMutableDictionary alloc] initWithCapacity:0];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", nil])
        mQIDDataItem = [[NSMutableDictionary alloc] initWithCapacity:0];
}

- (void)didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName
{
    if ([self xmlPathEndsWith:@"data", nil])
        self.found = YES;
    else
    if ([self xmlPathEndsWith:@"data", @"error", nil])
        self.errorCode = [[self trimmedString] intValue];
    else
    if ([self xmlPathEndsWith:@"data", @"comment", nil])
        self.comment = [self trimmedString];
    else
    if ([self xmlPathEndsWith:@"data", @"results", nil])
    {
        [mResults addObject:mResultItem];
        
        [mResultItem release];
        mResultItem = nil;
    }
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid", nil])
        [mResultItem setObject:[self trimmedString] forKey:@"qid"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", nil])
    {
        [mResultItem setObject:mQIDDataItem forKey:@"qid_data"];
        
        [mQIDDataItem release];
        mQIDDataItem = nil;
    }
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", @"color", nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:@"color"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", @"isbn", nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:@"isbn"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", @"labels", nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:@"labels"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", @"sku", nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:@"sku"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", @"upc", nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:@"upc"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", @"url", nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:@"url"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", @"qrcode", nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:@"qrcode"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", @"meta", nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:@"meta"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qid_data", @"obj_id", nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:@"obj_id"];
}

@end
