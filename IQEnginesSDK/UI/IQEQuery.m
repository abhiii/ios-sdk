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
//  IQEQuery.m
//
// --------------------------------------------------------------------------------

#import "IQEQuery.h"
#import "IQE.h"

#define QUERY_KEY_TYPE              @"type"
#define QUERY_KEY_STATE             @"state"
#define QUERY_KEY_IMAGEFILE         @"imageFile"
#define QUERY_KEY_THUMBFILE         @"thumbFile"

#define QUERY_KEY_QID               @"qid"
#define QUERY_KEY_QIDDATA           @"qidData"
#define QUERY_KEY_QIDRESULTS        @"qidResults"

#define QUERY_KEY_OBJID             @"objId"
#define QUERY_KEY_OBJNAME           @"objName"
#define QUERY_KEY_OBJMETA           @"objMeta"

#define QUERY_KEY_CODEDATA          @"codeData"
#define QUERY_KEY_CODETYPE          @"codeType"
#define QUERY_KEY_CODEDESC          @"codeDescription"

#define QUERY_TYPE_UNKNOWN          @"unknown"
#define QUERY_TYPE_REMOTE           @"remote"
#define QUERY_TYPE_LOCAL            @"local"
#define QUERY_TYPE_BARCODE          @"barcode"

#define QUERY_STATE_UNKNOWN         @"unknown"
#define QUERY_STATE_UPLOADING       @"uploading"
#define QUERY_STATE_SEARCHING       @"searching"
#define QUERY_STATE_FOUND           @"found"
#define QUERY_STATE_NOTFOUND        @"notfound"
#define QUERY_STATE_NOTREADY        @"notready"
#define QUERY_STATE_NETWORK_PROBLEM @"networkproblem"
#define QUERY_STATE_TIMEOUT_PROBLEM @"timeoutproblem"

#define BUNDLE_TABLE @"IQE"

NSString* const IQEQueryTitleChangeNotification = @"IQEQueryTitleChangeNotification";
NSString* const IQEQueryStateChangeNotification = @"IQEQueryStateChangeNotification";

@interface IQEQuery ()
@property(nonatomic, retain) NSMutableDictionary* mStates;
- (NSString*)     stringFromState:(IQEQueryState)aState;
- (NSString*)     stringFromType:(IQEQueryType)aType;
- (IQEQueryState) stateFromString:(NSString*)aString;
- (IQEQueryType)  typeFromString:(NSString*)aString;
+ (NSArray*)      removeDuplicates:(NSArray*)inArray;
@end

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEQuery implementation
// --------------------------------------------------------------------------------

@implementation IQEQuery

@synthesize mStates;
@synthesize type;
@synthesize state;
@synthesize imageFile;
@synthesize thumbFile;
@synthesize qid;
@synthesize qidData;
@synthesize qidResults;
@synthesize objId;
@synthesize objName;
@synthesize objMeta;
@synthesize codeData;
@synthesize codeType;
@synthesize codeDesc;

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEQuery lifecycle
// --------------------------------------------------------------------------------

