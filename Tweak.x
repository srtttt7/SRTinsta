#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface UIViewController (SRTHelpers)
- (void)srt_convertVideoToAudio:(NSURL *)videoURL;
@end

@interface UIWindow (SRTHelpers)
- (void)srt_handlePanGesture:(UIPanGestureRecognizer *)pan;
- (void)srt_pickVideoForAudio;
@end

static NSURL *gPendingConvertedAudioURL = nil;

// =======================================================
// 1. Hook على مسار التسجيل واستبدال ملف الصوت قبل الإرسال
// =======================================================
%hook AVAudioRecorder

- (BOOL)record {
    BOOL result = %orig;
    
    // إذا كان هناك صوت محول من الفيديو، نستبدل مسار الحفظ المؤقت للمايك
    if (gPendingConvertedAudioURL && [NSFileManager.defaultManager fileExistsAtPath:gPendingConvertedAudioURL.path]) {
        NSURL *destURL = self.url;
        if (destURL) {
            [NSFileManager.defaultManager removeItemAtURL:destURL error:nil];
            [NSFileManager.defaultManager copyItemAtURL:gPendingConvertedAudioURL toURL:destURL error:nil];
        }
    }
    return result;
}

%end

// =======================================================
// 2. Hook على UIWindow لإضافة الزر العائم
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
// 3. معالجة تحويل الفيديو
// =======================================================
%hook UIViewController

%new
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        if (videoURL) {
            [self srt_convertVideoToAudio:videoURL];
        }
    }];
}

%new
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

%new
- (void)srt_convertVideoToAudio:(NSURL *)videoURL {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
        
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"srt_voice_override.m4a"];
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:outputPath]) {
            [fm removeItemAtPath:outputPath error:nil];
        }
        
        exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
        exportSession.outputFileType = AVFileTypeAppleM4A;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                gPendingConvertedAudioURL = [NSURL fileURLWithPath:outputPath];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // إشعار بسيط بالاهتزاز للتنبيه بأن الصوت جاهز للإرسال
                    UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
                    [generator impactOccurred];
                });
            }
        }];
    });
}

%end
