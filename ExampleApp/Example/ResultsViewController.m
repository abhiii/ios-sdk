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
//  ResultsViewController.m
//
// --------------------------------------------------------------------------------

#import "ResultsViewController.h"
#import "WebViewController.h"
#import "IQE.h"

@interface ResultsViewController () <UITableViewDataSource>
- (void) updateView;
@property(nonatomic, retain) IQEQuery*        mQuery;
@property(nonatomic, retain) UITableView*     mTableView;
@property(nonatomic, retain) UIImageView*     mImageView;
@property(nonatomic, retain) UIToolbar*       mToolBar;
@property(nonatomic, retain) UIBarButtonItem* mBackButton;
@property(nonatomic, retain) UIBarButtonItem* mWebButton;
@end

@implementation ResultsViewController

@synthesize mQuery;
@synthesize mTableView;
@synthesize mImageView;
@synthesize mToolBar;
@synthesize mBackButton;
@synthesize mWebButton;

#pragma mark -
#pragma mark ResultsViewController lifecycle

- (id) initWithQuery:(IQEQuery*)query
{
    self = [super initWithNibName:@"ResultsViewController" bundle:nil];
    if (self)
    {
        self.mQuery = query;
    }
    return self;
}

- (void)dealloc
{
    mTableView.dataSource = nil;
    
    [mBackButton release];
    [mWebButton  release];
    [mToolBar    release];
    [mImageView  release];
    [mTableView  release];
    
    [mQuery release];
    
    [super dealloc];
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    mTableView.separatorColor  = [UIColor colorWithWhite:0.5 alpha:0.25];
    mTableView.backgroundColor = [UIColor clearColor];
    mTableView.dataSource      = self;

    if (mQuery.qidResults)
    {
        if (mQuery.qidResults.count == 1)
            mTableView.scrollEnabled = NO;
        else
            mTableView.scrollEnabled = YES;
    }
    else
    {
        mTableView.scrollEnabled = NO;
    }
    
    if (mTableView.scrollEnabled == NO)
        mTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self updateView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.mBackButton = nil;
    self.mWebButton  = nil;
    self.mToolBar    = nil;
    self.mImageView  = nil;
    self.mTableView  = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark Actions

- (IBAction)onClose:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onWeb:(id)sender
{
    //
    // Get meta/url/label string to be used for web result.
    //
    
    NSString* dataString = nil;
    if (mQuery.type == IQEQueryTypeRemoteObject)
    {
        NSDictionary* results = mQuery.qidData;
        NSString*     labels  = [results objectForKey:IQEKeyLabels];
        NSString*     meta    = [results objectForKey:IQEKeyMeta];
        
        if (meta && [meta isEqualToString:@""] == NO && [NSURL URLWithString:meta])
            dataString = meta;
        else
        if (labels)
            dataString = labels;
    }
    else
    if (mQuery.type == IQEQueryTypeLocalObject)
    {
        dataString = mQuery.objMeta;
        
        // No Meta, so just use what is in the title.
        if (dataString == nil || [dataString isEqualToString:@""])
            dataString = mQuery.title;
    }
    
    //
    // Create URL from query result data string.
    //
    
    NSURL* url = nil;
    
    //
    // See if dataString is a valid URL.
    // if not, put text into a web search url.
    //
    
    url = [NSURL URLWithString:dataString];
    
    if (url == nil || url.scheme == nil)
    {
        NSString* encodedData = [dataString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString* stringURL   = [NSString stringWithFormat:@"http://www.google.com/search?q=%@", encodedData];
        
        url = [NSURL URLWithString:stringURL];
    }
    
    if (url && url.scheme)
    {
        WebViewController* vc = [[WebViewController alloc] initWithUrl:url];
            
        [self.navigationController pushViewController:vc animated:YES];
        [vc release];
    }
}

#pragma mark -
#pragma mark <UITableViewDataSource> implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (mQuery.qidResults.count)
        return mQuery.qidResults.count;
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = nil;
    
    static NSString* cellIdentifier = @"IQEResultsCell";
    
    cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier] autorelease];
    
    if (indexPath.row < mQuery.qidResults.count)
    {
        NSDictionary* queryData = [mQuery.qidResults objectAtIndex:indexPath.row];
        cell.textLabel.text = [queryData objectForKey:IQEKeyLabels];
    }
    else
    {
        cell.textLabel.text = mQuery.title;
    }

    cell.textLabel.font                 = [UIFont boldSystemFontOfSize:18];
    cell.textLabel.numberOfLines        = 1;
    cell.textLabel.textColor            = [UIColor whiteColor];
    cell.backgroundView                 = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
    cell.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
    
    return cell;
}

#pragma mark -
#pragma mark Private methods

- (void)updateView
{
    //
    // Image.
    //
    
    if (mQuery.type == IQEQueryTypeLocalObject
    ||  mQuery.type == IQEQueryTypeRemoteObject)
    {        
        NSString* documentPath  = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString* imageFilePath = [documentPath stringByAppendingPathComponent:mQuery.imageFile];
        
        mImageView.image = [UIImage imageWithContentsOfFile:imageFilePath];
    }
}

@end