- (id) init
{
    self = [super init];
    if (self)
    {
        type  = IQEQueryTypeUnknown;
        state = IQEQueryStateUnknown;
        
        self.mStates = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return self;
}

- (id) initWithDictionary:(NSDictionary*)dict
{
    self = [self init];
    if (self)
    {
        NSString* strType   = [dict objectForKey:QUERY_KEY_TYPE];
        NSString* strStatus = [dict objectForKey:QUERY_KEY_STATE];
        
        type            = [self typeFromString:strType];
        state           = [self stateFromString:strStatus];
                
        self.imageFile  = [dict objectForKey:QUERY_KEY_IMAGEFILE];
        self.thumbFile  = [dict objectForKey:QUERY_KEY_THUMBFILE];

        self.qid        = [dict objectForKey:QUERY_KEY_QID];
        self.qidData    = [dict objectForKey:QUERY_KEY_QIDDATA];
        self.qidResults = [dict objectForKey:QUERY_KEY_QIDRESULTS];
        
        self.objId      = [dict objectForKey:QUERY_KEY_OBJID];
        self.objName    = [dict objectForKey:QUERY_KEY_OBJNAME];
        self.objMeta    = [dict objectForKey:QUERY_KEY_OBJMETA];
        
        self.codeData   = [dict objectForKey:QUERY_KEY_CODEDATA];
        self.codeType   = [dict objectForKey:QUERY_KEY_CODETYPE];
        self.codeDesc   = [dict objectForKey:QUERY_KEY_CODEDESC];
    }
    return self;
}

- (void) encodeWithDictionary:(NSMutableDictionary*)dictionary
{
    [dictionary setObject:[self stringFromType:type]   forKey:QUERY_KEY_TYPE];
    [dictionary setObject:[self stringFromState:state] forKey:QUERY_KEY_STATE];
        
    if (imageFile)   [dictionary setObject:imageFile   forKey:QUERY_KEY_IMAGEFILE];
    if (thumbFile)   [dictionary setObject:thumbFile   forKey:QUERY_KEY_THUMBFILE];
    
    if (qid)         [dictionary setObject:qid         forKey:QUERY_KEY_QID];
    if (qidData)     [dictionary setObject:qidData     forKey:QUERY_KEY_QIDDATA];
    if (qidResults)  [dictionary setObject:qidResults  forKey:QUERY_KEY_QIDRESULTS];

    if (objId)       [dictionary setObject:objId       forKey:QUERY_KEY_OBJID];
    if (objName)     [dictionary setObject:objName     forKey:QUERY_KEY_OBJNAME];
    if (objMeta)     [dictionary setObject:objMeta     forKey:QUERY_KEY_OBJMETA];

    if (codeData)    [dictionary setObject:codeData    forKey:QUERY_KEY_CODEDATA];
    if (codeType)    [dictionary setObject:codeType    forKey:QUERY_KEY_CODETYPE];
    if (codeDesc)    [dictionary setObject:codeDesc    forKey:QUERY_KEY_CODEDESC];
}

- (void) dealloc
{
    [imageFile  release];
    [thumbFile  release];
    
    [qid        release];
    [qidData    release];
    [qidResults release];
    
    [objId      release];
    [objName    release];
    [objMeta    release];
    
    [codeData   release];
    [codeType   release];
    [codeDesc   release];
    
    [mStates    release];
    
    [super dealloc];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEQuery Public methods
// --------------------------------------------------------------------------------

- (BOOL) isEqualToQuery:(IQEQuery*)query
{
    if (query == self)
        return YES;
    
    if (type == IQEQueryTypeRemoteObject
    ||  type == IQEQueryTypeUnknown)
    {
        return ([query.qid isEqualToString:qid]);
    }
    else
    if (type == IQEQueryTypeLocalObject)
    {
        return ([query.objId   isEqualToString:objId]
            &&  [query.objName isEqualToString:objName]
            &&  [query.objMeta isEqualToString:objMeta]);
    }
    else
    if (type == IQEQueryTypeBarCode)
    {
        return ([query.codeData isEqualToString:codeData]
            &&  [query.codeType isEqualToString:codeType]);
    }
    
    return NO;
}

- (NSString*) title
{
    NSString* titleString = nil;
    
    if (type == IQEQueryTypeRemoteObject
    ||  type == IQEQueryTypeUnknown)
    {
        if (state == IQEQueryStateUnknown)        return @"";
        if (state == IQEQueryStateUploading)      return NSLocalizedStringFromTable(@"Uploading...",       BUNDLE_TABLE, @"");
        if (state == IQEQueryStateSearching)      return NSLocalizedStringFromTable(@"Searching...",       BUNDLE_TABLE, @"");
        if (state == IQEQueryStateNotReady)       return NSLocalizedStringFromTable(@"Not Ready",          BUNDLE_TABLE, @"");
        if (state == IQEQueryStateNetworkProblem) return NSLocalizedStringFromTable(@"On Hold",            BUNDLE_TABLE, @"");
        if (state == IQEQueryStateTimeoutProblem) return NSLocalizedStringFromTable(@"Connection Problem", BUNDLE_TABLE, @"");
        if (state == IQEQueryStateFound)
        {
            titleString = [self.qidData objectForKey:IQEKeyLabels];
        }
    }
    else
    if (type == IQEQueryTypeLocalObject)
    {
        if (state == IQEQueryStateFound)
            titleString = objName;
    }
    else
    if (type == IQEQueryTypeBarCode)
    {
        if (state == IQEQueryStateFound)
        {
            if (codeDesc && [codeDesc isEqualToString:@""] == NO)
                titleString = codeDesc;
            else
                titleString = codeData;
        }
    }
    
    if (state == IQEQueryStateNotFound)
        titleString = NSLocalizedStringFromTable(@"No Match", BUNDLE_TABLE, @"");            

    return [[titleString retain] autorelease];
}

- (void) setTitle:(NSString*)title
{
    NSString* previous = nil;
    
    if (type == IQEQueryTypeRemoteObject)
    {
        if (qidData == nil)
            return;
        
        previous = [[qidData objectForKey:IQEKeyLabels] copy];

        NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionaryWithDictionary:qidData];
        
        if (title == nil)
            [dataDictionary removeObjectForKey:IQEKeyLabels];
        else
            [dataDictionary setObject:title forKey:IQEKeyLabels];
        
        self.qidData = dataDictionary;
    }
    else
    if (type == IQEQueryTypeLocalObject)
    {
        previous = [objName copy];

        self.objName = title;
    }
    else
    if (type == IQEQueryTypeBarCode)
    {
        if (codeDesc && [codeDesc isEqualToString:@""] == NO)
        {
            previous = [codeDesc copy];

            self.codeDesc = title;
        }
        else
        {
            previous = [codeData copy];

            self.codeData = title;
        }
    }
    
    if (previous != title && [previous isEqualToString:title] == NO)
        [[NSNotificationCenter defaultCenter] postNotificationName:IQEQueryTitleChangeNotification object:self];
    
    [previous release];
}

- (void) setState:(IQEQueryState)newState
{
    if (state == newState)
        return;
    
    state = newState;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:IQEQueryStateChangeNotification object:self];
}

