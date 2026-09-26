#import <UIKit/UIKit.h>

// --- إعدادات الأداة ---
static BOOL isAntiDeleteEnabled = YES;
static BOOL isVoiceDownloadEnabled = YES;

// --- إضافة زر الميزات العائم ورسالة الترحيب ---
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1. عرض رسالة الترحيب للتأكد من اشتغال الـ Dylib
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        
        if (keyWindow && keyWindow.rootViewController) {
            UIAlertController *welcomeAlert = [UIAlertController alertControllerWithTitle:@"InstaSRT 🚀"
                                                                           message:@"تم تحميل أداة InstaSRT بنجاح!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [welcomeAlert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
            [keyWindow.rootViewController presentViewController:welcomeAlert animated:YES completion:nil];
            
            // 2. إنشاء الزر العائم للأداة (SRT Menu Button)
            UIButton *srtButton = [UIButton buttonWithType:UIButtonTypeCustom];
            srtButton.frame = CGRectMake(20, 100, 50, 50);
            srtButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.8];
            [srtButton setTitle:@"SRT" forState:UIControlStateNormal];
            [srtButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            srtButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
            srtButton.layer.cornerRadius = 25;
            srtButton.layer.borderWidth = 1.5;
            srtButton.layer.borderColor = [UIColor systemInstagramColor].CGColor ?: [UIColor purpleColor].CGColor;
            srtButton.clipsToBounds = YES;
            
            // إمكانية سحب الزر في أي مكان على الشاشة
            UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:srtButton action:@selector(draggedButton:)];
            [srtButton addGestureRecognizer:panGesture];
            
            // إضافة حدث الضغط للفتح القائمة
            [srtButton addTarget:keyWindow.rootViewController action:@selector(openSRTMenu) forControlEvents:UIControlEventTouchUpInside];
            
            [keyWindow addSubview:srtButton];
        }
    });
}

// --- إضافة وظيفة قائمة الإعدادات عند الضغط على الزر ---
%category UIViewController (InstaSRTMenu)

- (void)openSRTMenu {
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"إعدادات InstaSRT"
                                                                  message:@"اختر الميزات التي تريد التحكم بها:"
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    
    // زر تفعيل/تعطيل منع الحذف
    NSString *antiDeleteTitle = isAntiDeleteEnabled ? @"منع حذف الرسائل: [مفعل ✅]" : @"منع حذف الرسائل: [معطل ❌]";
    [menu addAction:[UIAlertAction actionWithTitle:antiDeleteTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        isAntiDeleteEnabled = !isAntiDeleteEnabled;
        [self openSRTMenu]; // إعادة فتح القائمة لتحديث الحالة
    }]];
    
    // زر تفعيل/تعطيل حفظ الصوتيات
    NSString *voiceTitle = isVoiceDownloadEnabled ? @"ميزات الصوتيات: [مفعل ✅]" : @"ميزات الصوتيات: [معطل ❌]";
    [menu addAction:[UIAlertAction actionWithTitle:voiceTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        isVoiceDownloadEnabled = !isVoiceDownloadEnabled;
        [self openSRTMenu];
    }]];
    
    [menu addAction:[UIAlertAction actionWithTitle:@"إغلاق" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:menu animated:YES completion:nil];
}

%end

// --- السحب والإفلات للزر العائم ---
@implementation UIButton (SRTDrag)
- (void)draggedButton:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateChanged || pan.state == UIGestureRecognizerStateBegan) {
        CGPoint translation = [pan translationInView:self.superview];
        self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        [pan setTranslation:CGPointZero inView:self.superview];
    }
}
@end

// --- Hook منع حذف الرسائل (Anti-Unsend) ---
%hook IGDirectMessageSectionController
- (void)didUnsendMessage:(id)message {
    if (isAntiDeleteEnabled) {
        // العبور بدون تنفيذ الحذف
        return;
    }
    %orig;
}
%end
