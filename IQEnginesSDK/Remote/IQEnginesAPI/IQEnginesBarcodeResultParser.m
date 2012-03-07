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

#import "IQEnginesBarcodeResultParser.h"

/*
 
<?xml version="1.0" ?>
<data>
    <results />
    <error>0</error>
</data>

<?xml version="1.0" ?>
<data>
    <results>None</results>
<error>0</error>
</data>
 
<?xml version="1.0" ?>
<data>
    <results>Mrs. Meyer's Counter Top Spray, Lemon Verbena, 16 fl oz</results>
    <error>0</error>
</data>
 
<?xml version="1.0" ?>
<data>
    <comment>Unknown user: sduvgsiudv</comment>
    <error>1</error>
</data>
*/

@implementation IQEnginesBarcodeResultParser

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
        self.results = [self trimmedString];
}

@end
