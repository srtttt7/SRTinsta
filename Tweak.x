#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

// =======================================================
// 0. تعريف الفئات الخارجية لإنستغرام لمنع خطأ Buid Error
// =======================================================
@interface IGNavigationBar : UIView
- (void)openInstaSRTMenu;
@end

@interface IGDirectComposerMicButton : UIView
- (void)handleSRTVoiceLongPress:(UILongPressGestureRecognizer *)gesture;
- (void)openMediaPickerForAudioExtraction;
- (void)openDocumentPickerForAudio;
- (void)processAndSendAudioFromURL:(NSURL *)inputURL;
@end

@interface IGDirectPublishedMessage : NSObject
@end

@interface IGStoryViewTracker : NSObject
@end

// =======================================================
// 1. مفاتيح حفظ واسترجاع الإعدادات (NSUserDefaults)
// =======================================================
#define PREF_KEY(key) [NSString stringWithFormat:@"InstaSRT_%@", key]
#define GET_BOOL(key, defaultVal) ([[NSUserDefaults standardUserDefaults] objectForKey:PREF_KEY(key)] ? [[NSUserDefaults standardUserDefaults] boolForKey:PREF_KEY(key)] : defaultVal)
#define SET_BOOL(key, val) { [[NSUserDefaults standardUserDefaults] setBool:val forKey:PREF_KEY(key)]; [[NSUserDefaults standardUserDefaults] synchronize]; }

// =======================================================
// 2. واجهات قائمة الإعدادات (واجهة زر S)
// =======================================================
@interface SRTMenuTableViewController : UITableViewController
@property (nonatomic, strong) NSString *menuType;
@end

@implementation SRTMenuTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.08 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:0.5];
}

- (UITableViewCell *)makeSwitchCellWithTitle:(NSString *)title subtitle:(NSString *)subtitle prefKey:(NSString *)prefKey defaultVal:(BOOL)defaultVal {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:1.0];
    cell.textLabel.text = title;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.text = subtitle;
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    
    UISwitch *sw = [[UISwitch alloc] init];
    sw.on = GET_BOOL(prefKey, defaultVal);
    sw.onTintColor = [UIColor systemPurpleColor];
    
    [sw addAction:[UIAction actionWithHandler:^(UIAction *action) {
        UISwitch *s = (UISwitch *)action.sender;
        SET_BOOL(prefKey, s.isOn);
    }] forControlEvents:UIControlEventValueChanged];
    
    cell.accessoryView = sw;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self.menuType isEqualToString:@"ghost"]) return 4;
    if ([self.menuType isEqualToString:@"messages"]) return 4;
    if ([self.menuType isEqualToString:@"reels"]) return 3;
    if ([self.menuType isEqualToString:@"profile"]) return 3;
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.menuType isEqualToString:@"ghost"]) {
        if (indexPath.row == 0) return [self makeSwitchCellWithTitle:@"التخفي في الرسائل" subtitle:@"لا ترسل إشعار القراءة للآخرين" prefKey:@"ghost_dm" defaultVal:YES];
        if (indexPath.row == 1) return [self makeSwitchCellWithTitle:@"التخفي في القصص" subtitle:@"شاهد القصص دون الظهور في القائمة" prefKey:@"ghost_stories" defaultVal:YES];
        if (indexPath.row == 2) return [self makeSwitchCellWithTitle:@"إخفاء الكتابة" subtitle:@"لن يعرف المستلم أنك تكتب" prefKey:@"ghost_typing" defaultVal:YES];
        if (indexPath.row == 3) return [self makeSwitchCellWithTitle:@"التخفي في البث" subtitle:@"شاهد البث المباشر بشكل مخفي" prefKey:@"ghost_live" defaultVal:YES];
    }
    
    if ([self.menuType isEqualToString:@"messages"]) {
        if (indexPath.row == 0) return [self makeSwitchCellWithTitle:@"حفظ الرسائل المحذوفة" subtitle:@"منع حذف الرسائل من المحادثة" prefKey:@"msg_antidelete" defaultVal:YES];
        if (indexPath.row == 1) return [self makeSwitchCellWithTitle:@"تحويل الفيديو لصوت" subtitle:@"تفعيل خيار اختيار فيديو وتحويله لصوت عند الضغط المطول على المايك" prefKey:@"msg_audio_picker" defaultVal:YES];
        if (indexPath.row == 2) return [self makeSwitchCellWithTitle:@"عرض المعروضة لمرة بلا حدود" subtitle:@"عرض الوسائط المؤقتة لمرات غير محدودة" prefKey:@"msg_viewonce" defaultVal:YES];
        if (indexPath.row == 3) return [self makeSwitchCellWithTitle:@"تنزيل رسالة صوتية" subtitle:@"إظهار زر التنزيل للرسائل الصوتية" prefKey:@"msg_vndownload" defaultVal:YES];
    }

    if ([self.menuType isEqualToString:@"reels"]) {
        if (indexPath.row == 0) return [self makeSwitchCellWithTitle:@"إخفاء الإعلانات" subtitle:@"إزالة جميع إعلانات المنشورات والريلز" prefKey:@"reels_noads" defaultVal:YES];
        if (indexPath.row == 1) return [self makeSwitchCellWithTitle:@"تحميل المنشورات" subtitle:@"إمكانية تنزيل الفيديوهات والصور" prefKey:@"reels_download" defaultVal:YES];
        if (indexPath.row == 2) return [self makeSwitchCellWithTitle:@"نسخ الوصف" subtitle:@"إمكانية نسخ نص الوصف والتعليقات" prefKey:@"reels_copytext" defaultVal:YES];
    }

    if ([self.menuType isEqualToString:@"profile"]) {
        if (indexPath.row == 0) return [self makeSwitchCellWithTitle:@"نسخ المعرف والاسم" subtitle:@"نسخ الـ Username والاسم بنقرة" prefKey:@"prof_copyid" defaultVal:YES];
        if (indexPath.row == 1) return [self makeSwitchCellWithTitle:@"تنزيل صورة الحساب" subtitle:@"تنزيل صورة البروفايل بجودة عالية" prefKey:@"prof_dpdownload" defaultVal:YES];
        if (indexPath.row == 2) return [self makeSwitchCellWithTitle:@"عرض صورة البروفايل للجميع" subtitle:@"إجبار عرض الصورة بالحجم الكامل" prefKey:@"prof_fulldp" defaultVal:YES];
    }

    return [self makeSwitchCellWithTitle:@"تفعيل الميزة" subtitle:@"تخصيص الإعدادات العامة" prefKey:@"gen_setting" defaultVal:YES];
}
@end

