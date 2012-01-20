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
//  WebViewController.m
//

#import "WebViewController.h"

@interface WebViewController ()
- (void) updateToolbarButtons;
@end

@implementation WebViewController

@synthesize url;

- (id)initWithUrl:(NSURL *)urlInput
{
    self = [super initWithNibName:@"WebViewController" bundle:nil];
    if (self)
    {
        self.url = urlInput;
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"%s", __func__);
    
    [webView stopLoading];
    webView.delegate = nil;
    
    [webView           release];
    [activityIndicator release];
    [backButton        release];
    [forwardButton     release];
    [url               release];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    webView.delegate        = self;
    webView.scalesPageToFit = YES;

    NSURLRequest* requestObject = [NSURLRequest requestWithURL:url];
    [webView loadRequest:requestObject];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [backButton release];
    backButton = nil;
    
    [forwardButton release];
    forwardButton = nil;

    [activityIndicator release];
    activityIndicator = nil;
    
    [webView release];
    webView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateToolbarButtons];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Actions

- (IBAction)onClose:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backButtonDidClick:(id)sender
{
    if (webView.canGoBack)
        [webView goBack];
}

- (IBAction)forwardButtonDidClick:(id)sender
{
    if (webView.canGoForward)
        [webView goForward];
}

- (IBAction)actionButtonDidClick:(id)sender
{
    UIActionSheet* actionsheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self 
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                               destructiveButtonTitle:nil 
                                                    otherButtonTitles:NSLocalizedString(@"Open with Safari", @""), nil];
    [actionsheet showInView:self.view];
    [actionsheet release];
}

#pragma mark -
#pragma mark Private method implementation

- (void)updateToolbarButtons
{
    backButton.enabled    = webView.canGoBack;
    forwardButton.enabled = webView.canGoForward;
}

#pragma mark -
#pragma mark <UIWebViewDelegate> implementation

- (void)webViewDidStartLoad:(UIWebView*)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView*)webView
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [activityIndicator stopAnimating];

    [self updateToolbarButtons];
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [activityIndicator stopAnimating];

    [self updateToolbarButtons];
}

- (void)webviewDidClick 
{
    
}

#pragma mark -
#pragma mark UIActionSheetDelegate methods implementation

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case 0:
            [[UIApplication sharedApplication] openURL:url];
            break;
            
        default:
            break;
    }
}

@end
