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
//  IQEViewController.m
//
// --------------------------------------------------------------------------------

#import "IQEViewController.h"
#import "IQEHistoryTableViewCell.h"
#import "IQEQuery.h"
#import "IQELocation.h"
#import "UIImage+IQE.h"

#define STR_DATADIR           @"iqe"
#define STR_DATAFILE          @"IQEData.plist"
#define STR_DATAFILE_VER      @"1.0"
#define STR_KEY_VERSION       @"version"
#define STR_KEY_HISTORY       @"history"

#define BUNDLE_TABLE          @"IQE"

#define DEFAULTS_KEY_RUNCOUNT @"IQERunCount"

#define CELL_HEIGHT           60.0f
#define MAX_DISPLAYCELLS      3.0f
#define THUMB_WIDTH           50.0f
#define THUMB_HEIGHT          50.0f
#define SWIPE_HORIZ_MAX       40.0f
#define SWIPE_VERT_MIN        40.0f

typedef enum 
{
    ListDisplayModeNone,
    ListDisplayModeResult,
    ListDisplayModeHistory,
} ListDisplayMode;

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEViewController Private interface
// --------------------------------------------------------------------------------

@interface IQEViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>
- (void)   queryTitleChange:(NSNotification*)n;
- (void)   queryStateChange:(NSNotification*)n;
- (void)   updateView;
- (void)   updateToolbar;
- (void)   loadState;
- (void)   saveState;
- (void)   applicationDidEnterBackground;
- (void)   applicationWillEnterForeground;
- (void)   processUnfinishedQueries:(BOOL)search;
- (CGRect) historyListRect;
- (CGSize) thumbSize;
- (void)   startSearchForQuery:(IQEQuery*)query withImage:(UIImage*)image;
- (void)   saveImageFiles:(IQEQuery*)query forImage:(UIImage*)image;
- (void)   removeImageFiles:(IQEQuery*)query;
@property(nonatomic, assign) IQESearchType    mSearchType;
@property(nonatomic, retain) UITableView*     mTableView;
@property(nonatomic, retain) UIView*          mPreviewView;
@property(nonatomic, retain) UIToolbar*       mToolBar;
@property(nonatomic, retain) UIBarButtonItem* mBackButton;
@property(nonatomic, retain) UIButton*        mCameraButton;
@property(nonatomic, retain) UIBarButtonItem* mHistoryButton;
@property(nonatomic, assign) BOOL             mFirstViewLoad;
@property(nonatomic, assign) CGFloat          mZoom;
@property(nonatomic, retain) NSMutableArray*  mQueryHistory;
@property(nonatomic, retain) NSString*        mDocumentPath;
@property(nonatomic, retain) NSString*        mDataPath;
@property(nonatomic, assign) CGPoint          mStartTouchPosition;
@property(nonatomic, assign) ListDisplayMode  mListDisplayMode;
@end

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEViewController implementation
// --------------------------------------------------------------------------------

@implementation IQEViewController

@synthesize delegate = mDelegate;
@synthesize hidesBackButton;
@synthesize locationEnabled;
@synthesize mPreviewView;
@synthesize mBackButton;
@synthesize mCameraButton;
@synthesize mHistoryButton;
@synthesize mFirstViewLoad;
@synthesize mZoom;
@synthesize mToolBar;
@synthesize mSearchType;
@synthesize mTableView;
@synthesize mQueryHistory;
@synthesize mDocumentPath;
@synthesize mDataPath;
@synthesize mStartTouchPosition;
@synthesize mListDisplayMode;

- (id)initWithParameters:(IQESearchType)searchType
{
    return [self initWithParameters:searchType apiKey:nil apiSecret:nil];
}

