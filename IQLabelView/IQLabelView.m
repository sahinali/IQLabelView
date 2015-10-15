//
//  IQLabelView.m
//  Created by kcandr on 17/12/14.

#import "IQLabelView.h"
#import <QuartzCore/QuartzCore.h>
#import "UITextField+DynamicFontSize.h"
#import "KPFontPicker.h"

CG_INLINE CGPoint CGRectGetCenter(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

CG_INLINE CGRect CGRectScale(CGRect rect, CGFloat wScale, CGFloat hScale)
{
    return CGRectMake(rect.origin.x * wScale, rect.origin.y * hScale, rect.size.width * wScale, rect.size.height * hScale);
}

CG_INLINE CGFloat CGPointGetDistance(CGPoint point1, CGPoint point2)
{
    //Saving Variables.
    CGFloat fx = (point2.x - point1.x);
    CGFloat fy = (point2.y - point1.y);
    
    return sqrt((fx*fx + fy*fy));
}

CG_INLINE CGFloat CGAffineTransformGetAngle(CGAffineTransform t)
{
    return atan2(t.b, t.a);
}


CG_INLINE CGSize CGAffineTransformGetScale(CGAffineTransform t)
{
    return CGSizeMake(sqrt(t.a * t.a + t.c * t.c), sqrt(t.b * t.b + t.d * t.d)) ;
}

static IQLabelView *lastTouchedView;

@implementation IQLabelView
{
    CGFloat globalInset;
    
    CGRect initialBounds;
    CGFloat initialDistance;
    
    CGPoint beginningPoint;
    CGPoint beginningCenter;
    
    CGPoint prevPoint;
    CGPoint touchLocation;
    
    CGFloat deltaAngle;
    
    CGAffineTransform startTransform;
    CGRect beginBounds;
    
    CAShapeLayer *border;
}

@synthesize textColor = textColor, borderColor = borderColor;
@synthesize fontName = fontName, apiFontSize = apiFontSize;
@synthesize enableClose = enableClose, enableRotate = enableRotate;
@synthesize delegate = delegate;
@synthesize showContentShadow = showContentShadow;
@synthesize closeImage = closeImage, rotateImage = rotateImage;

- (void)refresh
{
    if (self.superview) {
        CGSize scale = CGAffineTransformGetScale(self.superview.transform);
        CGAffineTransform t = CGAffineTransformMakeScale(scale.width, scale.height);
        [closeView setTransform:CGAffineTransformInvert(t)];
        [rotateView setTransform:CGAffineTransformInvert(t)];
        
        if (isShowingEditingHandles) {
            [_textView.layer addSublayer:border];
        } else {
            [border removeFromSuperlayer];
        }
    }
}

-(void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self refresh];
}

- (void)setFrame:(CGRect)newFrame
{
    [super setFrame:newFrame];
    [self refresh];
}

- (id)initWithFrame:(CGRect)frame
{
    if (frame.size.width < (1+12*2))     frame.size.width = 25;
    if (frame.size.height < (1+12*2))    frame.size.height = 25;
    
    self = [super initWithFrame:frame];
    if (self) {
        globalInset = 12;
        
        self.backgroundColor = [UIColor clearColor];
        borderColor = [UIColor redColor];
        
        //Close button view which is in top left corner
        closeView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, globalInset*2, globalInset*2)];
        [closeView setAutoresizingMask:(UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleBottomMargin)];
        closeView.backgroundColor = [UIColor whiteColor];
        closeView.layer.cornerRadius = globalInset - 5;
        closeView.userInteractionEnabled = YES;
        [self addSubview:closeView];
     
        rotateView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width-globalInset*2, self.bounds.size.height-globalInset*2, globalInset*2, globalInset*2)];
        [rotateView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleTopMargin)];
        rotateView.backgroundColor = [UIColor whiteColor];
        rotateView.layer.cornerRadius = globalInset - 5;
        rotateView.contentMode = UIViewContentModeCenter;
        rotateView.userInteractionEnabled = YES;
        [self addSubview:rotateView];
        
        UIPanGestureRecognizer *moveGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveGesture:)];
        [self addGestureRecognizer:moveGesture];
        
        UITapGestureRecognizer *singleTapShowHide = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentTapped:)];
        [self addGestureRecognizer:singleTapShowHide];
        
        UITapGestureRecognizer *closeTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeTap:)];
        [closeView addGestureRecognizer:closeTap];
        
        UIPanGestureRecognizer *panRotateGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(rotateViewPanGesture:)];
        [rotateView addGestureRecognizer:panRotateGesture];
        
        [moveGesture requireGestureRecognizerToFail:closeTap];
        
        [self setEnableClose:YES];
        [self setEnableRotate:YES];
        [self setShowContentShadow:YES];
        [self setCloseImage:[UIImage imageNamed:@"IQLabelView.bundle/sticker_close.png"]];
        [self setRotateImage:[UIImage imageNamed:@"IQLabelView.bundle/sticker_resize.png"]];
        

        NSArray *fonts = @[ @"MICKEY", @"Minnie",@"DK Petit Four", @"orange juice" ];
        
        self.picker = [[KPFontPicker alloc] initWithFonts:fonts];
        self.picker.delegate = self;
        
        [self showEditingHandles];
    }
    return self;
}



