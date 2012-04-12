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
#import "IQEnginesAPI.h"
#import "IQEnginesTags.h"

/*

<?xml version="1.0" ?>
<data>
    <results>
        <qid_data>
            <color>Mostly black white, with some gray.</color>
            <labels>starbucks</labels>
            <bbox>0</bbox>
            <bbox>21</bbox>
            <bbox>232</bbox>
            <bbox>147</bbox>
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
    [mResults     release];
    [mComment     release];
    [mBoundingBox release];
    
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
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, nil])
    {
        mResultItem = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, nil])
    {
        mQIDDataItem = [[NSMutableDictionary alloc] initWithCapacity:0];
        mBoundingBox = [[NSMutableArray      alloc] initWithCapacity:0];
    }
}

- (void)didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName
{
    if ([self xmlPathEndsWith:IQETagData, nil])
        self.found = YES;
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagError, nil])
        self.errorCode = [[self trimmedString] intValue];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagComment, nil])
        self.comment = [self trimmedString];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, nil])
    {
        [mResults addObject:mResultItem];
        
        [mResultItem release];
        mResultItem = nil;
    }
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQID, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeyQID];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, nil])
    {
        if (mBoundingBox.count > 0)
            [mQIDDataItem setObject:mBoundingBox forKey:IQEnginesKeyBoundingBox];
        [mBoundingBox release];
        mBoundingBox = nil;
        
        [mResultItem setObject:mQIDDataItem forKey:IQETagQIDData];
        
        [mQIDDataItem release];
        mQIDDataItem = nil;
    }
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagColor, nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:IQEnginesKeyColor];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagISBN, nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:IQEnginesKeyISBN];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagLabels, nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:IQEnginesKeyLabels];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagSKU, nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:IQEnginesKeySKU];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagUPC, nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:IQEnginesKeyUPC];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagURL, nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:IQEnginesKeyURL];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagQRCode, nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:IQEnginesKeyQRCode];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagMeta, nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:IQEnginesKeyMeta];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagObjId, nil])
        [mQIDDataItem setObject:[self trimmedString] forKey:IQEnginesKeyObjId];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQIDData, IQETagBBox, nil])
        [mBoundingBox addObject:[self trimmedString]];
}

@end