@interface SRTHomeTableViewController : UITableViewController
@end

@implementation SRTHomeTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"إعدادات InstaSRT 🚀";
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.08 alpha:1.0];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.view.backgroundColor = [UIColor colorWithRed:0.07 green:0.07 blue:0.08 alpha:1.0];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.2 alpha:0.3];
    
    UIBarButtonItem *closeBtn = [[UIBarButtonItem alloc] initWithTitle:@"إغلاق" style:UIBarButtonItemStyleDone target:self action:@selector(closeMenu)];
    self.navigationItem.leftBarButtonItem = closeBtn;
}

- (void)closeMenu {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:1.0];
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.textColor = [UIColor lightGrayColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSArray *titles = @[@"وضع الشبح 👻", @"الرسائل 💬", @"ريلز ومنشورات 🎬", @"الملف الشخصي 👤", @"التخصيص 🎨"];
    NSArray *subs = @[@"مشاهدة الرسائل والقصص بشكل مخفي", @"تحويل فيديو لصوت، حفظ المحذوف", @"التحميل، إخفاء الإعلانات، النسخ", @"نسخ المعرف، تحويل الصورة", @"تعديل المظهر والإعدادات العامة"];

    cell.textLabel.text = titles[indexPath.row];
    cell.detailTextLabel.text = subs[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SRTMenuTableViewController *subVC = [[SRTMenuTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    NSArray *types = @[@"ghost", @"messages", @"reels", @"profile", @"custom"];
    NSArray *titles = @[@"وضع الشبح", @"إعدادات الرسائل", @"ريلز ومنشورات", @"الملف الشخصي", @"التخصيص"];
    
    subVC.menuType = types[indexPath.row];
    subVC.title = titles[indexPath.row];
    [self.navigationController pushViewController:subVC animated:YES];
}
@end

// =======================================================
// 3. Hook إضافة زر S أعلى يمين الشاشة
// =======================================================
%hook IGNavigationBar

- (void)layoutSubviews {
    %orig;
    
    if ([self viewWithTag:998877]) return;
    
    UIButton *sButton = [UIButton buttonWithType:UIButtonTypeCustom];
    sButton.tag = 998877;
    sButton.frame = CGRectMake(15, 6, 32, 32);
    sButton.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.25 alpha:0.9];
    [sButton setTitle:@"S" forState:UIControlStateNormal];
    [sButton setTitleColor:[UIColor systemPurpleColor] forState:UIControlStateNormal];
    sButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    sButton.layer.cornerRadius = 16;
    sButton.layer.borderWidth = 1.2;
    sButton.layer.borderColor = [UIColor systemPurpleColor].CGColor;
    sButton.clipsToBounds = YES;
    
    [sButton addTarget:self action:@selector(openInstaSRTMenu) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:sButton];
}

%new
- (void)openInstaSRTMenu {
    SRTHomeTableViewController *homeVC = [[SRTHomeTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:homeVC];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UIWindow *keyWindow = nil;
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        if (window.isKeyWindow) { keyWindow = window; break; }
    }
    [keyWindow.rootViewController presentViewController:nav animated:YES completion:nil];
}

%end

// =======================================================
// 4. Hook الضغط المطول على المايك وتحويل الفيديو لصوت
// =======================================================
%hook IGDirectComposerMicButton

- (void)didMoveToWindow {
    %orig;
    
    for (UIGestureRecognizer *recognizer in self.gestureRecognizers) {
        if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]] && recognizer.tag == 8899) {
            return;
        }
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSRTVoiceLongPress:)];
    longPress.minimumPressDuration = 0.4;
    longPress.tag = 8899;
    [self addGestureRecognizer:longPress];
}