- (void) setState:(IQEQueryState)aState forType:(IQEQueryType)aType
{
    [mStates setObject:[self stringFromState:aState] forKey:[self stringFromType:aType]];
}

- (BOOL) complete
{
    if (mStates == nil || mStates.count == 0)
        return state == IQEQueryStateFound;
    
    NSUInteger count = 0;
    
    for (NSString* theType in [mStates allKeys])
    {
        NSString* theState = [mStates objectForKey:theType];
        
        if ([theState isEqualToString:QUERY_STATE_FOUND]
        ||  [theState isEqualToString:QUERY_STATE_NOTFOUND])
            count++;
    }
    
    if (count == mStates.count)
        return YES;
    
    return NO;
}

- (BOOL) found
{
    if (mStates == nil || mStates.count == 0)
        return state == IQEQueryStateFound;
    
    for (NSString* theType in [mStates allKeys])
    {
        NSString* theState = [mStates objectForKey:theType];
        
        if ([theState isEqualToString:QUERY_STATE_FOUND])
            return YES;
    }
    
    return NO;
}

- (NSDictionary*) qidData
{
    NSDictionary* data = nil;
    
    if (qidData)
    {
        data = qidData;
    }
    else
    {
        if (qidResults.count > 0)
            data = [qidResults objectAtIndex:0];
    }
    
    return [[data retain] autorelease];
}

- (void) setQidResults:(NSArray*)results
{
    if (qidResults == results)
        return;
        
    [qidResults autorelease];
    
    //
    // Remove results with same labels.
    //
    
    results = [IQEQuery removeDuplicates:results];
    
    qidResults = [results retain];
}

