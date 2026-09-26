#import <UIKit/UIKit.h>

// 1. إشعار الحقوق عند فتح إنستغرام
%hook UIApplication

- (void)applicationDidBecomeActive:(id)application {
    %orig;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"SRT Insta Tweak 🚀"
                                                                       message:@"تم تفعيل أداة SRT بنجاح!\n- منع حذف الرسائل\n- رفع الصوت كبصمة صوتية"
                                                                preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"موافق" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];

        [rootVC presentViewController:alert animated:YES completion:nil];
    });
}

%end

// 2. منع حذف الرسائل في إنستغرام (Anti-Delete)
%hook IGDirectMessageStore

- (void)removeMessageForID:(id)msgId {
    // منع الحذف تماماً
    NSLog(@"[SRT] Anti-Delete Triggered!");
}

%end

// 3. رفع الصوت كبصمة صوتية في إنستغرام
%hook IGDirectAudioMessage

- (BOOL)isRecordedVoiceNote {
    return YES;
}

%end