- (void)layoutSubviews
{
    if (_textView) {
        border.path = [UIBezierPath bezierPathWithRect:_textView.bounds].CGPath;
        border.frame = _textView.bounds;
    }
}

#pragma mark - Set Control Buttons

- (void)setEnableClose:(BOOL)value
{
    enableClose = value;
    [closeView setHidden:!enableClose];
    [closeView setUserInteractionEnabled:enableClose];
}

- (void)setEnableRotate:(BOOL)value
{
    enableRotate = value;
    [rotateView setHidden:!enableRotate];
    [rotateView setUserInteractionEnabled:enableRotate];
}

- (void)setShowContentShadow:(BOOL)showShadow
{
    showContentShadow = showShadow;
    
    if (showContentShadow) {
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOffset:CGSizeMake(0, 5)];
        [self.layer setShadowOpacity:1.0];
        [self.layer setShadowRadius:4.0];
    } else {
        [self.layer setShadowColor:[UIColor clearColor].CGColor];
        [self.layer setShadowOffset:CGSizeZero];
        [self.layer setShadowOpacity:0.0];
        [self.layer setShadowRadius:0.0];
    }
}

- (void)setCloseImage:(UIImage *)image
{
    closeImage = image;
    [closeView setImage:closeImage];
}

- (void)setRotateImage:(UIImage *)image
{
    rotateImage = image;
    [rotateView setImage:rotateImage];
}

#pragma mark - Set Text Field

- (void)setTextField:(UITextView *)field
{
    [_textView removeFromSuperview];
    
    _textView = field;
    
    _textView.frame = CGRectInset(self.bounds, globalInset, globalInset);
    
    [_textView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight)];
   
    _textView.backgroundColor = [UIColor clearColor];
    _textView.tintColor = [UIColor redColor];
    [_textView becomeFirstResponder];
    
    border = [CAShapeLayer layer];
    border.strokeColor = borderColor.CGColor;
    border.fillColor = nil;
    border.lineDashPattern = @[@4, @3];
    
    
    _textView.delegate = self;
    _textView.inputAccessoryView = [self createToolbar];
    
    
    [self insertSubview:_textView atIndex:0];
    
}



#pragma mark - KPFontpicker Delegate
- (void)pickerDidSelectFont:(NSString *)font withSize:(CGFloat)fontSize color:(UIColor *)fontColor
{
    _textView.font = [UIFont fontWithName:font size:fontSize];
    _textView.textColor = fontColor;
//    [self textViewDidChange:textView];
    //[_textView adjustsWidthToFillItsContents];
}

// Optional delegate
- (void)pickerDidSelectFontColor:(UIColor *)fontColor
{
    NSLog(@"Color selected %@", fontColor);
}

#pragma mark - Toolbar
- (UIToolbar *)createToolbar
{
    UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
    keyboardDoneButtonView.barTintColor = [UIColor darkGrayColor];
    keyboardDoneButtonView.tintColor = [UIColor whiteColor];
    [keyboardDoneButtonView sizeToFit];
    
    UIBarButtonItem *keyboardButton = [[UIBarButtonItem alloc] initWithTitle:@"Keyboard"
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(keyboardClicked:)];
    
    UIBarButtonItem *fontButton = [[UIBarButtonItem alloc] initWithTitle:@"Font"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(pickerClicked:)];
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneClicked:)];
    
    [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:keyboardButton, fontButton, flex, doneButton, nil]];
    
    return keyboardDoneButtonView;
}

#pragma mark - Toolbar actions
- (IBAction)keyboardClicked:(id)sender
{
    if ([_textView isFirstResponder]) {
        _textView.inputView = nil;
        
        [_textView reloadInputViews];
    }
}

- (IBAction)pickerClicked:(id)sender
{
    if ([_textView isFirstResponder]) {
        _textView.inputView = self.picker;
        [_textView reloadInputViews];
        [self.picker setPickerText:_textView.text];

    }
}