- (id)initWithParameters:(IQESearchType)searchType apiKey:(NSString*)key apiSecret:(NSString*)secret
{
    self = [super initWithNibName:@"IQEViewController" bundle:nil];
    if (self)
    {
        //
        // Create directory to store files.
        //
        
        NSArray*  paths        = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* documentPath = [paths objectAtIndex:0];
        NSString* dataPath     = [documentPath stringByAppendingPathComponent:STR_DATADIR];
        NSError*  error        = nil;
        
        if ([[NSFileManager defaultManager] createDirectoryAtPath:dataPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error] == NO)
        {
            NSLog(@"IQEViewController: Error creating directory %@: %@", dataPath, error.localizedDescription);
        }
        
        //
        // Initialize state variables.
        //
        
        self.mDocumentPath    = documentPath;
        self.mDataPath        = dataPath;
        self.mQueryHistory    = [NSMutableArray arrayWithCapacity:0];
        self.mSearchType      = searchType;
        self.mZoom            = 1.4;
        self.mListDisplayMode = ListDisplayModeNone;
        self.hidesBackButton  = NO;
        self.locationEnabled  = NO;
        self.mFirstViewLoad   = YES;
        
        //
        // Init IQE.
        //
        
        mIQE = [[IQE alloc] initWithParameters:searchType
                                        apiKey:key
                                     apiSecret:secret];
        
        mIQE.delegate = self;
        
        //
        // Register notification message for query changes.
        //
        
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self
                               selector:@selector(queryTitleChange:) 
                                   name:IQEQueryTitleChangeNotification
                                 object:nil];
        
        [notificationCenter addObserver:self
                               selector:@selector(queryStateChange:) 
                                   name:IQEQueryStateChangeNotification
                                 object:nil];
        
        //
        // Set up application notifications for saving/restoring state.
        //
        
        if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]
        &&  [[UIDevice currentDevice] isMultitaskingSupported])
        {
            [notificationCenter addObserver:self
                                   selector:@selector(applicationDidEnterBackground)
                                       name:UIApplicationDidEnterBackgroundNotification
                                     object:nil];
            
            [notificationCenter addObserver:self
                                   selector:@selector(applicationWillEnterForeground)
                                       name:UIApplicationWillEnterForegroundNotification
                                     object:nil];
        }
        else
        {
            [notificationCenter addObserver:self
                                   selector:@selector(applicationDidEnterBackground)
                                       name:UIApplicationWillTerminateNotification
                                     object:nil];
        }
        
        //
        // Load data from storage.
        //
        
        [self loadState];
        
        //
        // Start GPS
        //
        
        if ((mSearchType & IQESearchTypeRemoteSearch) && self.locationEnabled)
            [[IQELocation location] startLocating];
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"%s", __func__);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    mIQE.delegate = nil;
    [mIQE stopCamera];
    
    mTableView.delegate   = nil;
    mTableView.dataSource = nil;

    [self applicationDidEnterBackground];

    [mIQE           release];
    [mPreviewView   release];
    [mToolBar       release];
    [mBackButton    release];
    [mCameraButton  release];
    [mHistoryButton release];
    [mTableView     release];
    [mQueryHistory  release];
    [mDocumentPath  release];
    [mDataPath      release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    NSLog(@"%s", __func__);

    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark UIViewController
// --------------------------------------------------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //
    // Set up video preview layer.
    //
    
    [mPreviewView.layer insertSublayer:mIQE.previewLayer atIndex:0];
    
    mPreviewView.backgroundColor = [UIColor blackColor];
    mPreviewView.clipsToBounds   = YES;
    
    //
    // History list.
    //
    
    CGRect historyRect = [self historyListRect];
    
    self.mTableView = [[[UITableView alloc] initWithFrame:historyRect style:UITableViewStylePlain] autorelease];
    
    mTableView.separatorColor   = [UIColor colorWithWhite:0.5 alpha:0.25];
    mTableView.rowHeight        = CELL_HEIGHT;
    mTableView.backgroundColor  = [UIColor clearColor];
    mTableView.delegate         = self;
    mTableView.dataSource       = self;
    mTableView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    [mPreviewView addSubview:mTableView];
    
    //
    // Accessibility.
    //
    
    [mCameraButton  setAccessibilityLabel:NSLocalizedStringFromTable(@"Take Picture", BUNDLE_TABLE, @"")];
    [mBackButton    setAccessibilityLabel:NSLocalizedStringFromTable(@"Back",         BUNDLE_TABLE, @"")];
    [mHistoryButton setAccessibilityLabel:NSLocalizedStringFromTable(@"History",      BUNDLE_TABLE, @"")];
    [mPreviewView   setAccessibilityLabel:NSLocalizedStringFromTable(@"Viewfinder",   BUNDLE_TABLE, @"")];
    
    [self updateToolbar];
    [self updateView];
    
    //
    // Run on the first view load.
    //
    
    if (mFirstViewLoad)
    {
        //
        // Handle unfinished queries.
        //
        
        [self processUnfinishedQueries:YES];
        
        mFirstViewLoad = NO;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    mTableView.delegate   = nil;
    mTableView.dataSource = nil;

    self.mTableView     = nil;
    self.mPreviewView   = nil;
    self.mToolBar       = nil;
    self.mBackButton    = nil;
    self.mCameraButton  = nil;
    self.mHistoryButton = nil;
}

- (void)viewDidLayoutSubviews
{
    [self updateView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [mIQE startCamera];    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [mIQE stopCamera];
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    [mTableView setEditing:editing animated:animated];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Application lifecycle
// --------------------------------------------------------------------------------

- (void)applicationDidEnterBackground
{
    [self saveState];
    
    [[IQELocation location] stopLocating];
}

- (void)applicationWillEnterForeground
{
    [self loadState];
    
    if (mSearchType & IQESearchTypeRemoteSearch && self.locationEnabled)
        [[IQELocation location] startLocating];
    
    [self processUnfinishedQueries:NO];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <IQEDelegate> implementation
// --------------------------------------------------------------------------------

- (void)iqEngines:(IQE*)iqe didCompleteSearch:(IQESearchType)type withResults:(NSArray*)results forQID:(NSString*)qid
{
    IQEQuery*  query       = nil;
    NSUInteger scrollIndex = NSNotFound;
    
    if (results.count <= 0)
        return;
    
    // Multiple results. Take the first one.
    NSDictionary* result = [results objectAtIndex:0];
    
    if (qid)
    {
        query = [mQueryHistory queryForQID:qid];
        if (!query)
            return; // query for this qid has been deleted. Ignore result.
    }
    
    //
    // Deal with queries that have no results.
    //
    
    if (query && result.count == 0)
    {
        if (type == IQESearchTypeRemoteSearch)
            [query setState:IQEQueryStateNotFound forType:IQEQueryTypeRemoteObject];
        else
        if (type == IQESearchTypeObjectSearch)
            [query setState:IQEQueryStateNotFound forType:IQEQueryTypeLocalObject];
        else
        if (type == IQESearchTypeBarCode)
            [query setState:IQEQueryStateNotFound forType:IQEQueryTypeBarCode];
        
        // If the search is complete, find out if there are any results found.
        if ([query complete] == YES
        &&  [query found]    == NO)
        {
            query.type  = IQEQueryTypeUnknown;
            query.state = IQEQueryStateNotFound;
        }
        
        return;
    }
    
    if (type == IQESearchTypeRemoteSearch)
    {
        if (query)
        {
            [query setState:IQEQueryStateFound forType:IQEQueryTypeRemoteObject];
            
            // Ignore remote result if local or barcode is already finished.
            if (query.type == IQEQueryTypeBarCode
            ||  query.type == IQEQueryTypeLocalObject)
                return;
            
            if (query.state != IQEQueryStateFound)
                scrollIndex = [mQueryHistory indexOfObject:query];
            
            if (results.count >= 1)
            {
                // multiple_results
                query.qidResults = results;
                query.qidData    = nil;
            }
            else
            {
                query.qidResults = nil;
                query.qidData    = result;
            }
            
            query.type  = IQEQueryTypeRemoteObject;
            query.state = IQEQueryStateFound;
            
            [mTableView reloadData];
        }
    }
    else
    if (type == IQESearchTypeObjectSearch)
    {
        NSString* objId     = [result objectForKey:IQEKeyObjectId];
        NSString* objName   = [result objectForKey:IQEKeyObjectName];
        NSString* objMeta   = [result objectForKey:IQEKeyObjectMeta];
        NSString* imagePath = [result objectForKey:IQEKeyObjectImagePath];
        
        if (query)
        {
            [query setState:IQEQueryStateFound forType:IQEQueryTypeLocalObject];
            
            UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
            if (image)
            {
                // Remove images. Local Object item uses images in local files.
                [self removeImageFiles:query];
                
                // Use local object images.
                [self saveImageFiles:query forImage:image];
            }
            
            query.qidData    = nil; // local results overwrite remote object
            query.qidResults = nil; // local results overwrite remote object
            query.objId      = objId;
            query.objName    = objName;
            query.objMeta    = objMeta;
            query.type       = IQEQueryTypeLocalObject;
            query.state      = IQEQueryStateFound;
            
            scrollIndex = [mQueryHistory indexOfObject:query];
        }
        else
        {
            // Automatic detect.
            
            IQEQuery* newQuery = [[[IQEQuery alloc] init] autorelease];
            
            newQuery.objId   = objId;
            newQuery.objName = objName;
            newQuery.objMeta = objMeta;
            newQuery.type    = IQEQueryTypeLocalObject;
            
            IQEQuery* latestQuery = [mQueryHistory firstObject];
            if (latestQuery == nil || [latestQuery isEqualToQuery:newQuery] == NO)
            {
                UIImage* image = [UIImage imageWithContentsOfFile:imagePath];
                if (image)
                    [self saveImageFiles:newQuery forImage:image];
                
                newQuery.state = IQEQueryStateFound;
                
                [mQueryHistory insertObject:newQuery atIndex:0];
                [mTableView reloadData];
            }
            else
            {
                if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iPhoneOS_3_2)
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, latestQuery.title);
            }
            
            scrollIndex = 0;
        }
    }
    else
    if (type == IQESearchTypeBarCode)
    {
        NSString* barData = [result objectForKey:IQEKeyBarcodeData];
        NSString* barType = [result objectForKey:IQEKeyBarcodeType];
        
        if (query)
        {
            [query setState:IQEQueryStateFound forType:IQEQueryTypeBarCode];
            
            // Remove images. Barcode item uses default images in bundle.
            [self removeImageFiles:query];
            
            query.qidData    = nil; // local results overwrite remote object
            query.qidResults = nil; // local results overwrite remote object
            query.codeData   = barData;
            query.codeType   = barType;
            query.type       = IQEQueryTypeBarCode;
            query.state      = IQEQueryStateFound;
            
            scrollIndex = [mQueryHistory indexOfObject:query];
        }
        else
        {
            // Automatic detect.
            
            IQEQuery* newQuery = [[[IQEQuery alloc] init] autorelease];
            
            newQuery.codeData = barData;
            newQuery.codeType = barType;
            newQuery.type     = IQEQueryTypeBarCode;
            
            IQEQuery* latestQuery = [mQueryHistory firstObject];
            if (latestQuery == nil || [latestQuery isEqualToQuery:newQuery] == NO)
            {                
                newQuery.state = IQEQueryStateFound;
                
                [mQueryHistory insertObject:newQuery atIndex:0];
                [mTableView reloadData];
            }
            
            scrollIndex = 0;
        }
    }
    
    //
    // Update UI:
    // - Scroll list to query
    // - Show list
    //
    
    if (scrollIndex != NSNotFound && [mTableView numberOfRowsInSection:0] > 0)
    {
        [mTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(NSInteger)scrollIndex inSection:0]
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:YES];
        
        if (mListDisplayMode == ListDisplayModeNone)
            mListDisplayMode = ListDisplayModeResult;
        
        [self updateView];
    }
}

- (void)iqEngines:(IQE*)iqe didCaptureStillFrame:(UIImage*)image
{
    //
    // Crop image to adjust for preview zoom factor.
    //
        
    CGRect cropRect = CGRectMake((image.size.width  - (image.size.width  / mZoom)) / 2,
                                 (image.size.height - (image.size.height / mZoom)) / 2,
                                  image.size.width  / mZoom,
                                  image.size.height / mZoom);
    
    image = [image croppedImage:CGRectIntegral(cropRect)];
    
    //
    // Got an image due to the camera button press. Start a new search.
    //
    
    IQEQuery* newQuery = [[IQEQuery alloc] init];
    
    [self startSearchForQuery:newQuery withImage:image];
    
    [mQueryHistory insertObject:newQuery atIndex:0];
    
    [self saveImageFiles:newQuery forImage:image];
    
    //
    // Update UI
    //
    
    [mTableView reloadData];
    [mTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                      atScrollPosition:UITableViewScrollPositionTop
                              animated:NO];
    
    if (mListDisplayMode == ListDisplayModeNone)
        mListDisplayMode = ListDisplayModeResult;
    
    [self updateView];
    
    [newQuery release];
}

- (void)iqEngines:(IQE*)iqe statusDidChange:(IQEStatus)status forQID:(NSString *)qid
{
    IQEQuery* query = [mQueryHistory queryForQID:qid];
    
    if (query == nil)
        return;
    
    // Ignore remote status if local or barcode is already finished.
    if (query.type == IQEQueryTypeBarCode
    ||  query.type == IQEQueryTypeLocalObject)
        return;
    
    // State should not change once found or not found.
    if (query.state == IQEQueryStateFound
    ||  query.state == IQEQueryStateNotFound)
        return;
    
    switch (status)
    {
        case IQEStatusUnknown:
            query.state = IQEQueryStateUnknown;
            break;
            
        case IQEStatusError:
            query.state = IQEQueryStateNetworkProblem;
            break;

        case IQEStatusUploading:
            query.state = IQEQueryStateUploading;
            break;
            
        case IQEStatusSearching:
            query.state = IQEQueryStateSearching;
            break;
            
        case IQEStatusNotReady:
            query.state = IQEQueryStateNotReady;
            break;
            
        default:
            break;
    }
}

- (void) iqEngines:(IQE*)iqe didFindBarcodeDescription:(NSString*)desc forUPC:(NSString*)upc
{
    if (desc == nil || [desc isEqualToString:@""])
        return;
    
    for (IQEQuery* query in mQueryHistory)
    {
        if (query.type == IQEQueryTypeBarCode
        && [query.codeData isEqualToString:upc]  == YES
        && [query.codeDesc isEqualToString:desc] == NO)
        {
            query.codeDesc = desc;
            
            [mTableView reloadData];
            
            if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iPhoneOS_3_2)
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, query.title);

            break;
        }
    }
}

