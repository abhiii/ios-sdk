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
//  IQEBadgeView.m
//
// --------------------------------------------------------------------------------

#import "IQEBadgeView.h"

#define BADGE_TEXTBORDER 2.0
#define BADGE_BORDER     0.0
#define BADGE_FONTSIZE   14.0
#define BADGE_COLOR      colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEBadgeView Private interface
// --------------------------------------------------------------------------------

@interface IQEBadgeView ()
- (void)   pathAddOval:(CGMutablePathRef)path inRect:(CGRect)rect;
- (CGSize) pathSizeForString:(NSString*)string;
@property(nonatomic, retain) UIColor* mFillColor;
@property(nonatomic, retain) UIColor* mStrokeColor;
@property(nonatomic, retain) UIColor* mTextColor;
@property(nonatomic, retain) UIFont*  mFont;
@property(nonatomic, assign) CGFloat  mBorderWidth;
@end

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEBadgeView implementation
// --------------------------------------------------------------------------------

@implementation IQEBadgeView

@synthesize value;
@synthesize mFillColor;
@synthesize mStrokeColor;
@synthesize mTextColor;
@synthesize mFont;
@synthesize mBorderWidth;

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEBadgeView lifecycle
// --------------------------------------------------------------------------------

- (void)initIQEBadgeView
{
    self.backgroundColor = [UIColor clearColor];
    self.opaque          = NO;
    
    self.mBorderWidth    = BADGE_BORDER;
    self.mFont           = [UIFont boldSystemFontOfSize:BADGE_FONTSIZE];
    self.mFillColor      = [UIColor BADGE_COLOR];
    self.mStrokeColor    = [UIColor whiteColor];
    self.mTextColor      = [UIColor whiteColor];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    [self initIQEBadgeView];
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];
    [self initIQEBadgeView];    
    return self;
}

- (void)dealloc
{
    [mFont        release];
    [mFillColor   release];
    [mStrokeColor release];
    [mTextColor   release];
    
    [super dealloc];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark UIView
// --------------------------------------------------------------------------------

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    NSString* valueString = [NSString stringWithFormat:@"%d", self.value];
    
    CGSize  pathSize    = [self pathSizeForString:valueString];
    CGRect  badgeRect   = CGRectMake(0.0, 0.0, pathSize.width, pathSize.height);    
    CGPoint originPoint = CGPointMake(ceilf((self.frame.size.width  - badgeRect.size.width)  / 2.0),
                                      ceilf((self.frame.size.height - badgeRect.size.height) / 2.0));
    
    //
    // Oval
    //
    
    CGContextSaveGState(context);
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    [self pathAddOval:path inRect:badgeRect];
    
    CGContextTranslateCTM(context, originPoint.x, originPoint.y);
    
    CGContextSetLineWidth(context, mBorderWidth);
    CGContextSetFillColorWithColor(context,   mFillColor.CGColor);
    CGContextSetStrokeColorWithColor(context, mStrokeColor.CGColor);
    
    CGContextBeginPath(context);
    CGContextAddPath(context, path);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    //
    // Shine
    //
    
    if (0)
    {
        // Clip path
        CGContextBeginPath(context);
        CGContextAddPath(context, path);
        CGContextClosePath(context);
        CGContextClip(context);

        CGContextSaveGState(context);

        CGFloat components[8] = { 1.0, 1.0, 1.0, 0.7,   // Start color
                                  1.0, 1.0, 1.0, 0.0 }; // End color
        
        CGColorSpaceRef rgbColorspace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef   gradient      = CGGradientCreateWithColorComponents(rgbColorspace, components, nil, 2);
        
        CGPoint startPoint = CGPointMake(0.0, 0.0);
        CGPoint endPoint   = CGPointMake(0.0, self.bounds.size.height * 0.40);
        
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
        
        CGContextRestoreGState(context);

        CGGradientRelease(gradient);
        CGColorSpaceRelease(rgbColorspace);    
    }
    
    CGContextRestoreGState(context);
    CGPathRelease(path);
    
    //
    // Text
    //
    
    CGContextSaveGState(context);
    
    CGContextSetFillColorWithColor(context, mTextColor.CGColor);
    
    CGSize  textSize  = [valueString sizeWithFont:self.mFont];
    CGPoint textPoint = CGPointMake(originPoint.x + floorf((badgeRect.size.width  - textSize.width)  / 2.0),
                                    originPoint.y + floorf((badgeRect.size.height - textSize.height) / 2.0));
        
    [valueString drawAtPoint:textPoint withFont:self.mFont];
    
    CGContextRestoreGState(context);
}

- (CGSize)sizeThatFits:(CGSize)size
{
    NSString* string = [NSString stringWithFormat:@"%d", self.value];
    
    CGSize pathSize  = [self pathSizeForString:string];
    CGRect badgeRect = CGRectMake(0, 0, pathSize.width, pathSize.height);

    // Adjust badgeRect for border width, 1/2 border on each side of path + 1 pix border.
    badgeRect = CGRectInset(badgeRect, - (mBorderWidth / 2.0 + 1.0),
                                       - (mBorderWidth / 2.0 + 1.0));
    
    return badgeRect.size;
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEBadgeView Public methods
// --------------------------------------------------------------------------------

- (void)setValue:(NSUInteger)newValue
{
    value = newValue;
    
    [self setNeedsDisplay];
}

// --------------------------------------------------------------------------------
#pragma mark -
#pragma mark IQEBadgeView Private methods
// --------------------------------------------------------------------------------

- (void)pathAddOval:(CGMutablePathRef)path inRect:(CGRect)rect
{
    CGFloat radius = rect.size.height / 2.0;
    
    CGPathAddArc(path,
                 NULL,
                 rect.size.width - radius,
                 radius,
                 radius,
                 M_PI_2,
                 M_PI_2 * 3.0,
                 YES);
    
    CGPathAddArc(path,
                 NULL,
                 radius,
                 radius,
                 radius,
                 M_PI_2 * 3.0,
                 M_PI_2,
                 YES);
}

- (CGSize)pathSizeForString:(NSString*)string
{
    CGSize textSize = [string sizeWithFont:self.mFont];
    
    textSize.width  += BADGE_TEXTBORDER * 2;
    textSize.height += BADGE_TEXTBORDER * 2;
    
    textSize.width = MAX(textSize.height * 1.5, textSize.width + textSize.height / 2.0);
    
    return CGSizeMake(textSize.width, textSize.height);
}

@end

// --------------------------------------------------------------------------------
