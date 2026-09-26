#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

// =======================================================
// 1. الواجهات المستهدفة لشاشة المحادثة (Direct Chat)
// =======================================================
@interface IGDirectComposerContainerView : UIView
- (void)srt_openAudioConverterPicker;
- (void)srt_convertVideoToAudioAndSend:(NSURL *)videoURL;
@end

// =======================================================
// 2. Hook إضافة زر تحويل الصوت داخل شريط الكتابة
// =======================================================
%hook IGDirectComposerContainerView

- (void)layoutSubviews {
    %orig;
    
    // منع تكرار إنشاء الزر إذا كان موجوداً
    if ([self viewWithTag:778899]) return;
    
    UIButton *audioConvertBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    audioConvertBtn.tag = 778899;
    audioConvertBtn.frame = CGRectMake(10, (self.frame.size.height - 32) / 2, 32, 32);
    [audioConvertBtn setTitle:@"🎵" forState:UIControlStateNormal];
    audioConvertBtn.titleLabel.font = [UIFont systemFontOfSize:20];
    audioConvertBtn.backgroundColor = [[UIColor systemPurpleColor] colorWithAlphaComponent:0.2];
    audioConvertBtn.layer.cornerRadius = 16;
    audioConvertBtn.clipsToBounds = YES;
    
    [audioConvertBtn addTarget:self action:@selector(srt_openAudioConverterPicker) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:audioConvertBtn];
}

%new
- (void)srt_openAudioConverterPicker {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[@"public.movie", @"public.video"];
    picker.delegate = (id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)self;
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    [rootVC presentViewController:picker animated:YES completion:nil];
}

%new
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    if (videoURL) {
        [self srt_convertVideoToAudioAndSend:videoURL];
    }
}

%new
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

%new
- (void)srt_convertVideoToAudioAndSend:(NSURL *)videoURL {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    
    UIAlertController *loadingAlert = [UIAlertController alertControllerWithTitle:@"جاري التحويل ⏳" 
                                                                          message:@"يتم استخراج الصوت من الفيديو..." 
                                                                   preferredStyle:UIAlertControllerStyleAlert];
    [rootVC presentViewController:loadingAlert animated:YES completion:nil];
    
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
                    UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:@"تم بنجاح! 🎵" 
                                                                                          message:[NSString stringWithFormat:@"تم استخراج الملف الصوتي بنجاح وحفظه في:\n%@", outputPath] 
                                                                                   preferredStyle:UIAlertControllerStyleAlert];
                    [successAlert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
                    [rootVC presentViewController:successAlert animated:YES completion:nil];
                } else {
                    UIAlertController *errAlert = [UIAlertController alertControllerWithTitle:@"خطأ" 
                                                                                      message:@"فشل استخراج الصوت من هذا الفيديو." 
                                                                               preferredStyle:UIAlertControllerStyleAlert];
                    [errAlert addAction:[UIAlertAction actionWithTitle:@"إغلاق" style:UIAlertActionStyleCancel handler:nil]];
                    [rootVC presentViewController:errAlert animated:YES completion:nil];
                }
            }];
        });
    }];
}

%end