- (NSString*) description
{
    NSMutableDictionary* dictionary = [[[NSMutableDictionary alloc] init] autorelease];
    
    [self encodeWithDictionary:dictionary];
    
    return [dictionary description];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEQuery Private methods
// --------------------------------------------------------------------------------

- (NSString*) stringFromState:(IQEQueryState)aState
{
    if (aState == IQEQueryStateUnknown)        return QUERY_STATE_UNKNOWN;         else
    if (aState == IQEQueryStateUploading)      return QUERY_STATE_UPLOADING;       else
    if (aState == IQEQueryStateSearching)      return QUERY_STATE_SEARCHING;       else
    if (aState == IQEQueryStateFound)          return QUERY_STATE_FOUND;           else
    if (aState == IQEQueryStateNotFound)       return QUERY_STATE_NOTFOUND;        else
    if (aState == IQEQueryStateNotReady)       return QUERY_STATE_NOTREADY;        else
    if (aState == IQEQueryStateNetworkProblem) return QUERY_STATE_NETWORK_PROBLEM; else
    if (aState == IQEQueryStateTimeoutProblem) return QUERY_STATE_TIMEOUT_PROBLEM;
    
    NSAssert(NO, @"Unknown IQEQueryState");
    return @"";
}

- (NSString*) stringFromType:(IQEQueryType)aType
{
    if (aType == IQEQueryTypeUnknown)      return QUERY_TYPE_UNKNOWN; else
    if (aType == IQEQueryTypeRemoteObject) return QUERY_TYPE_REMOTE;  else
    if (aType == IQEQueryTypeLocalObject)  return QUERY_TYPE_LOCAL;   else
    if (aType == IQEQueryTypeBarCode)      return QUERY_TYPE_BARCODE;

    NSAssert(NO, @"Unknown IQEQueryType");
    return @"";
}

- (IQEQueryState) stateFromString:(NSString*)aString
{
    if ([aString isEqualToString:QUERY_STATE_UNKNOWN])         return IQEQueryStateUnknown;        else
    if ([aString isEqualToString:QUERY_STATE_UPLOADING])       return IQEQueryStateUploading;      else
    if ([aString isEqualToString:QUERY_STATE_SEARCHING])       return IQEQueryStateSearching;      else
    if ([aString isEqualToString:QUERY_STATE_FOUND])           return IQEQueryStateFound;          else
    if ([aString isEqualToString:QUERY_STATE_NOTFOUND])        return IQEQueryStateNotFound;       else
    if ([aString isEqualToString:QUERY_STATE_NOTREADY])        return IQEQueryStateNotReady;       else
    if ([aString isEqualToString:QUERY_STATE_NETWORK_PROBLEM]) return IQEQueryStateNetworkProblem; else
    if ([aString isEqualToString:QUERY_STATE_TIMEOUT_PROBLEM]) return IQEQueryStateTimeoutProblem;
    
    NSAssert(NO, @"Unknown state");
    return IQEQueryStateUnknown;
}

- (IQEQueryType) typeFromString:(NSString*)aString
{
    if ([aString isEqualToString:QUERY_TYPE_UNKNOWN]) return IQEQueryTypeUnknown;      else
    if ([aString isEqualToString:QUERY_TYPE_REMOTE])  return IQEQueryTypeRemoteObject; else
    if ([aString isEqualToString:QUERY_TYPE_LOCAL])   return IQEQueryTypeLocalObject;  else
    if ([aString isEqualToString:QUERY_TYPE_BARCODE]) return IQEQueryTypeBarCode;
    
    NSAssert(NO, @"Unknown type");
    return IQEQueryTypeUnknown;
}

+ (NSArray*)removeDuplicates:(NSArray*)inArray
{
    NSMutableArray* uniques = [NSMutableArray array];
    
    for (NSDictionary* queryData in inArray)
    {
        NSString* label = [queryData objectForKey:IQEKeyLabels];
        
        BOOL containsObject = NO;
        
        for (NSDictionary* queryDataUnique in uniques)
        {
            NSString* labelUnique = [queryDataUnique objectForKey:IQEKeyLabels];
            
            if ([label caseInsensitiveCompare:labelUnique] == NSOrderedSame)
            {
                containsObject = YES;
                break;
            }
        }
        
        if (containsObject == NO)
            [uniques addObject:queryData];
    }
    
    return uniques;
}

@end

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark NSMutableArray (IQEQuery)
// --------------------------------------------------------------------------------

@implementation NSMutableArray (IQEQuery)

- (id) initWithNSArray:(NSArray*)array
{
    self = [self initWithCapacity:array.count];
    if (self)
    {
        for (NSDictionary* queryDictionary in array)
        {
            IQEQuery* query = [[IQEQuery alloc] initWithDictionary:queryDictionary];
            [self addObject:query];
            [query release];
        }
    }
    return self;
}

- (void) encodeWithNSArray:(NSMutableArray*)array
{
    for (IQEQuery* query in self)
    {
        NSMutableDictionary* queryDictionary = [NSMutableDictionary dictionary];
        [query encodeWithDictionary:queryDictionary];
        
        [array addObject:queryDictionary];
    }
}

- (IQEQuery*) queryForQID:(NSString*)qid
{
    for (IQEQuery* query in self)
    {
        if ([query.qid isEqualToString:qid])
            return query;
    }
    
    return nil;
}

- (id) firstObject
{
    id firstItem = nil;
    if (self.count > 0)
        firstItem = [self objectAtIndex:0];
    
    return firstItem;
}

@end

// --------------------------------------------------------------------------------
