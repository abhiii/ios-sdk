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

#import "IQEnginesXMLParserBase.h"

@interface IQEnginesXMLParserBase (Private)

//- (BOOL)parsingNode:(XMLNode *)node byName:(NSString *)name;

@end

@implementation IQEnginesXMLParserBase

@synthesize parsedData = mData;

- (id)initWithXMLData:(NSData*)xmlData
{
    self = [super init];
    if (self)
    {
        [self beforeParsing];
        mParsingStack = [NSMutableArray new];
        mObjectStack = [NSMutableArray new];
        mData = [NSMutableArray new];
        mCurrentLevel= mData;
        [mObjectStack addObject:mData];
        mElementStack = [NSMutableArray new];
        mCurrentString = [NSMutableString new];
        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:xmlData];
        [parser setDelegate:self];
        [parser parse];
        BOOL gotError = ([parser parserError] != nil);
        if (gotError || (![self afterParsing])) {
            [self release];
            NSLog(@"Parser = nil! Error: %@", [[parser parserError] description]);
            [parser release];
            return nil;
        }
        [parser release];
        
        mResult = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [mResult release];
    [mParsingStack release];
    [mCurrentString release];
    [mElementStack release];
    [mObjectStack release];
    [mData release];
    [super dealloc];
}

#pragma mark To be overridden in subclasses.

- (void)beforeParsing
{
}

- (BOOL)afterParsing
{
    return YES;
}

- (void)didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributes;
{

}

- (void)didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName
{

}

#pragma mark NSXMLParser delegate implementation and support

- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName attributes:(NSDictionary*)attributes
{
    [mElementStack addObject:elementName];
    [mCurrentString replaceCharactersInRange:NSMakeRange(0, [mCurrentString length]) withString:@""];
    [self didStartElement:elementName namespaceURI:namespaceURI qualifiedName:qualifiedName attributes:attributes];

    // Parsing xml to template structure
    NSMutableArray *lastLevel = mCurrentLevel;
    [mCurrentLevel addObject:[NSMutableDictionary dictionaryWithObject:@"" forKey:elementName]];
    mCurrentLevel = [NSMutableArray arrayWithCapacity:0];
    NSMutableDictionary *curItem = [lastLevel lastObject];
    [curItem setObject:mCurrentLevel forKey:[[curItem allKeys] lastObject]];
    [mObjectStack addObject:mCurrentLevel];    
    mLastObject = nil;
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qualifiedName
{
    NSAssert([[mElementStack lastObject] isEqualToString:elementName], @"Bad stack");
    [self didEndElement:elementName namespaceURI:namespaceURI qualifiedName:qualifiedName];
    [mElementStack removeLastObject];
    
    // Parsing xml to template structure
    if (mLastObject == nil) {
        NSMutableDictionary *curItem = [mCurrentLevel lastObject];
        if (curItem == nil) {
            curItem = [NSMutableDictionary dictionaryWithObject:@"" forKey:elementName];
            [mCurrentLevel addObject:curItem];
        }
        [curItem setObject:[self trimmedString] forKey:elementName];
        mLastObject = curItem;
    }
    
    [mObjectStack removeLastObject];
    mCurrentLevel = [mObjectStack lastObject];
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
    [mCurrentString appendString:string];
}

- (BOOL)xmlPathEndsWith:(NSString*)first, ...
{
    // Count arguments.
    NSUInteger count = 0;
    va_list ap1;
    va_start(ap1, first);
    NSString* x1 = first;
    while (x1) {
        count += 1;
        x1 = va_arg(ap1, NSString*);
    }
    va_end(ap1);
    if ([mElementStack count] < count) return NO;
    
    // Check path.
    NSUInteger index = [mElementStack count] - count;
    va_list ap2;
    va_start(ap2, first);
    NSString* x2 = first;
    while (x2) {
        if (![[mElementStack objectAtIndex:index] isEqualToString:x2]) return NO;
        index += 1;
        x2 = va_arg(ap2, NSString*);
    }
    va_end(ap2);
    
    return YES;
}

- (NSString*)trimmedString
{
    return [mCurrentString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)parser:(NSXMLParser *)parser foundNotationDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID {
    NSLog(@"foundNotationDeclarationWithName");
    NSLog(@"name: %@; publicID: %@; systemID: %@;", name, publicID, systemID);
}

- (void)parser:(NSXMLParser *)parser foundUnparsedEntityDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID notationName:(NSString *)notationName {
    NSLog(@"foundUnparsedEntityDeclarationWithName");
    NSLog(@"name: %@; publicID: %@; systemID: %@; notationName: %@;", name, publicID, systemID, notationName);
}

- (void)parser:(NSXMLParser *)parser foundAttributeDeclarationWithName:(NSString *)attributeName forElement:(NSString *)elementName type:(NSString *)type defaultValue:(NSString *)defaultValue {
    NSLog(@"foundAttributeDeclarationWithName");
    NSLog(@"attributeName: %@; elementName: %@; type: %@; defaultValue: %@;", attributeName, elementName, type, defaultValue);
}

- (void)parser:(NSXMLParser *)parser foundElementDeclarationWithName:(NSString *)elementName model:(NSString *)model {
    NSLog(@"foundElementDeclarationWithName");
    NSLog(@"elementName: %@; model: %@;", elementName, model);
}

- (void)parser:(NSXMLParser *)parser foundInternalEntityDeclarationWithName:(NSString *)name value:(NSString *)value {
    NSLog(@"foundInternalEntityDeclarationWithName");
    NSLog(@"name: %@; value: %@;", name, value);
}

- (void)parser:(NSXMLParser *)parser foundExternalEntityDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID {
    NSLog(@"foundExternalEntityDeclarationWithName");
    NSLog(@"name: %@; publicID: %@; systemID: %@;", name, publicID, systemID);
}


@end
