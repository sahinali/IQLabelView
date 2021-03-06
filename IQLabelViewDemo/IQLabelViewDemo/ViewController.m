//
//  ViewController.m
//  IQLabelViewDemo
//
//  Created by kcandr on 20.12.14.

#import "ViewController.h"
#import "IQLabelView.h"

@interface ViewController () <IQLabelViewDelegate>
{
    IQLabelView *currentlyEditingLabel;
    NSMutableArray *labels;
}

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) NSArray *colors;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.colors = [NSArray arrayWithObjects:[UIColor whiteColor], [UIColor redColor], [UIColor blueColor], nil];
    
    UIBarButtonItem *addLabelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                    target:self action:@selector(addLabel)];

    UIBarButtonItem *refreshColorButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                        target:self action:@selector(changeColor)];
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                target:self action:@selector(saveImage)];
    self.navigationItem.leftBarButtonItem = addLabelButton;
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:saveButton, refreshColorButton, nil];
    
    [self.view setBackgroundColor:[UIColor colorWithRed:88/255.0 green:173/255.0 blue:227/255.0 alpha:1.0]];
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchOutside:)]];
    [self.imageView setImage:[UIImage imageNamed:@"image"]];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addLabel
{
    [currentlyEditingLabel hideEditingHandles];
    CGRect labelFrame = CGRectMake(30,
                                   30,
                                   200, 150);
    UITextView *aLabel = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 180, 120)];
      aLabel.font = [UIFont fontWithName:@"Minnie" size:20];
    [aLabel setClipsToBounds:YES];
    [aLabel setAutoresizingMask:(UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin)];

//        [aLabel setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"ImagEdit", nil)
//                                                                         attributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.75],  NSFontAttributeName : [UIFont fontWithName:@"Minnie" size:17.0]}]];

    [aLabel setTextColor:[UIColor redColor]];

   
    
    IQLabelView *labelView = [[IQLabelView alloc] initWithFrame:labelFrame];
    [labelView setAutoresizingMask:(UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth)];
    labelView.delegate = self;
    [labelView setShowContentShadow:NO];
    //[labelView setEnableMoveRestriction:YES];

    
    
  
    
    [labelView setTextField:aLabel];


    [labelView setTextColor:[UIColor redColor]];
    
    [labelView sizeToFit];
    labelView.delegate = self;
//    [self.view addSubview:labelView];

    
    UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationDetected:)];
    [self.imageView addGestureRecognizer:rotationRecognizer];
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)];
    [self.imageView addGestureRecognizer:pinchRecognizer];
    

    [self.imageView addSubview:labelView];
    [self.imageView setUserInteractionEnabled:YES];
    
    currentlyEditingLabel = labelView;
    
    
    [currentlyEditingLabel setTextColor:[UIColor redColor]];
    

    [labels addObject:labelView];
}


- (void)pinchDetected:(UIPinchGestureRecognizer *)pinchRecognizer
{
//    [currentlyEditingLabel pinchViewPanGesture:pinchRecognizer];
    
    
}

- (void)rotationDetected:(UIRotationGestureRecognizer *)rotationRecognizer
{

        CGFloat angle = rotationRecognizer.rotation;
        currentlyEditingLabel.transform = CGAffineTransformRotate(currentlyEditingLabel.transform, angle);
        rotationRecognizer.rotation = 0.0;

    
}




- (void)saveImage
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        UIImageWriteToSavedPhotosAlbum([self visibleImage], nil, nil, nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Saved to Photo Roll");
        });
    });
}

- (void)changeColor
{
    [currentlyEditingLabel setTextColor:[self.colors objectAtIndex:arc4random() % 3]];
}

- (UIImage *)visibleImage
{
    UIGraphicsBeginImageContextWithOptions(self.imageView.bounds.size, YES, [UIScreen mainScreen].scale);
    CGContextTranslateCTM(UIGraphicsGetCurrentContext(), CGRectGetMinX(self.imageView.frame), -CGRectGetMinY(self.imageView.frame));
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *visibleViewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return visibleViewImage;
}

#pragma mark - Gesture 

- (void)touchOutside:(UITapGestureRecognizer *)touchGesture
{
    [currentlyEditingLabel hideEditingHandles];
}

#pragma mark - IQLabelDelegate

- (void)labelViewDidClose:(IQLabelView *)label
{
    // some actions after delete label
    [labels removeObject:label];
}

- (void)labelViewDidBeginEditing:(IQLabelView *)label
{
    // move or rotate begin
}

- (void)labelViewDidShowEditingHandles:(IQLabelView *)label
{
    // showing border and control buttons
    currentlyEditingLabel = label;
}

- (void)labelViewDidHideEditingHandles:(IQLabelView *)label
{
    // hiding border and control buttons
    currentlyEditingLabel = nil;
}

- (void)labelViewDidStartEditing:(IQLabelView *)label
{
    // tap in text field and keyboard showing
    currentlyEditingLabel = label;
}

@end
