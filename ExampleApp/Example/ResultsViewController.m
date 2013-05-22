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

#define LIST_MAX_CELLS        4
#define LIST_MAX_HEIGHT     180
#define LIST_CELL_HEIGHT     (LIST_MAX_HEIGHT / LIST_MAX_CELLS)

@interface ResultsViewController () <UITableViewDataSource, UITableViewDelegate>
- (void) updateView;
- (void) navigateToWebWithIndexPath:(NSIndexPath*)indexPath;
@property(nonatomic, retain) IQEQuery*        mQuery;
@property(nonatomic, retain) UITableView*     mTableView;
@property(nonatomic, retain) UIImageView*     mImageView;
@property(nonatomic, retain) UIToolbar*       mToolBar;
@property(nonatomic, retain) UIBarButtonItem* mBackButton;
@end

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark ResultsViewController implementation
// --------------------------------------------------------------------------------

@implementation ResultsViewController

@synthesize mQuery;
@synthesize mTableView;
@synthesize mImageView;
@synthesize mToolBar;
@synthesize mBackButton;

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark ResultsViewController lifecycle
// --------------------------------------------------------------------------------

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
    //NSLog(@"%s", __func__);
        
    mTableView.delegate   = nil;
    mTableView.dataSource = nil;
    
    [mBackButton release];
    [mToolBar    release];
    [mImageView  release];
    [mTableView  release];
    
    [mQuery release];
    
    [super dealloc];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark UIViewController
// --------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //
    // Table View
    //
    
    mTableView.separatorColor  = [UIColor colorWithWhite:0.5 alpha:0.25];
    mTableView.backgroundColor = [UIColor clearColor];
    mTableView.delegate        = self;
    mTableView.dataSource      = self;
    mTableView.rowHeight       = LIST_CELL_HEIGHT;
    
    [self updateView];
}

- (void)viewDidLayoutSubviews
{
    [self updateView];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    self.mBackButton = nil;
    self.mToolBar    = nil;
    self.mImageView  = nil;
    self.mTableView  = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}
#endif

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Actions
// --------------------------------------------------------------------------------

- (IBAction)onClose:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private methods
// --------------------------------------------------------------------------------

- (void)updateView
{
    //
    // Text/tableview.
    //
    
    NSUInteger rowCount = 0;
    
    if (mQuery.qidResults == nil)
    {
        // No multiple_results. Show one row.
        mTableView.scrollEnabled = NO;
        rowCount = 1;
    }
    else
    if (mQuery.qidResults.count <= LIST_MAX_CELLS)
    {
        mTableView.scrollEnabled = NO;
        rowCount = mQuery.qidResults.count;
    }
    else
    {
        mTableView.scrollEnabled = YES;
        rowCount = LIST_MAX_CELLS;
    }
    
    // Position list on bottom of imageview.
    // Move down by 1 to hide separator on bottom.
    mTableView.frame = CGRectMake(mTableView.frame.origin.x,
                                  mImageView.frame.origin.y + mImageView.frame.size.height - (LIST_CELL_HEIGHT * rowCount) + 1,
                                  mTableView.frame.size.width,
                                  (LIST_CELL_HEIGHT * rowCount) - 1);
    
    if (rowCount == 1)
        mTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    else
        mTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    [mTableView reloadData];
    
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

- (void) navigateToWebWithIndexPath:(NSIndexPath*)indexPath
{
    //
    // Get meta/url/label string to be used for web result.
    //
    
    NSString* dataString = nil;
    if (mQuery.type == IQEQueryTypeRemoteObject)
    {
        NSDictionary* results = nil;
        
        if (mQuery.qidResults)
            results = [mQuery.qidResults objectAtIndex:(NSUInteger)[indexPath row]];
        else
            results = mQuery.qidData;
        
        NSString* labels  = [results objectForKey:IQEKeyLabels];
        NSString* meta    = [results objectForKey:IQEKeyMeta];
        
        if (meta && [meta isEqualToString:@""] == NO && [meta isEqualToString:@"{}"] == NO && [NSURL URLWithString:meta])
            dataString = meta;
        else
        if (labels)
            dataString = labels;
    }
    else
    if (mQuery.type == IQEQueryTypeBarCode)
    {
        dataString = mQuery.codeData;
    }
    else
    if (mQuery.type == IQEQueryTypeLocalObject)
    {
        dataString = mQuery.objMeta;
        
        // If no Meta, so just use what is in the title.
        if (dataString == nil || [dataString isEqualToString:@""] || [dataString isEqualToString:@"{}"])
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

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <UITableViewDataSource> implementation
// --------------------------------------------------------------------------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (mQuery.qidResults.count)
        return (NSInteger)mQuery.qidResults.count;
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
    
    if (indexPath.row < (NSInteger)mQuery.qidResults.count)
    {
        NSDictionary* queryData = [mQuery.qidResults objectAtIndex:(NSUInteger)indexPath.row];
        cell.textLabel.text = [queryData objectForKey:IQEKeyLabels];
    }
    else
    {
        cell.textLabel.text = mQuery.title;
    }
    
    UIImage*     arrowImage         = [UIImage imageNamed:@"IQEAccessoryDisclosureArrow.png"];
    UIImageView* accessoryImageView = [[UIImageView alloc] initWithImage:arrowImage];
    
    [accessoryImageView sizeToFit];
    
    cell.accessoryView = accessoryImageView;
    
    [accessoryImageView release];
    
    cell.textLabel.font                 = [UIFont boldSystemFontOfSize:14];
    cell.textLabel.numberOfLines        = 1;
    cell.textLabel.textColor            = [UIColor whiteColor];
    cell.backgroundView                 = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
    cell.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
    
    return cell;
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <UITableViewDelegate> implementation
// --------------------------------------------------------------------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self navigateToWebWithIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
