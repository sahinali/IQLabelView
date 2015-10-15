//
//  IQLabelView.h
//  Created by kcandr on 17/12/14.

#import <UIKit/UIKit.h>
#import "KPFontPicker.h"

@protocol IQLabelViewDelegate;

@interface IQLabelView : UIView<UIGestureRecognizerDelegate, UITextViewDelegate,KPFontPickerDelegate>
{
    UIImageView *rotateView;
    UIImageView *closeView;
    
    BOOL isShowingEditingHandles;
}



@property(strong, nonatomic) UITextView *textView;

@property(strong, nonatomic) KPFontPicker *picker;
@property (assign, nonatomic) UIColor *textColor;
@property (assign, nonatomic) UIColor *borderColor;

@property (strong, nonatomic) NSString *fontName;
@property (assign, nonatomic) CGFloat apiFontSize;

@property (assign, nonatomic) UIImage *closeImage;
@property (assign, nonatomic) UIImage *rotateImage;

@property (unsafe_unretained) id <IQLabelViewDelegate> delegate;

@property (assign, nonatomic) BOOL showContentShadow;    //Default is YES.
@property (assign, nonatomic) BOOL enableClose;          //Default is YES. if set to NO, user can't delete the view
@property (assign, nonatomic) BOOL enableRotate;         //Default is YES. if set to NO, user can't Rotate the view

//Give call's to refresh. If SuperView is UIScrollView. And it changes it's zoom scale.
- (void)refresh;

- (void)hideEditingHandles;
//
//- (void)pinchViewPanGesture:(UIPinchGestureRecognizer*)recognizer;
- (void)showEditingHandles;

- (void)setTextField:(UITextView *)field;

- (void)setTextAlpha:(CGFloat)alpha;
- (CGFloat)textAlpha;

@end

@protocol IQLabelViewDelegate <NSObject>
@optional
- (void)labelViewDidBeginEditing:(IQLabelView *)label;
- (void)labelViewDidChangeEditing:(IQLabelView *)label;
- (void)labelViewDidEndEditing:(IQLabelView *)label;

- (void)labelViewDidClose:(IQLabelView *)label;

- (void)labelViewDidShowEditingHandles:(IQLabelView *)label;
- (void)labelViewDidHideEditingHandles:(IQLabelView *)label;
- (void)labelViewDidStartEditing:(IQLabelView *)label;
@end