- (void)iqEngines:(IQE*)iqe failedWithError:(NSError*)error
{
    NSLog(@"failedWithError: %@", error.localizedDescription);
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <UITableViewDataSource> implementation
// --------------------------------------------------------------------------------

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (NSInteger)mQueryHistory.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    IQEHistoryTableViewCell* cell = nil;
    
    static NSString* cellIdentifier = @"IQECell";

    cell = (IQEHistoryTableViewCell*)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
        cell = [[[IQEHistoryTableViewCell alloc] initWithReuseIdentifier:cellIdentifier] autorelease];
    
    IQEQuery* query = [mQueryHistory objectAtIndex:(NSUInteger)indexPath.row];
    
    cell.textLabel.text                 = query.title;
    cell.textLabel.font                 = (query.state == IQEQueryStateFound) ? [UIFont boldSystemFontOfSize:14] : [UIFont systemFontOfSize:14];
    cell.textLabel.numberOfLines        = 1;
    cell.textLabel.textColor            = [UIColor whiteColor];
    cell.backgroundView                 = [[[UIView alloc] initWithFrame:cell.frame] autorelease];
    cell.backgroundView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
    cell.imageViewSize                  = CGSizeMake(THUMB_WIDTH, THUMB_HEIGHT);
    
    // Use a white arrow for accessory disclosure indicator.
    if (query.state == IQEQueryStateFound)
    {
        UIImage*     arrowImage         = [UIImage imageNamed:@"IQEAccessoryDisclosureArrow.png"];
        UIImageView* accessoryImageView = [[UIImageView alloc] initWithImage:arrowImage];
        
        [accessoryImageView sizeToFit];
        
        cell.accessoryView = accessoryImageView;
        
        [accessoryImageView release];
    }
    else
    {
        cell.accessoryView = nil;
    }
    
    //
    // Set thumbnail image.
    //
    
    cell.imageView.contentMode   = UIViewContentModeScaleAspectFill;
    cell.imageView.clipsToBounds = YES;
    
    if (query.type == IQEQueryTypeBarCode)
    {
        if ([query.codeType isEqualToString:IQEBarcodeTypeQRCODE])
            cell.imageView.image = [UIImage imageNamed:@"IQEQRCode.png"];
        else
        if ([query.codeType isEqualToString:IQEBarcodeTypeDATAMATRIX])
            cell.imageView.image = [UIImage imageNamed:@"IQEDataMatrix.png"];
        else
            cell.imageView.image = [UIImage imageNamed:@"IQEBarcode.png"];
    }
    else
    {
        cell.imageView.image = [UIImage imageWithContentsOfFile:[mDocumentPath stringByAppendingPathComponent:query.thumbFile]];
    }
    
    // Badge
    cell.count = (query.qidResults.count > 1) ? query.qidResults.count : 0;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        //
        // Remove image and thumbnail files. Then remove query from query history.
        //
        
        IQEQuery* query = [mQueryHistory objectAtIndex:(NSUInteger)indexPath.row];
        if (query == nil)
            return;
            
        [self removeImageFiles:query];
        
        [mQueryHistory removeObjectAtIndex:(NSUInteger)indexPath.row];
        
        if (mListDisplayMode == ListDisplayModeResult)
            mListDisplayMode = ListDisplayModeNone;
        
        [self updateView];
    }
    
    [mTableView reloadData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <UITableDelegate> implementation
// --------------------------------------------------------------------------------

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Notify delegate of item selection
    
    IQEQuery* query = [mQueryHistory objectAtIndex:(NSUInteger)indexPath.row];

    if (query.state == IQEQueryStateFound)
    {
        if ([mDelegate respondsToSelector:@selector(iqeViewController:didSelectItem:atIndex:)])
            [mDelegate iqeViewController:self didSelectItem:query atIndex:(NSUInteger)indexPath.row];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark <UIScrollViewDelegate> implementation
// --------------------------------------------------------------------------------

- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
{
    if (scrollView.dragging)
    {
        if (scrollView.contentOffset.y < - scrollView.frame.size.height / 3.0)
        {
            mListDisplayMode = ListDisplayModeNone;
            
            [self updateView];
            [self updateToolbar];
        }
    }
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark UIResponder implementation
// --------------------------------------------------------------------------------

//
// Handle touches to show or hide the history list when swiping
// up or down on the image preview.
//

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    UITouch* touch = [touches anyObject];
    if ([touch.view isEqual:mPreviewView] == NO)
        return;
    
    mStartTouchPosition = [touch locationInView:mPreviewView];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    UITouch* touch = [touches anyObject];
    if ([touch.view isEqual:mPreviewView] == NO)
        return;
    
    CGPoint currentTouchPosition = [touch locationInView:mPreviewView];
    
    if (fabsf(mStartTouchPosition.y - currentTouchPosition.y) >= SWIPE_VERT_MIN
    &&  fabsf(mStartTouchPosition.x - currentTouchPosition.x) <= SWIPE_HORIZ_MAX)
    {
        if (mStartTouchPosition.y < currentTouchPosition.y)
        {
            // Down swipe. Bring down history or result view.
            mListDisplayMode = ListDisplayModeNone;
        }
        else
        {
            // Up swipe. Bring up history list.
            mListDisplayMode = ListDisplayModeHistory;
        }
        
        [self updateView];
        [self updateToolbar];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    mStartTouchPosition = CGPointZero;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    mStartTouchPosition = CGPointZero;
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Actions
// --------------------------------------------------------------------------------

- (IBAction)onCameraButton:(id)sender
{
    // Request an image from the camera.
    // A UIImage will be returned asynchronously through IQEDelegate didCaptureStillFrame.
    
    [mIQE captureStillFrame];
    
    [self updateView];
}

- (IBAction)onCancel:(id)sender
{
    if ([mDelegate respondsToSelector:@selector(iqeViewControllerDidCancel:)])
        [mDelegate iqeViewControllerDidCancel:self];
}

- (IBAction)onHistory:(id)sender
{
    if (mListDisplayMode == ListDisplayModeHistory)
        mListDisplayMode = ListDisplayModeNone;
    else
    if (mListDisplayMode == ListDisplayModeResult)
        mListDisplayMode = ListDisplayModeHistory;
    else
    if (mListDisplayMode == ListDisplayModeNone)
        mListDisplayMode = ListDisplayModeHistory;
    
    [self updateView];
    [self updateToolbar];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Public methods
// --------------------------------------------------------------------------------

// Set key and secret pair after initialization.
- (void) setApiKey:(NSString*)key apiSecret:(NSString*)secret
{
    [mIQE setApiKey:key apiSecret:secret];
}

- (BOOL)autoDetection
{
    return mIQE.autoDetection;
}

- (void)setAutoDetection:(BOOL)detectionOn
{
    if (mIQE.autoDetection == detectionOn)
        return;

    mIQE.autoDetection = detectionOn;
    
    [self updateToolbar];
}

- (void)setHidesBackButton:(BOOL)hidden
{
    if (hidesBackButton == hidden)
        return;
    
    hidesBackButton = hidden;
    
    [self updateToolbar];
}

- (void)setLocationEnabled:(BOOL)enable
{
    if (locationEnabled == enable)
        return;
    
    locationEnabled = enable;
    
    if (mSearchType & IQESearchTypeRemoteSearch && self.locationEnabled)
        [[IQELocation location] startLocating];
    else
        [[IQELocation location] stopLocating];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark Private methods
// --------------------------------------------------------------------------------

- (void)queryTitleChange:(NSNotification*)n
{
    [self retain];
    
    IQEQuery* query = n.object;
    
    // Save new result data to data source.
    if (query.type == IQEQueryTypeRemoteObject && query.qidData)
        [mIQE updateResults:query.qidData forQID:query.qid];
    
    [mTableView reloadData];
    [self updateView];
    
    [self autorelease];
}

- (void)queryStateChange:(NSNotification*)n
{
    [self retain];
    
    IQEQuery* query = n.object;
    
    if (query.state == IQEQueryStateFound
    ||  query.state == IQEQueryStateNotFound)
    {
        //
        // Call delegate when an item is complete.
        //
        
        if ([mDelegate respondsToSelector:@selector(iqeViewController:didCompleteSearch:)])
            [mDelegate iqeViewController:self didCompleteSearch:query];
    }
    
    if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iPhoneOS_3_2)
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, query.title);

    [mTableView reloadData];
    [self updateView];

    [self autorelease];
}

- (void)updateView
{
    //
    // Preview layer.
    //
    
    CGRect layerRect = CGRectInset(mPreviewView.frame,
                                  (mPreviewView.frame.size.width  - mPreviewView.frame.size.width  * mZoom) / 2,
                                  (mPreviewView.frame.size.height - mPreviewView.frame.size.height * mZoom) / 2);
    
    mIQE.previewLayer.frame = CGRectIntegral(layerRect);
    
    //
    // History TableView.
    //
    
    // Don't scroll in result display mode.
    if (mListDisplayMode == ListDisplayModeHistory)
        mTableView.scrollEnabled = YES;
    else
    if (mListDisplayMode == ListDisplayModeResult)
        mTableView.scrollEnabled = NO;
    
    // Move history list in/out of view.
    CGRect historyRect = [self historyListRect];
    if (CGRectEqualToRect(mTableView.frame, historyRect) == NO)
    {
        if (mTableView.contentOffset.y < 0.0)
            mTableView.frame = CGRectOffset(mTableView.frame, 0.0, - mTableView.contentOffset.y);
        else
        if (mTableView.contentOffset.y > mTableView.contentSize.height - mTableView.frame.size.height)
            [mTableView setContentOffset:CGPointMake(mTableView.contentOffset.x, mTableView.contentSize.height - mTableView.frame.size.height)
                                animated:NO];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25];
        
        mTableView.frame = historyRect;
        
        [UIView commitAnimations];
        
        if (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iPhoneOS_3_2)
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    }
    
    // Edit only when displaying history. 
    if (mListDisplayMode != ListDisplayModeHistory)
        [self setEditing:NO animated:NO];
}

- (void)updateToolbar
{
    //
    // ToolBar buttons.
    //
    
    if (mToolBar)
    {
        // Back button.
        NSUInteger backButtonIndex = [mToolBar.items indexOfObject:mBackButton];
        if (self.hidesBackButton)
        {
            if (backButtonIndex != NSNotFound)
            {
                NSMutableArray* array = [NSMutableArray arrayWithArray:mToolBar.items];
                
                [array removeObjectAtIndex:backButtonIndex];
                [mToolBar setItems:array];
            }
        }
        else
        {        
            if (backButtonIndex == NSNotFound)
            {
                NSMutableArray* array = [NSMutableArray arrayWithArray:mToolBar.items];
                
                [array insertObject:mBackButton atIndex:0]; // Left position.
                [mToolBar setItems:array];
            }
        }
        
        // Show an edit button so VoiceOver users can delete.
        if (UIAccessibilityIsVoiceOverRunning != nil && UIAccessibilityIsVoiceOverRunning())
        {
            // Show edit button when history is shown.
            NSUInteger editButtonIndex = [mToolBar.items indexOfObject:self.editButtonItem];
            if (mListDisplayMode == ListDisplayModeHistory)
            {
                if (editButtonIndex == NSNotFound)
                {
                    NSUInteger historyButtonIndex = [mToolBar.items indexOfObject:mHistoryButton];
                    
                    NSUInteger index = self.hidesBackButton ? 0 : historyButtonIndex;
                    NSMutableArray* array = [NSMutableArray arrayWithArray:mToolBar.items];
                    
                    [array insertObject:self.editButtonItem atIndex:index];
                    [mToolBar setItems:array animated:YES];
                }
            }
            else
            {
                if (editButtonIndex != NSNotFound)
                {
                    NSMutableArray* array = [NSMutableArray arrayWithArray:mToolBar.items];
                    
                    [array removeObjectAtIndex:editButtonIndex];
                    [mToolBar setItems:array animated:YES];
                }
            }
        }
    }
    
    //
    // History button.
    //
    
    if (mListDisplayMode == ListDisplayModeHistory)
        [mHistoryButton setAccessibilityLabel:NSLocalizedStringFromTable(@"History off", BUNDLE_TABLE, @"")];
    else
        [mHistoryButton setAccessibilityLabel:NSLocalizedStringFromTable(@"History on",  BUNDLE_TABLE, @"")];
    
    //
    // Camera button when remote and not running automatic local detection.
    //
    
    BOOL remote =  mSearchType & IQESearchTypeRemoteSearch;
    BOOL local  = (mSearchType & IQESearchTypeObjectSearch)
                ||(mSearchType & IQESearchTypeBarCode);
    
    if (local && !remote && mIQE.autoDetection == YES)
        mCameraButton.hidden = YES;
    else
        mCameraButton.hidden = NO;
}

- (void)loadState
{
    //
    // Load persistant data from plist.
    //
    
    NSString* dataFilePath = [mDataPath stringByAppendingPathComponent:STR_DATAFILE];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:dataFilePath] == NO)
    {
        // Set default values if file doesn't exist.
        self.mQueryHistory = [NSMutableArray arrayWithCapacity:0];
    }
    else
    {
        NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:dataFilePath];
        
        NSArray* historyArray = [dict objectForKey:STR_KEY_HISTORY];
        if (historyArray)
        {
            self.mQueryHistory = [[[NSMutableArray alloc] initWithNSArray:historyArray] autorelease];
        }
    }
}

