// AKTab.m
//
// Copyright (c) 2012 Ali Karagoz (http://alikaragoz.net)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AKTab.h"

// cross fade animation duration.
static const float kAnimationDuration = 0.15;

// Padding of the content
static const float kPadding = 4.0;

// Margin between the image and the title
static const float kMargin = 2.0;

// Margin at the top
static const float kTopMargin = 2.0;

@interface AKTab ()

// Permits the cross fade animation between the two images, duration in seconds.
- (void)animateContentWithDuration:(CFTimeInterval)duration;

@end

@implementation AKTab
{
    BOOL isTabIconPresent;
    BOOL isSelectedTabIconPresent;
}

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.backgroundColor = [UIColor clearColor];
        _titleIsHidden = NO;
        isTabIconPresent = NO;
        isSelectedTabIconPresent = NO;
    }
    return self;
}

#pragma mark - Touche handeling

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self animateContentWithDuration:kAnimationDuration];
}

#pragma mark - Animation

- (void)animateContentWithDuration:(CFTimeInterval)duration
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"contents"];
    animation.duration = duration;
    [self.layer addAnimation:animation forKey:@"contents"];
    [self setNeedsDisplay];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    // If the height of the container is too short, we do not display the title
    CGFloat offset = 1.0;
    
    if (_tabImageWithName) isTabIconPresent = YES;
    if (_selectedTabImageWithName) isSelectedTabIconPresent = YES;

    if (!_minimumHeightToDisplayTitle)
        _minimumHeightToDisplayTitle = _tabBarHeight - offset;
    
    BOOL displayTabTitle = (CGRectGetHeight(rect) + offset >= _minimumHeightToDisplayTitle) ? YES : NO;
    if (!isTabIconPresent) displayTabTitle = YES;
    if (_titleIsHidden) displayTabTitle = NO;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // Container, basically centered in rect
    CGRect container = CGRectInset(rect, kPadding, kPadding);
    container.size.height -= kTopMargin;
    container.origin.y += kTopMargin;
    
    UIImage *image;
    CGRect imageRect = CGRectZero;
    CGFloat ratio = 0;

    if (self.selected && isSelectedTabIconPresent) {
        // Tab's image
        image = [UIImage imageNamed:_selectedTabImageWithName];
        
        // Getting the ratio for eventual scaling
        ratio = image.size.width / image.size.height;
        
        // Setting the imageContainer's size.
        imageRect.size = image.size;
    } else if (isTabIconPresent) {
        // Tab's image
        image = [UIImage imageNamed:_tabImageWithName];

        // Getting the ratio for eventual scaling
        ratio = image.size.width / image.size.height;

        // Setting the imageContainer's size.
        imageRect.size = image.size;
    }
    
    // Title label
    UILabel *tabTitleLabel = [[UILabel alloc] init];
    tabTitleLabel.text = _tabTitle;
    tabTitleLabel.font = self.tabTitleFont ?: [UIFont fontWithName:@"Helvetica-Bold" size:11.0];
    
    CGSize labelSize = [tabTitleLabel.text sizeWithFont:tabTitleLabel.font forWidth:CGRectGetWidth(rect) lineBreakMode: NSLineBreakByTruncatingMiddle ];
    
    CGRect labelRect = CGRectZero;
    
    labelRect.size.height = (displayTabTitle) ? labelSize.height : 0;
    
    // Container of the image + label (when there is room)
    CGRect content = CGRectZero;
    content.size.width = CGRectGetWidth(container);
    
    // We determine the height based on the longest side of the image (when not square) , presence of the label and height of the container
    content.size.height = MIN(MAX(CGRectGetWidth(imageRect), CGRectGetHeight(imageRect)) + ((displayTabTitle) ? (kMargin + CGRectGetHeight(labelRect)) : 0), CGRectGetHeight(container));
    
    // Now we move the boxes
    content.origin.x = floorf(CGRectGetMidX(container) - CGRectGetWidth(content) / 2);
    content.origin.y = floorf(CGRectGetMidY(container) - CGRectGetHeight(content) / 2);
    
    labelRect.size.width = CGRectGetWidth(content);
    labelRect.origin.x = CGRectGetMinX(content);
    labelRect.origin.y = CGRectGetMaxY(content) - CGRectGetHeight(labelRect);
    
    if (!displayTabTitle)
        labelRect = CGRectZero;
    
    if (isTabIconPresent)
    {
        CGRect imageContainer = content;
        imageContainer.size.height = CGRectGetHeight(content) - ((displayTabTitle) ? (kMargin + CGRectGetHeight(labelRect)) : 0);
        
        imageRect.size.width = CGRectGetWidth(imageRect) / 2;
        imageRect.size.height = CGRectGetHeight(imageRect) / 2;
        imageRect.origin.x = floorf(CGRectGetMidX(content) - CGRectGetWidth(imageRect) / 2);
        imageRect.origin.y = floorf(CGRectGetMidY(imageContainer) - CGRectGetHeight(imageRect) / 2);
    }

    CGFloat offsetY = rect.size.height - ((displayTabTitle) ? (kMargin + CGRectGetHeight(labelRect)) : 0) + kTopMargin;
    
    if (isTabIconPresent) {
        CGContextSaveGState(ctx);
        {
            CGContextTranslateCTM(ctx, 0.0, offsetY);
            CGContextScaleCTM(ctx, 1.0, -1.0);
            CGContextDrawImage(ctx, imageRect, image.CGImage);
        }
        CGContextRestoreGState(ctx);
    }
    
    if (displayTabTitle) {
        CGContextSaveGState(ctx);
        {
            UIColor *textColor = [UIColor colorWithRed:0.961 green:0.961 blue:0.961 alpha:1.0];
            CGContextSetFillColorWithColor(ctx, _textColor ? _textColor.CGColor : textColor.CGColor);
            CGContextSetShadow(ctx, CGSizeMake(1, 1), 0.0f);
            [tabTitleLabel.text drawInRect:labelRect withFont:tabTitleLabel.font lineBreakMode:NSLineBreakByTruncatingMiddle  alignment:UITextAlignmentCenter];
        }
        CGContextRestoreGState(ctx);
    }
}
@end