%new
- (void)handleSRTVoiceLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if (!GET_BOOL(@"msg_audio_picker", YES)) return;
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"من المعرض 🏞" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self openMediaPickerForAudioExtraction];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"من الملفات 📁" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self openDocumentPickerForAudio];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"إلغاء" style:UIAlertActionStyleCancel handler:nil]];
        
        UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        [rootVC presentViewController:alert animated:YES completion:nil];
    }
}

%new
- (void)openMediaPickerForAudioExtraction {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie, (NSString *)kUTTypeVideo];
    picker.delegate = (id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)self;
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    [rootVC presentViewController:picker animated:YES completion:nil];
}

%new
- (void)openDocumentPickerForAudio {
    UIDocumentPickerViewController *docPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.audio", @"public.movie"] inMode:UIDocumentPickerModeImport];
    docPicker.delegate = (id<UIDocumentPickerDelegate>)self;
    
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (rootVC.presentedViewController) {
        rootVC = rootVC.presentedViewController;
    }
    [rootVC presentViewController:docPicker animated:YES completion:nil];
}

%new
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    NSURL *videoURL = info[UIImagePickerControllerMediaURL];
    if (!videoURL) return;
    
    [self processAndSendAudioFromURL:videoURL];
}

%new
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *selectedURL = urls.firstObject;
    if (selectedURL) {
        [self processAndSendAudioFromURL:selectedURL];
    }
}

%new
- (void)processAndSendAudioFromURL:(NSURL *)inputURL {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
    
    NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"srt_extracted_voice.m4a"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        [fileManager removeItemAtPath:outputPath error:nil];
    }
    
    exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
    exportSession.outputFileType = AVFileTypeAppleM4A;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"تم تحويل الفيديو إلى صوت 🎵" message:@"جاري إرسال الرسالة الصوتية..." preferredStyle:UIAlertControllerStyleAlert];
                [rootVC presentViewController:alert animated:YES completion:nil];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [alert dismissViewControllerAnimated:YES completion:nil];
                });
            });
        }
    }];
}

%end

// =======================================================
// 5. Hooks الميزات الفعالة المربوطة بالإعدادات
// =======================================================

// منع حذف الرسائل
%hook IGDirectPublishedMessage
- (BOOL)isDeleted {
    if (GET_BOOL(@"msg_antidelete", YES)) {
        return NO;
    }
    return %orig;
}
%end

// إخفاء مشاهدة القصص
%hook IGStoryViewTracker
- (void)markStoryAsViewed:(id)arg1 {
    if (GET_BOOL(@"ghost_stories", YES)) {
        return;
    }
    %orig;
}
%end