- (void)saveState
{
    //
    // Save persistant data to plist.
    //
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    [dict setObject:STR_DATAFILE_VER forKey:STR_KEY_VERSION];

    if (mQueryHistory)
    {
        NSMutableArray* historyArray = [NSMutableArray arrayWithCapacity:mQueryHistory.count];
        [mQueryHistory encodeWithNSArray:historyArray];
        
        [dict setObject:historyArray forKey:STR_KEY_HISTORY];
    }
    
    NSString* dataFilePath = [mDataPath stringByAppendingPathComponent:STR_DATAFILE];
    [dict writeToFile:dataFilePath atomically:YES];
}

- (void)processUnfinishedQueries:(BOOL)search
{
    //
    // Queries may be in an unfinished state under normal circumstances.
    // For instance, when the view is deallocated, or the app goes into the background.
    // This method will go through the query history list and restart them.
    //

    for (IQEQuery* query in mQueryHistory)
    {
        // Query type is unknown until a successful image search/detection.
        if (query.type  == IQEQueryTypeUnknown
        &&  query.state != IQEQueryStateNotFound)
        {
            if (mSearchType & IQESearchTypeRemoteSearch)
            {
                // Remote search disconnects from server when in the background.
                
                if ((query.state == IQEQueryStateUploading
                ||   query.state == IQEQueryStateNetworkProblem))
                {
                    //
                    // Image may not have made it to the server. Try again.
                    //
                    
                    NSString* imagePath = [mDocumentPath stringByAppendingPathComponent:query.imageFile];
                    UIImage*  image     = [UIImage imageWithContentsOfFile:imagePath];
                    
                    if (image)
                        [self startSearchForQuery:query withImage:image];
                }
                else
                if ((query.state == IQEQueryStateSearching
                ||   query.state == IQEQueryStateNotReady))
                {
                    //
                    // Results may be available if the app was closed
                    // before getting the results, so check for them.
                    //
                    
                    [mIQE searchWithQID:query.qid];
                }
            }
            else
            if (mSearchType & IQESearchTypeObjectSearch
            ||  mSearchType & IQESearchTypeBarCode)
            {
                if (search)
                {
                    //
                    // Resubmit image when initial search for this item is no longer running.
                    //
                    
                    NSString* imagePath = [mDocumentPath stringByAppendingPathComponent:query.imageFile];
                    UIImage*  image     = [UIImage imageWithContentsOfFile:imagePath];
                    
                    if (image)
                        [self startSearchForQuery:query withImage:image];
                }
            }
        }
    }
}

