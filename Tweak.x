#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

// =======================================================
// 0. التصريحات الخاصة بالمترجم (Interface Declarations)
// =======================================================
@interface UIViewController (SRTHelpers)
- (void)srt_processAndSendDirectly:(NSURL *)videoURL;
@end

@interface UIWindow (SRTHelpers)
- (void)srt_handlePanGesture:(UIPanGestureRecognizer *)pan;
- (void)srt_pickVideoForAudio;
@end

@interface IGDirectThreadViewController : UIViewController
- (void)_sendAudioMessageWithURL:(NSURL *)url duration:(double)duration waveformData:(id)waveform;
@end

static NSURL *gPendingAudioURL = nil;

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
// 2. معالجة الفيديو وإرساله مباشرة كصوتية
// =======================================================
%hook UIViewController

%new
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
        if (videoURL) {
            [self srt_processAndSendDirectly:videoURL];
        }
    }];
}

%new
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

%new
- (void)srt_processAndSendDirectly:(NSURL *)videoURL {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
        AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
        
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"srt_direct_voice.m4a"];
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:outputPath]) {
            [fm removeItemAtPath:outputPath error:nil];
        }
        
        exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
        exportSession.outputFileType = AVFileTypeAppleM4A;
        
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    gPendingAudioURL = [NSURL fileURLWithPath:outputPath];
                    
                    UIViewController *currentVC = self;
                    while (currentVC && ![currentVC isKindOfClass:NSClassFromString(@"IGDirectThreadViewController")]) {
                        if (currentVC.childViewControllers.count > 0) {
                            currentVC = currentVC.childViewControllers.lastObject;
                        } else {
                            break;
                        }
                    }
                    
                    if ([currentVC isKindOfClass:NSClassFromString(@"IGDirectThreadViewController")]) {
                        IGDirectThreadViewController *threadVC = (IGDirectThreadViewController *)currentVC;
                        
                        AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:gPendingAudioURL options:nil];
                        double duration = CMTimeGetSeconds(audioAsset.duration);
                        
                        if ([threadVC respondsToSelector:@selector(_sendAudioMessageWithURL:duration:waveformData:)]) {
                            [threadVC _sendAudioMessageWithURL:gPendingAudioURL duration:duration waveformData:nil];
                        }
                    }
                });
            }
        }];
    });
}

%end
