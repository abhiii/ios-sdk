/*
 Copyright (c) 2012 IQ Engines, Inc.
 
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
//  ExampleViewController.m
//
// --------------------------------------------------------------------------------

#import "ExampleViewController.h"
#import "IQEViewController.h"
#import "WebViewController.h"
#import "UINavigationController+Rotation.h"
#import "ResultsViewController.h"
#import "Config.h"

@implementation ExampleViewController

@synthesize iqeNavController;

// --------------------------------------------------------------------------------
#pragma mark - Actions
// --------------------------------------------------------------------------------

- (IBAction)onButton:(id)sender
{
    IQESearchType searchType = 0;
    
    if (SEARCH_BARCODE       == YES) searchType |= IQESearchTypeBarCode;
    if (SEARCH_OBJECT_LOCAL  == YES) searchType |= IQESearchTypeObjectSearch;
    if (SEARCH_OBJECT_REMOTE == YES) searchType |= IQESearchTypeRemoteSearch;
    
    IQEViewController* vc = [[IQEViewController alloc] initWithParameters:searchType
                                                                   apiKey:IQE_APIKEY
                                                                apiSecret:IQE_SECRET];
    
    vc.delegate        = self;
    vc.hidesBackButton = NO;
    vc.autoDetection   = SEARCH_OBJECT_LOCAL_CONTINUOUS;
    vc.locationEnabled = NO;
    
    self.iqeNavController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    
    self.iqeNavController.navigationBarHidden = YES;
    
    [self presentModalViewController:self.iqeNavController animated:YES];
    
    [vc release];
}

// --------------------------------------------------------------------------------
#pragma mark - <IQEViewControllerDelegate> implementation
// --------------------------------------------------------------------------------

// Called when an image search has completed. Results are contained in the query object.

- (void) iqeViewController:(IQEViewController*)controller didCompleteSearch:(IQEQuery*)query
{
    NSLog(@"%s", __func__);
}

// Called after the user selects an item in the history list.

- (void) iqeViewController:(IQEViewController*)controller didSelectItem:(IQEQuery*)query atIndex:(NSUInteger)index
{
    if (query.type == IQEQueryTypeRemoteObject && query.qidResults)
        NSLog(@"results: %@", query.qidResults);
    else
    if (query.type == IQEQueryTypeRemoteObject && query.qidData)
        NSLog(@"result: %@", query.qidData);
    else
    if (query.type == IQEQueryTypeLocalObject)
        NSLog(@"objID: %@, objName: %@, objMeta: %@", query.objId, query.objName, query.objMeta);
    else
    if (query.type == IQEQueryTypeBarCode)
        NSLog(@"codeData: %@, codeType:%@, codeDesc:%@", query.codeData, query.codeType, query.codeDesc);
    
    //
    // Take action based on query.
    //
    
    // If query title is a url, go directly to a WebView.
    NSURL* url = [NSURL URLWithString:query.title];
    
    // Go to shop webView if UPC/EAN barcode.
    if (query.type == IQEQueryTypeBarCode)
    {
        NSString* stringData  = query.codeData;
        NSString* encodedData = [stringData stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* stringURL   = nil;

        if ([query.codeType isEqualToString:IQEBarcodeTypeEAN8]
        ||  [query.codeType isEqualToString:IQEBarcodeTypeEAN13]
        ||  [query.codeType isEqualToString:IQEBarcodeTypeUPCA]
        ||  [query.codeType isEqualToString:IQEBarcodeTypeUPCE])
        {
            stringURL = [NSString stringWithFormat:@"http://www.google.com/products?q=%@", encodedData];
        }
        else
        {
            stringURL = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", encodedData];
        }
        
        url = [NSURL URLWithString:stringURL];
    }
    
    if (url && url.scheme)
    {        
        WebViewController* vc = [[WebViewController alloc] initWithUrl:url];
            
        [iqeNavController pushViewController:vc animated:YES];
        [vc release];
    }
    else
    {
        ResultsViewController* vc = [[ResultsViewController alloc] initWithQuery:query];
        
        [iqeNavController pushViewController:vc animated:YES];
        [vc release];
    }
}

// The delegate should dismiss the view controller in this callback. The controller does not dismiss itself.

- (void) iqeViewControllerDidCancel:(IQEViewController*)controller
{
    controller.delegate = nil;
    [controller dismissModalViewControllerAnimated:YES];
    
    self.iqeNavController = nil;
}

@end

// --------------------------------------------------------------------------------

