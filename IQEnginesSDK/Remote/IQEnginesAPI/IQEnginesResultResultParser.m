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

*/

@implementation IQEnginesResultResultParser

@synthesize errorCode    = mErrorCode;
@synthesize found        = mFound;
@synthesize comment      = mComment;
@synthesize results      = mResults;

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
}

- (void)didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributes;
{
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, nil])
    {
        mResults     = [[NSMutableDictionary alloc] initWithCapacity:0];
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
            [mResults setObject:mBoundingBox forKey:IQEnginesKeyBoundingBox];
        [mBoundingBox release];
        mBoundingBox = nil;
    }
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagColor, nil])
        [mResults setObject:[self trimmedString] forKey:IQEnginesKeyColor];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagISBN, nil])
        [mResults setObject:[self trimmedString] forKey:IQEnginesKeyISBN];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagLabels, nil])
        [mResults setObject:[self trimmedString] forKey:IQEnginesKeyLabels];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagSKU, nil])
        [mResults setObject:[self trimmedString] forKey:IQEnginesKeySKU];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagUPC, nil])
        [mResults setObject:[self trimmedString] forKey:IQEnginesKeyUPC];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagURL, nil])
        [mResults setObject:[self trimmedString] forKey:IQEnginesKeyURL];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagQRCode, nil])
        [mResults setObject:[self trimmedString] forKey:IQEnginesKeyQRCode];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagMeta, nil])
        [mResults setObject:[self trimmedString] forKey:IQEnginesKeyMeta];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagObjId, nil])
        [mResults setObject:[self trimmedString] forKey:IQEnginesKeyObjId];
    else
    if ([self xmlPathEndsWith:IQETagData, IQETagResults, IQETagBBox, nil])
        [mBoundingBox addObject:[self trimmedString]];
}

@end
