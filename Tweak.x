#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface UIViewController (SRTHelpers)
- (void)srt_convertAndSendAudio:(NSURL *)videoURL;
@end

@interface IGDirectThreadViewController : UIViewController
- (void)sendAudioMessageWithURL:(NSURL *)audioURL waveformData:(NSData *)waveformData duration:(CGFloat)duration;
@end

// =======================================================
// 1. Hook على UIWindow لإضافة الزر العائم
// =======================================================
%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    
    if ([self viewWithTag:887766]) return;
    
    CGFloat btnSize = 46.0;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat yPosition = (screenHeight - btnSize) / 2.0;
    CGFloat xPosition = screenWidth - btnSize - 10.0;
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.tag = 887766;
    btn.frame = CGRectMake(xPosition, yPosition, btnSize, btnSize);
    btn.backgroundColor = [UIColor systemPurpleColor];
    [btn setTitle:@"🎙️" forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:22];
    btn.layer.cornerRadius = btnSize / 2.0;
    
    btn.layer.shadowColor = [UIColor blackColor].CGColor;
    btn.layer.shadowOffset = CGSizeMake(0, 3);
    btn.layer.shadowOpacity = 0.4;
    btn.layer.shadowRadius = 4.0;
    
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
    UIViewController *topVC = self.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[@"public.movie", @"public.video"];
    picker.delegate = (id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)topVC;
    
    [topVC presentViewController:picker animated:YES completion:nil];
}

%end

// =======================================================
// 2. معالجة الفيديو واستخراج الصوت ثم إرساله كـ Voice Message
// =======================================================
%hook UIViewController

%new
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        if (videoURL) {
            [self srt_convertAndSendAudio:videoURL];
        }
    }];
}

%new
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

%new
- (void)srt_convertAndSendAudio:(NSURL *)videoURL {
    UIAlertController *loadingAlert = [UIAlertController alertControllerWithTitle:@"جاري تجهيز الصوتية ⏳" 
                                                                          message:@"يتم تحويل الفيديو وإرساله كـ Voice..." 
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:loadingAlert animated:YES completion:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
        
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"srt_voice_to_send.m4a"];
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
                        NSURL *audioURL = [NSURL fileURLWithPath:outputPath];
                        
                        // نسخ الصوت إلى الحافظة (Pasteboard) ليسهل عليك إرساله أو لصقه فوراً داخل المحادثة
                        NSData *audioData = [NSData dataWithContentsOfURL:audioURL];
                        if (audioData) {
                            [[UIPasteboard generalPasteboard] setData:audioData forPasteboardType:@"com.apple.m4a-audio"];
                            [[UIPasteboard generalPasteboard] setData:audioData forPasteboardType:@"public.audio"];
                        }
                        
                        UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"تم تجهيز الصوتية 🎙️" 
                                                                                              message:@"تم نسخ الصوتية بنجاح إلى الحافظة! يمكنك الآن لصقها مباشرة وإرسالها في المحادثة." 
                                                                                       preferredStyle:UIAlertControllerStyleAlert];
                        [successAlert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
                        [self presentViewController:successAlert animated:YES completion:nil];
                    } else {
                        UIAlertController *errAlert = [UIAlertController alertControllerWithTitle:@"خطأ" 
                                                                                          message:@"تعذر استخراج الصوت من الفيديو." 
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                        [errAlert addAction:[UIAlertAction actionWithTitle:@"إغلاق" style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:errAlert animated:YES completion:nil];
                    }
                }];
            });
        }];
    });
}

%end
