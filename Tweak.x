#import <UIKit/UIKit.h>

// --- إعدادات الأداة ---
static BOOL isAntiDeleteEnabled = YES;
static BOOL isVoiceDownloadEnabled = YES;

// --- واجهة أزرار التحكم ---
@interface SRTManager : NSObject
+ (void)openSRTMenuFromController:(UIViewController *)vc;
@end

@implementation SRTManager
+ (void)openSRTMenuFromController:(UIViewController *)vc {
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:@"إعدادات InstaSRT 🚀"
                                                                  message:@"اختر الميزات التي تريد التحكم بها:"
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSString *antiDeleteTitle = isAntiDeleteEnabled ? @"منع حذف الرسائل: [مفعل ✅]" : @"منع حذف الرسائل: [معطل ❌]";
    [menu addAction:[UIAlertAction actionWithTitle:antiDeleteTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        isAntiDeleteEnabled = !isAntiDeleteEnabled;
        [self openSRTMenuFromController:vc];
    }]];
    
    NSString *voiceTitle = isVoiceDownloadEnabled ? @"ميزات الصوتيات: [مفعل ✅]" : @"ميزات الصوتيات: [معطل ❌]";
    [menu addAction:[UIAlertAction actionWithTitle:voiceTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        isVoiceDownloadEnabled = !isVoiceDownloadEnabled;
        [self openSRTMenuFromController:vc];
    }]];
    
    [menu addAction:[UIAlertAction actionWithTitle:@"إغلاق" style:UIAlertActionStyleCancel handler:nil]];
    
    [vc presentViewController:menu animated:YES completion:nil];
}
@end

// --- عنصر الزر العائم وتفاعله ---
@interface SRTButton : UIButton
@end

@implementation SRTButton
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.85];
        [self setTitle:@"SRT" forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        self.layer.cornerRadius = 25;
        self.layer.borderWidth = 1.5;
        self.layer.borderColor = [UIColor purpleColor].CGColor;
        self.clipsToBounds = YES;
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan];
        
        [self addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateChanged || pan.state == UIGestureRecognizerStateBegan) {
        CGPoint translation = [pan translationInView:self.superview];
        self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        [pan setTranslation:CGPointZero inView:self.superview];
    }
}

- (void)buttonTapped {
    UIWindow *keyWindow = nil;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    if (keyWindow.rootViewController) {
        [SRTManager openSRTMenuFromController:keyWindow.rootViewController];
    }
}
@end

// --- تهيئة الأداة عند تشغيل التطبيق ---
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
            // 1. تنبيه الترحيب المباشر
            UIAlertController *welcomeAlert = [UIAlertController alertControllerWithTitle:@"InstaSRT 🚀"
                                                                           message:@"تم تحميل أداة InstaSRT بنجاح!"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [welcomeAlert addAction:[UIAlertAction actionWithTitle:@"حسناً" style:UIAlertActionStyleDefault handler:nil]];
            [keyWindow.rootViewController presentViewController:welcomeAlert animated:YES completion:nil];
            
            // 2. إظهار زر SRT العائم
            SRTButton *srtBtn = [[SRTButton alloc] initWithFrame:CGRectMake(20, 100, 50, 50)];
            [keyWindow addSubview:srtBtn];
        }
    });
}

// --- Hook منع حذف الرسائل ---
%hook IGDirectMessageSectionController
- (void)didUnsendMessage:(id)message {
    if (isAntiDeleteEnabled) {
        return;
    }
    %orig;
}
%end
