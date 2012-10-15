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
#import "IQEnginesAPI.h"
#import "IQEnginesTags.h"

/*

<?xml version="1.0" ?>
<data>
    <results>
        <color>Mostly black white, with some gray.</color>
        <labels>starbucks</labels>
        <meta>http://www.starbucks.com</meta>
        <bbox>29</bbox>
        <bbox>24</bbox>
        <bbox>259</bbox>
        <bbox>283</bbox>
        <obj_id>076440e8e2cf48aea6fa265dcca1f2e2</obj_id>
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

<?xml version="1.0" ?>
<data>
    <comment>There is no query with qid 0123</comment>
    <results>
        <labels>Query Error (101)</labels>
    </results>
    <error>1</error>
</data>

multiple_results
 
<?xml version="1.0" ?>
<data>
    <results>
        <labels>Starbucks</labels>
        <meta>{}</meta>
        <bbox>14</bbox><bbox>72</bbox><bbox>260</bbox><bbox>256</bbox>
        <obj_id>8f1f9a16990746378c57d9a47f5048fd</obj_id>
    </results>
    <results>
        <labels>Starbucks Coffee</labels>
        <meta>{}</meta>
        <bbox>37</bbox><bbox>72</bbox><bbox>213</bbox><bbox>219</bbox>
        <obj_id>79301fce20c0475db46a6b22186a9199</obj_id>
    </results>
    ...
    <error>0</error>
</data>

*/

@implementation IQEnginesResultResultParser

@synthesize found     = mFound;
@synthesize errorCode = mErrorCode;
@synthesize comment   = mComment;
@synthesize results   = mResults;

- (id)initWithXMLData:(NSData*)xmlData
{
    self = [super initWithXMLData:xmlData];
    if (self)
    {
        mResultItem  = nil;
        mBoundingBox = nil;
    }
    return self;
}

- (void)dealloc
{
    [mResults release];
    [mComment release];
    
    [mResultItem  release];
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
        mResultItem  = [[NSMutableDictionary alloc] initWithCapacity:0];
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
        if (mBoundingBox.count > 0)
            [mResultItem setObject:mBoundingBox forKey:IQEnginesKeyBoundingBox];
        [mBoundingBox release]; mBoundingBox = nil;
        
        [mResults addObject:mResultItem];
        [mResultItem release]; mResultItem = nil;
    }
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagColor, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeyColor];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagISBN, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeyISBN];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagLabels, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeyLabels];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagSKU, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeySKU];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagUPC, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeyUPC];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagURL, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeyURL];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQRCode, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeyQRCode];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagMeta, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeyMeta];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagObjId, nil])
        [mResultItem setObject:[self trimmedString] forKey:IQEnginesKeyObjId];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagBBox, nil])
        [mBoundingBox addObject:[self trimmedString]];
}

@end
