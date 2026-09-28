#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// =======================================================
// 0. التصريحات الخاصة بكلاسات إنستغرام (Declarations)
// =======================================================
@interface IGDirectMessageCell : UICollectionViewCell
- (void)srt_markAsDeletedIfNeeded;
@end

@interface IGDirectMessageViewModel : NSObject
@property (nonatomic, assign) BOOL isLocallyDeleted;
@property (nonatomic, copy) NSString *messageId;
@end

// مجموعة لتخزين معرّفات الرسائل المحذوفة (Message IDs)
static NSMutableSet *gDeletedMessageIDs = nil;

%ctor {
    gDeletedMessageIDs = [[NSMutableSet alloc] init];
}

// =======================================================
// 1. Hook منع حذف الرسالة عند وصول إشعار Unsend من السيرفر
// =======================================================
%hook IGDirectMessageDatabaseStore

- (void)removeMessageWithServerID:(NSString *)serverID threadID:(NSString *)threadID {
    if (serverID) {
        // حفظ ID الرسالة المحذوفة لعرض الإشعار الأحمر عليها
        [gDeletedMessageIDs addObject:serverID];
    }
    // عدم استدعاء %orig لمنع مسح الرسالة من قاعدة البيانات المحلية
}

- (void)deleteMessageWithID:(NSString *)messageID {
    if (messageID) {
        [gDeletedMessageIDs addObject:messageID];
    }
    // منع الحذف المحلي
}

%end

// =======================================================
// 2. Hook لمنع اختفاء الرسالة من الواجهة (UI Model)
// =======================================================
%hook IGDirectMessageViewModel

- (NSString *)messageText {
    NSString *originalText = %orig;
    if ([gDeletedMessageIDs containsObject:self.messageId]) {
        // إضافة إشعار أحمر/تنبيه أمام نص الرسالة المحذوفة
        return [NSString stringWithFormat:@"🔴 [محذوفة] %@", originalText ? originalText : @""];
    }
    return originalText;
}

%end

// =======================================================
// 3. تمييز خلية الرسالة (Cell) بعلامة/خلفية حمراء إضافية
// =======================================================
%hook IGDirectMessageCell

- (void)layoutSubviews {
    %orig;
    
    // فحص إذا كانت الخلية تحتوي على رسالة محذوفة لتظليلها باللون الأحمر الخفيف
    id viewModel = [self respondsToSelector:@selector(viewModel)] ? [self performSelector:@selector(viewModel)] : nil;
    if (viewModel && [viewModel respondsToSelector:@selector(messageId)]) {
        NSString *msgID = [viewModel performSelector:@selector(messageId)];
        if (msgID && [gDeletedMessageIDs containsObject:msgID]) {
            self.contentView.backgroundColor = [[UIColor systemRedColor] colorWithAlphaComponent:0.15];
            self.contentView.layer.borderColor = [UIColor systemRedColor].CGColor;
            self.contentView.layer.borderWidth = 1.0;
            self.contentView.layer.cornerRadius = 8.0;
        } else {
            self.contentView.layer.borderWidth = 0.0;
        }
    }
}

%end