- (IBAction)doneClicked:(id)sender
{
    if ([_textView isFirstResponder]) {
        _textView.inputView = nil;
        
        [_textView resignFirstResponder];
    }
}



- (void)setFontName:(NSString *)name
{
    fontName = name;
    _textView.font = [UIFont fontWithName:fontName size:apiFontSize];
  // [_textView adjustsWidthToFillItsContents];
}

-(UIViewController*)findViewControllerWithView:(UIView*)view{
    
    UIResponder *responder = view;
    
    while ((responder = responder.nextResponder) != nil) {
        
        if([responder isKindOfClass:[UIViewController class]]){
            
            break;
        }
        
    }
    
    return (UIViewController*)responder;
}


- (void)setFontSize:(CGFloat)size
{
    apiFontSize = size;
    if (fontName!= nil) {
        _textView.font = [UIFont fontWithName:fontName size:apiFontSize];
    }
    
}

- (void)setTextColor:(UIColor *)color
{
    textColor = color;
    _textView.textColor = textColor;
}

- (void)setBorderColor:(UIColor *)color
{
    borderColor = color;
    border.strokeColor = borderColor.CGColor;
}

- (void)setTextAlpha:(CGFloat)alpha
{
    _textView.alpha = alpha;
}

- (CGFloat)textAlpha
{
    return _textView.alpha;
}

#pragma mark - Bounds

- (void)hideEditingHandles
{
    lastTouchedView = nil;
    
    isShowingEditingHandles = NO;
    
    if (_textView) {
        if (enableClose)       closeView.hidden = YES;
        if (enableRotate)      rotateView.hidden = YES;
        
        
        [_textView resignFirstResponder];
        
        
        [self refresh];
        if([delegate respondsToSelector:@selector(labelViewDidHideEditingHandles:)]) {
            [delegate labelViewDidHideEditingHandles:self];
            
        }
        
        
        
        
    }
}

- (void)showEditingHandles
{
    [lastTouchedView hideEditingHandles];
    
    isShowingEditingHandles = YES;
    
    lastTouchedView = self;
    
    if (enableClose)       closeView.hidden = NO;
    if (enableRotate)      rotateView.hidden = NO;
    
    [self refresh];
    
    [self.picker setPickerText:_textView.text];
    
    if([delegate respondsToSelector:@selector(labelViewDidShowEditingHandles:)]) {
        [delegate labelViewDidShowEditingHandles:self];
    }
}

#pragma mark - Gestures

- (void)contentTapped:(UITapGestureRecognizer*)tapGesture
{
    if (isShowingEditingHandles) {
        [self hideEditingHandles];
        [self.superview bringSubviewToFront:self];
    } else {
        [self showEditingHandles];
    }
}

- (void)closeTap:(UITapGestureRecognizer *)recognizer
{
    [self removeFromSuperview];
    
    if([delegate respondsToSelector:@selector(labelViewDidClose:)]) {
        [delegate labelViewDidClose:self];
    }
}

-(void)moveGesture:(UIPanGestureRecognizer *)recognizer
{
    if (!isShowingEditingHandles) {
        [self showEditingHandles];
    }
    touchLocation = [recognizer locationInView:self.superview];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        beginningPoint = touchLocation;
        beginningCenter = self.center;
        
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        
        beginBounds = self.bounds;
        
        if([delegate respondsToSelector:@selector(labelViewDidBeginEditing:)]) {
            [delegate labelViewDidBeginEditing:self];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        
        if([delegate respondsToSelector:@selector(labelViewDidChangeEditing:)]) {
            [delegate labelViewDidChangeEditing:self];
        }
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self setCenter:CGPointMake(beginningCenter.x+(touchLocation.x-beginningPoint.x), beginningCenter.y+(touchLocation.y-beginningPoint.y))];
        
        if([delegate respondsToSelector:@selector(labelViewDidEndEditing:)]) {
            [delegate labelViewDidEndEditing:self];
        }
    }
    
    prevPoint = touchLocation;
}