- (CGRect)historyListRect
{
    CGRect  rect;
    CGFloat historyHeight = MIN(mQueryHistory.count, MAX_DISPLAYCELLS) * CELL_HEIGHT;
    
    if (mListDisplayMode == ListDisplayModeHistory)
    {
        mTableView.scrollEnabled = YES;
        rect = CGRectMake(0, mPreviewView.frame.size.height - historyHeight, mPreviewView.frame.size.width, historyHeight);
    }
    else
    if (mListDisplayMode == ListDisplayModeResult)
    {
        mTableView.scrollEnabled = NO;
        rect = CGRectMake(0, mPreviewView.frame.size.height - CELL_HEIGHT, mPreviewView.frame.size.width, CELL_HEIGHT);   
    }
    else
    if (mListDisplayMode == ListDisplayModeNone)
    {
        rect = CGRectMake(0, mPreviewView.frame.size.height, mPreviewView.frame.size.width, 0);
    }
    
    return rect;
}

- (CGSize)thumbSize
{
    CGFloat screenScale = 1.0;
    
    // Retina display.
    if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)])
        screenScale = [UIScreen mainScreen].scale;
    
    return CGSizeMake(THUMB_WIDTH * screenScale, THUMB_HEIGHT * screenScale);
}

- (void)startSearchForQuery:(IQEQuery*)query withImage:(UIImage*)image
{
    // Reset state of query for all search types when doing a new search.
    if (mSearchType & IQESearchTypeBarCode      && self.autoDetection == NO) [query setState:IQEQueryStateUnknown forType:IQEQueryTypeBarCode];
    if (mSearchType & IQESearchTypeObjectSearch && self.autoDetection == NO) [query setState:IQEQueryStateUnknown forType:IQEQueryTypeLocalObject];
    if (mSearchType & IQESearchTypeRemoteSearch)                             [query setState:IQEQueryStateUnknown forType:IQEQueryTypeRemoteObject];
    
    //
    // Start image search/detection. The result will be returned via the IQEDelegate protocol.
    //
    
    NSString* qid = [mIQE searchWithImage:image atLocation:[IQELocation location].coordinates];
    
    if (qid)
    {
        query.qid = qid;
        
        if (mSearchType & IQESearchTypeRemoteSearch)
            query.state = IQEQueryStateUploading;
        else
            query.state = IQEQueryStateSearching;
    }
    else
    {
        query.state = IQEQueryStateNotFound;
        query.type  = IQEQueryTypeUnknown;
    }
}

