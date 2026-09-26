#import <UIKit/UIKit.h>

// --- إعدادات الأداة ---
static BOOL isAntiDeleteEnabled = YES;
static BOOL isVoiceDownloadEnabled = YES;

// --- زر الميزات العائم ورسالة الترحيب ---
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        
        if (keyWindow && keyWindow.rootViewController) {
            // 1. رسالة الترحيب للتأكد من تشغيل الـ Dylib
            UIAlertController *welcomeAlert = [UIAlertController alertControllerWithTitle:@"InstaSRT 🚀"
                                                                           message:@"تم تحميل أداة InstaSRT بنجاح!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [welcomeAlert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
            [keyWindow.rootViewController presentViewController:welcomeAlert animated:YES completion:nil];
            
            // 2. إنشاء زر SRT العائم
            UIButton *srtButton = [UIButton buttonWithType:UIButtonTypeCustom];
            srtButton.frame = CGRectMake(20, 100, 50, 50);
            srtButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
            [srtButton setTitle:@"SRT" forState:UIControlStateNormal];
            [srtButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            srtButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
            srtButton.layer.cornerRadius = 25;
            srtButton.layer.borderWidth = 1.5;
            srtButton.layer.borderColor = [UIColor purpleColor].CGColor;
            srtButton.clipsToBounds = YES;
            
            // إضافة خاصية السحب للزر
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:srtButton action:@selector(draggedButton:)];
            [srtButton addGestureRecognizer:panGesture];
            
            // إضافة حدث فتح القائمة عند الضغط
            [srtButton addTarget:keyWindow.rootViewController action:@selector(openSRTMenu) forControlEvents:UIControlEventTouchUpInside];
            
            [keyWindow addSubview:srtButton];
        }
    });
}

// --- قائمة إعدادات الأداة ---
%category UIViewController (InstaSRTMenu)

- (void)openSRTMenu {
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"إعدادات InstaSRT"
                                                                  message:@"اختر الميزات التي تريد التحكم بها:"
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSString *antiDeleteTitle = isAntiDeleteEnabled ? @"منع حذف الرسائل: [مفعل ✅]" : @"منع حذف الرسائل: [معطل ❌]";
    [menu addAction:[UIAlertAction actionWithTitle:antiDeleteTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        isAntiDeleteEnabled = !isAntiDeleteEnabled;
        [self openSRTMenu];
    }]];
    
    NSString *voiceTitle = isVoiceDownloadEnabled ? @"ميزات الصوتيات: [مفعل ✅]" : @"ميزات الصوتيات: [معطل ❌]";
    [menu addAction:[UIAlertAction actionWithTitle:voiceTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        isVoiceDownloadEnabled = !isVoiceDownloadEnabled;
        [self openSRTMenu];
    }]];
    
    [menu addAction:[UIAlertAction actionWithTitle:@"إغلاق" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:menu animated:YES completion:nil];
}

%end

// --- حركة السحب للزر العائم ---
@implementation UIButton (SRTDrag)
- (void)draggedButton:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateChanged || pan.state == UIGestureRecognizerStateBegan) {
        CGPoint translation = [pan translationInView:self.superview];
        self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        [pan setTranslation:CGPointZero inView:self.superview];
    }
}
@end

// --- Hook منع حذف الرسائل ---
%hook IGDirectMessageSectionController
- (void)didUnsendMessage:(id)message {
    if (isAntiDeleteEnabled) {
        return;
    }
    %orig;
}
%end
