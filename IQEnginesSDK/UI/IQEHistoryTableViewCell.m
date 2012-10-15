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
//  IQEHistoryTableViewCell.m
//
// --------------------------------------------------------------------------------

#import <QuartzCore/QuartzCore.h>
#import "IQEHistoryTableViewCell.h"
#import "IQEBadgeView.h"

#define CELL_MARGIN 4

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEHistoryTableViewCell private interface
// --------------------------------------------------------------------------------

@interface IQEHistoryTableViewCell ()
@property(nonatomic, retain) IQEBadgeView* mBadgeView;
@end

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEHistoryTableViewCell implementation
// --------------------------------------------------------------------------------

@implementation IQEHistoryTableViewCell

@synthesize imageViewSize;
@synthesize count;
@synthesize mBadgeView;

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEHistoryTableViewCell lifecycle
// --------------------------------------------------------------------------------

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self)
    {
        count         = 0;
        imageViewSize = CGSizeZero;
        
        self.imageView.layer.cornerRadius = 3.0;
        
        mBadgeView = [[IQEBadgeView alloc] init];
        [self addSubview:mBadgeView];
    }
    return self;
}

- (void)dealloc
{
    [mBadgeView release];
    
    [super dealloc];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark UIView
// --------------------------------------------------------------------------------

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // Positon badge view.
    [mBadgeView sizeToFit];
    mBadgeView.frame = CGRectMake(0.0,
                                  ceilf((self.frame.size.height - mBadgeView.frame.size.height) / 2.0),
                                  mBadgeView.frame.size.width,
                                  mBadgeView.frame.size.height);
    
    if (mBadgeView.value == 0)
        mBadgeView.frame = CGRectZero;    
    
    if (CGSizeEqualToSize(imageViewSize, CGSizeZero))
         imageViewSize = self.imageView.frame.size;
        
    self.imageView.frame = CGRectMake(CELL_MARGIN,
                                      ceilf((self.frame.size.height - imageViewSize.height) / 2.0),
                                      imageViewSize.width,
                                      imageViewSize.height);
    
    CGFloat textLabelX = self.imageView.frame.origin.x + self.imageView.frame.size.width + CELL_MARGIN + CELL_MARGIN;
    CGFloat textLabelW = self.accessoryView ? self.accessoryView.frame.origin.x - textLabelX - CELL_MARGIN
                                            : self.frame.size.width             - textLabelX - CELL_MARGIN;
    
    // Shrink textLabel width if there is a badge.
    textLabelW -= mBadgeView.frame.size.width + CELL_MARGIN;
    
    // Position badge horizontally.
    mBadgeView.frame = CGRectOffset(mBadgeView.frame, CELL_MARGIN + textLabelX + textLabelW, 0.0);
    
    self.textLabel.frame = CGRectMake(textLabelX,
                                      self.textLabel.frame.origin.y,
                                      textLabelW,
                                      self.textLabel.frame.size.height);
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark UITableViewCell
// --------------------------------------------------------------------------------

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEHistoryTableViewCell public methods
// --------------------------------------------------------------------------------

- (void) setCount:(NSUInteger)aCount
{
    mBadgeView.value = aCount;
}

@end

// --------------------------------------------------------------------------------