- (void)saveImageFiles:(IQEQuery*)query forImage:(UIImage*)image
{
    // Save image as a jpg in the iqe data directory.
    // Also create and save a thumbnail suffixed with "thumb".
    // Update query object with the location of image files.
    
    NSString* uniqueName = [UIImage uniqueName];
    NSString* imageName  = [NSString stringWithFormat:@"%@.jpg",      uniqueName];
    NSString* thumbName  = [NSString stringWithFormat:@"%@thumb.jpg", uniqueName];
    
    // /.../Documents/iqe/*.jpg
    [image saveAsJPEGinDirectory:mDataPath withName:imageName];
    [image saveAsJPEGinDirectory:mDataPath withName:thumbName size:[self thumbSize]];
    
    // iqe/*.jpg
    query.imageFile = [STR_DATADIR stringByAppendingPathComponent:imageName];
    query.thumbFile = [STR_DATADIR stringByAppendingPathComponent:thumbName];
}

- (void)removeImageFiles:(IQEQuery*)query
{
    NSString* imagePath = [mDocumentPath stringByAppendingPathComponent:query.imageFile];
    NSString* thumbPath = [mDocumentPath stringByAppendingPathComponent:query.thumbFile];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    if (query.imageFile && ![query.imageFile isEqualToString:@""]) 
        [fileManager removeItemAtPath:imagePath error:nil];
    
    if (query.thumbFile && ![query.thumbFile isEqualToString:@""])
        [fileManager removeItemAtPath:thumbPath error:nil];
    
    query.imageFile = nil;
    query.thumbFile = nil;
}

@end

// --------------------------------------------------------------------------------
