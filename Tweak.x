#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

// =======================================================
// 1. Hook على مستوى UIWindow لضمان ظهور الزر دائماً
// =======================================================
%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    
    // منع تكرار إنشاء الزر إذا كان موجوداً في النافذة
    if ([self viewWithTag:887766]) return;
    
    // حساب الأبعاد للظهور في منتصف الشاشة على اليمين
    CGFloat btnSize = 48.0;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat yPosition = (screenHeight - btnSize) / 2.0;
    CGFloat xPosition = screenWidth - btnSize - 10.0;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = 887766;
    btn.frame = CGRectMake(xPosition, yPosition, btnSize, btnSize);
    btn.backgroundColor = [UIColor systemPurpleColor];
    [btn setTitle:@"🎵" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:22];
    btn.layer.cornerRadius = btnSize / 2.0;
    
    // إضافة ظلال وبروز للزر
    btn.layer.shadowColor = [UIColor blackColor].CGColor;
    btn.layer.shadowOffset = CGSizeMake(0, 3);
    btn.layer.shadowOpacity = 0.5;
    btn.layer.shadowRadius = 5.0;
    
    // إضافة إمكانية السحب والإفلات (Pan Gesture)
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(srt_handlePanGesture:)];
    [btn addGestureRecognizer:panGesture];
    
    [btn addTarget:self action:@selector(srt_pickVideoForAudio) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btn];
}

%new
- (void)srt_handlePanGesture:(UIPanGestureRecognizer *)pan {
    UIView *btn = pan.view;
    CGPoint translation = [pan translationInView:self];
    btn.center = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self];
}

%new
- (void)srt_pickVideoForAudio {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[@"public.movie", @"public.video"];
    
    // الحصول على أحدث ViewController معروض على الشاشة
    UIViewController *topVC = self.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    
    picker.delegate = (id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)topVC;
    
    // تعيين الـ Handler عند اختيار الفيديو
    objc_setAssociatedObject(topVC, "srt_picker_delegate", picker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [topVC presentViewController:picker animated:YES completion:nil];
}

%end

// =======================================================
// 2. Handling اختيارات الاستوديو والتحويل
// =======================================================
%hook UIViewController

%new
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    if (videoURL) {
        [self srt_convertVideoToAudio:videoURL];
    }
}

%new
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

%new
- (void)srt_convertVideoToAudio:(NSURL *)videoURL {
    UIAlertController *loadingAlert = [UIAlertController alertControllerWithTitle:@"جاري التحويل ⏳" 
                                                                          message:@"يتم استخراج الصوت من الفيديو..." 
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loadingAlert animated:YES completion:nil];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"srt_extracted_voice.m4a"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:outputPath]) {
        [fm removeItemAtPath:outputPath error:nil];
    }
    
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.outputFileType = AVFileTypeAppleM4A;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [loadingAlert dismissViewControllerAnimated:YES completion:^{
                if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                    UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"تم التحويل بنجاح! 🎵" 
                                                                                          message:[NSString stringWithFormat:@"تم استخراج ملف الصوت بنجاح وحفظه في:\n\n%@", outputPath] 
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                    [successAlert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:successAlert animated:YES completion:nil];
                } else {
                    UIAlertController *errAlert = [UIAlertController alertControllerWithTitle:@"خطأ" 
                                                                                      message:@"فشل استخراج الصوت من هذا الفيديو." 
                                                                               preferredStyle:UIAlertControllerStyleAlert];
                    [errAlert addAction:[UIAlertAction actionWithTitle:@"إغلاق" style:UIAlertActionStyleCancel handler:nil]];
                    [self presentViewController:errAlert animated:YES completion:nil];
                }
            }];
        });
    }];
}

%end
