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

#import "IQEnginesResultResultParser.h"

/*

<?xml version="1.0" ?>
<data>
    <results>
        <color>Mostly black white, with some gray.</color>
        <labels>starbucks</labels>
        <meta>http://www.starbucks.com</meta>
    </results>
    <error>0</error>
</data>
 
<?xml version="1.0" ?>
<data>
    <comment>The results for qid QID are not available yet</color>
    <error>0</error>
</data>
 
 
<?xml version="1.0" ?>
<data>
    <comment>Authentication failed</comment>
    <error>1</error>
</data>
 
*/

@implementation IQEnginesResultResultParser

@synthesize errorCode    = mErrorCode;
@synthesize found        = mFound;
@synthesize comment      = mComment;
@synthesize results      = mResults;

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
}

- (void)didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributes;
{
    if ([self xmlPathEndsWith:@"data", @"results", nil])
        mResults = [[NSMutableDictionary alloc] initWithCapacity:0];
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
    if ([self xmlPathEndsWith:@"data", @"results", @"color", nil])
        [mResults setObject:[self trimmedString] forKey:@"color"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"isbn", nil])
        [mResults setObject:[self trimmedString] forKey:@"isbn"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"labels", nil])
        [mResults setObject:[self trimmedString] forKey:@"labels"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"sku", nil])
        [mResults setObject:[self trimmedString] forKey:@"sku"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"upc", nil])
        [mResults setObject:[self trimmedString] forKey:@"upc"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"url", nil])
        [mResults setObject:[self trimmedString] forKey:@"url"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"qrcode", nil])
        [mResults setObject:[self trimmedString] forKey:@"qrcode"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"meta", nil])
        [mResults setObject:[self trimmedString] forKey:@"meta"];
    else
    if ([self xmlPathEndsWith:@"data", @"results", @"obj_id", nil])
        [mResults setObject:[self trimmedString] forKey:@"obj_id"];
}

@end
