#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

// =======================================================
// 1. تعريف واجهة متحكم المحادثات لتفادي خطأ Forward Declaration
// =======================================================
@interface IGDirectMainViewController : UIViewController
- (void)srt_handlePanGesture:(UIPanGestureRecognizer *)pan;
- (void)srt_pickVideoForAudio;
- (void)srt_convertVideoToAudio:(NSURL *)videoURL;
@end

// =======================================================
// 2. Hook إضافة الزر العائم القابل للتحريك
// =======================================================
%hook IGDirectMainViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    // منع تكرار إنشاء الزر إذا كان موجوداً
    if ([self.view viewWithTag:887766]) return;
    
    // وضع الزر في منتصف الشاشة على اليمين
    CGFloat btnSize = 46.0;
    CGFloat yPosition = (self.view.frame.size.height - btnSize) / 2.0;
    CGFloat xPosition = self.view.frame.size.width - btnSize - 12.0;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = 887766;
    btn.frame = CGRectMake(xPosition, yPosition, btnSize, btnSize);
    btn.backgroundColor = [UIColor systemPurpleColor];
    [btn setTitle:@"🎵" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:22];
    btn.layer.cornerRadius = btnSize / 2.0;
    
    // إضافة ظلال للزر
    btn.layer.shadowColor = [UIColor blackColor].CGColor;
    btn.layer.shadowOffset = CGSizeMake(0, 3);
    btn.layer.shadowOpacity = 0.35;
    btn.layer.shadowRadius = 5.0;
    
    // إضافة حركة السحب والإفلات (Pan Gesture)
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(srt_handlePanGesture:)];
    [btn addGestureRecognizer:panGesture];
    
    [btn addTarget:self action:@selector(srt_pickVideoForAudio) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

%new
- (void)srt_handlePanGesture:(UIPanGestureRecognizer *)pan {
    UIView *btn = pan.view;
    CGPoint translation = [pan translationInView:self.view];
    btn.center = CGPointMake(btn.center.x + translation.x, btn.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.view];
}

%new
- (void)srt_pickVideoForAudio {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[@"public.movie", @"public.video"];
    picker.delegate = (id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)self;
    
    [self presentViewController:picker animated:YES completion:nil];
}

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