- (void)rotateViewPanGesture:(UIPanGestureRecognizer *)recognizer
{
    touchLocation = [recognizer locationInView:self.superview];
    
    CGPoint center = CGRectGetCenter(self.frame);
    
    if ([recognizer state] == UIGestureRecognizerStateBegan) {
        deltaAngle = atan2(touchLocation.y-center.y, touchLocation.x-center.x)-CGAffineTransformGetAngle(self.transform);
        
        initialBounds = self.bounds;
        initialDistance = CGPointGetDistance(center, touchLocation);
        
        if([delegate respondsToSelector:@selector(labelViewDidBeginEditing:)]) {
            [delegate labelViewDidBeginEditing:self];
        }
    } else if ([recognizer state] == UIGestureRecognizerStateChanged) {
        float ang = atan2(touchLocation.y-center.y, touchLocation.x-center.x);
        
        float angleDiff = deltaAngle - ang;
        [self setTransform:CGAffineTransformMakeRotation(-angleDiff)];
        [self setNeedsDisplay];
        
        //Finding scale between current touchPoint and previous touchPoint
        double scale = sqrtf(CGPointGetDistance(center, touchLocation)/initialDistance);
        
        CGRect scaleRect = CGRectScale(initialBounds, scale, scale);
        
        if (scaleRect.size.width >= (1+globalInset*2 + 20) && scaleRect.size.height >= (1+globalInset*2 + 20)) {
            if (apiFontSize < 100 || CGRectGetWidth(scaleRect) < CGRectGetWidth(self.bounds)) {
                [_textView adjustsFontSizeToFillRect:scaleRect];
               // [_textView adjustsWidthToFillItsContents];
                [self setBounds:scaleRect];
            }
        }
        
        if([delegate respondsToSelector:@selector(labelViewDidChangeEditing:)]) {
            [delegate labelViewDidChangeEditing:self];
        }
    } else if ([recognizer state] == UIGestureRecognizerStateEnded) {
        if([delegate respondsToSelector:@selector(labelViewDidEndEditing:)]) {
            [delegate labelViewDidEndEditing:self];
        }
    }
}


//- (void)pinchViewPanGesture:(UIPinchGestureRecognizer*)recognizer
//{
//    touchLocation = [recognizer locationInView:self.superview];
//    
//    CGPoint center = CGRectGetCenter(self.frame);
//    
//    if ([recognizer state] == UIGestureRecognizerStateBegan) {
//        deltaAngle = atan2(touchLocation.y-center.y, touchLocation.x-center.x)-CGAffineTransformGetAngle(self.transform);
//        
//        initialBounds = self.bounds;
//        initialDistance = CGPointGetDistance(center, touchLocation);
//        
//        if([delegate respondsToSelector:@selector(labelViewDidBeginEditing:)]) {
//            [delegate labelViewDidBeginEditing:self];
//        }
//    } else if ([recognizer state] == UIGestureRecognizerStateChanged) {
//        float ang = atan2(touchLocation.y-center.y, touchLocation.x-center.x);
//        
//        float angleDiff = deltaAngle - ang;
////        [self setTransform:CGAffineTransformMakeRotation(-angleDiff)];
////        [self setNeedsDisplay];
//        
//        //Finding scale between current touchPoint and previous touchPoint
//        double scale = sqrtf(CGPointGetDistance(center, touchLocation)/initialDistance);
//        
//        CGRect scaleRect = CGRectScale(initialBounds, scale, scale);
//        
//        if (scaleRect.size.width >= (1+globalInset*2 + 20) && scaleRect.size.height >= (1+globalInset*2 + 20)) {
//            if (apiFontSize < 100 || CGRectGetWidth(scaleRect) < CGRectGetWidth(self.bounds)) {
//                [_textView adjustsFontSizeToFillRect:scaleRect];
//                // [_textView adjustsWidthToFillItsContents];
//                [self setBounds:scaleRect];
//            }
//        }
//        
//        if([delegate respondsToSelector:@selector(labelViewDidChangeEditing:)]) {
//            [delegate labelViewDidChangeEditing:self];
//        }
//    } else if ([recognizer state] == UIGestureRecognizerStateEnded) {
//        if([delegate respondsToSelector:@selector(labelViewDidEndEditing:)]) {
//            [delegate labelViewDidEndEditing:self];
//        }
//    }
//}

#pragma mark - UITextField Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textField
{
    if (isShowingEditingHandles) {
        return YES;
    }
    [self contentTapped:nil];
    return NO;
}

- (void)textViewDidBeginEditing:(UITextView *)textField
{
    if([delegate respondsToSelector:@selector(labelViewDidStartEditing:)]) {
         [self.picker setPickerText:_textView.text];
        [delegate labelViewDidStartEditing:self];
    }
    
    [_textView adjustsFontSizeToFillRect:self.textView.frame];
    
    //[_textView adjustsWidthToFillItsContents];
   
}

- (BOOL)textView:(UITextView *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (!isShowingEditingHandles) {
        [self showEditingHandles];
    }
   // [_textView adjustsWidthToFillItsContents];
    return YES;
}

@end
