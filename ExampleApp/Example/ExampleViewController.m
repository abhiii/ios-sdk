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

//
//  ExampleViewController.m
//

#import "ExampleViewController.h"
#import "IQEViewController.h"
#import "WebViewController.h"
#import "Config.h"

@interface ExampleViewController ()
- (void) showWebViewForUrl:(NSString*)stringURL;
@end

@implementation ExampleViewController

@synthesize iqeNavController;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Actions

- (IBAction)onButton:(id)sender
{
    IQESearchType searchType = 0;
    
    if (SEARCH_BARCODE       == YES) searchType |= IQESearchTypeBarCode;
    if (SEARCH_OBJECT_LOCAL  == YES) searchType |= IQESearchTypeObjectSearch;
    if (SEARCH_OBJECT_REMOTE == YES) searchType |= IQESearchTypeRemoteSearch;
    
    IQEViewController* vc = [[IQEViewController alloc] initWithSearchType:searchType
                                                                   apiKey:IQE_APIKEY
                                                                apiSecret:IQE_SECRET];
    
    vc.delegate        = self;
    vc.hidesBackButton = NO;
    vc.autoDetection   = SEARCH_OBJECT_LOCAL_CONTINUOUS;
    vc.locationEnabled = YES;
    
    self.iqeNavController = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    
    self.iqeNavController.navigationBarHidden = YES;
    
    [self presentModalViewController:self.iqeNavController animated:YES];
    
    [vc release];
}

#pragma mark - <IQEViewControllerDelegate> implementation

- (void) iqeViewController:(IQEViewController*)controller didCompleteSearch:(IQEHistoryItem*)historyItem
{
    NSLog(@"%s", __func__);
}

// History list selection
- (void) iqeViewController:(IQEViewController*)controller didSelectItem:(IQEHistoryItem *)historyItem atIndex:(NSUInteger)index
{
    if (historyItem.type == IQEHistoryItemTypeRemoteObject)
    {
        NSLog(@"result: %@", historyItem.qidData);
        
        NSString* labels = [historyItem.qidData objectForKey:IQEKeyLabels];
        if (labels == nil)
            return;
        
        [self showWebViewForUrl:labels];
    }
    else
    if (historyItem.type == IQEHistoryItemTypeLocalObject)
    {
        NSLog(@"objID: %@, objName: %@, objMeta: %@", historyItem.objId, historyItem.objName, historyItem.objMeta);
        
        [self showWebViewForUrl:historyItem.objMeta];
    }
    else
    if (historyItem.type == IQEHistoryItemTypeBarCode)
    {
        NSLog(@"codeData: %@, codeType:%@, codeDesc:%@", historyItem.codeData, historyItem.codeType, historyItem.codeDesc);
        
        [self showWebViewForUrl:historyItem.codeData];
    }
}

- (void) iqeViewControllerDidCancel:(IQEViewController*)controller
{
    controller.delegate = nil;
    [controller dismissModalViewControllerAnimated:YES];
    
    self.iqeNavController = nil;
}

#pragma mark - Private

- (void) showWebViewForUrl:(NSString*)stringURL
{
    NSURL* url = [NSURL URLWithString:stringURL];
    
    if (url == nil || url.scheme == nil)
    {
        NSString* encodedData = [stringURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* stringURL   = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", encodedData];
        
        url = [NSURL URLWithString:stringURL];
    }
    
    WebViewController* vc = [[WebViewController alloc] initWithUrl:url];
    
    [self.iqeNavController pushViewController:vc animated:YES];
    [vc release];
}

@end
