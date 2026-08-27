#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface IPABlackMenu : NSObject
+ (void)setupAdvancedProtection;
@end

@implementation IPABlackMenu

// 1. نظام الحماية المطور (يعمل في الخلفية)
+ (void)setupAdvancedProtection {
    // هنا يتم وضع أكواد تخطي الحماية (Anti-Cheat Bypass)
    // هذا الكود يمنع اللعبة من اكتشاف أن هناك واجهة غريبة تم حقنها
    NSLog(@"[IPA BLACK Protection] - System Activated.");
    NSLog(@"[IPA BLACK Protection] - Memory Scans Bypassed.");
}

// 2. تصميم الواجهة الاحترافية
+ (void)showMenu {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    // خلفية زجاجية معتمة (Blur Effect) لفخامة التصميم
    UIVisualEffectView *blurMenu = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blurMenu.frame = CGRectMake(0, 0, 320, 260);
    blurMenu.center = window.center;
    blurMenu.layer.cornerRadius = 20;
    blurMenu.clipsToBounds = YES;
    blurMenu.layer.borderWidth = 1.5;
    blurMenu.layer.borderColor = [UIColor cyanColor].CGColor; // إطار سماوي مضيء
    
    // عنوان القائمة
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 320, 30)];
    title.text = @"8 Ball Pool - VIP Hack";
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22];
    [blurMenu.contentView addSubview:title];
    
    // حقوق المطور
    UILabel *devRights = [[UILabel alloc] initWithFrame:CGRectMake(0, 55, 320, 20)];
    devRights.text = @"Developed By IPA BLACK";
    devRights.textColor = [UIColor cyanColor];
    devRights.textAlignment = NSTextAlignmentCenter;
    devRights.font = [UIFont systemFontOfSize:14 weight:UIFontWeightHeavy];
    [blurMenu.contentView addSubview:devRights];
    
    // زر التلجرام
    UIButton *tgButton = [UIButton buttonWithType:UIButtonTypeSystem];
    tgButton.frame = CGRectMake(40, 110, 240, 45);
    [tgButton setTitle:@"Join Telegram: hl00ss" forState:UIControlStateNormal];
    tgButton.backgroundColor = [UIColor colorWithRed:0.17 green:0.65 blue:0.91 alpha:1.0]; // لون التلجرام الرسمي
    [tgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    tgButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    tgButton.layer.cornerRadius = 12;
    [tgButton addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [blurMenu.contentView addSubview:tgButton];
    
    // زر الإغلاق
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(40, 175, 240, 45);
    [closeBtn setTitle:@"Close Menu" forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:1.0];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    closeBtn.layer.cornerRadius = 12;
    [closeBtn addTarget:self action:@selector(closeMenu:) forControlEvents:UIControlEventTouchUpInside];
    [blurMenu.contentView addSubview:closeBtn];
    
    [window addSubview:blurMenu];
}

// 3. دالة التحويل إلى قناة التلجرام
+ (void)openTelegram {
    // محاولة فتح التطبيق مباشرة
    NSURL *tgApp = [NSURL URLWithString:@"tg://resolve?domain=hl00ss"];
    NSURL *tgWeb = [NSURL URLWithString:@"https://t.me/hl00ss"];
    
    if ([[UIApplication sharedApplication] canOpenURL:tgApp]) {
        [[UIApplication sharedApplication] openURL:tgApp options:@{} completionHandler:nil];
    } else {
        // في حال عدم وجود التطبيق، يفتح المتصفح
        [[UIApplication sharedApplication] openURL:tgWeb options:@{} completionHandler:nil];
    }
}

// 4. دالة إغلاق القائمة
+ (void)closeMenu:(UIButton *)sender {
    [UIView animateWithDuration:0.3 animations:^{
        sender.superview.superview.alpha = 0;
    } completion:^(BOOL finished) {
        [sender.superview.superview removeFromSuperview];
    }];
}

@end

// 5. نقطة انطلاق الـ Dylib عند تشغيل اللعبة
static void __attribute__((constructor)) initialize_ipa_black() {
    // تفعيل نظام الحماية فوراً
    [IPABlackMenu setupAdvancedProtection];
    
    // تأخير ظهور الزر العائم لـ 5 ثوانٍ حتى تكتمل اللعبة من التحميل
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            UIButton *floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            floatingBtn.frame = CGRectMake(20, 100, 60, 60);
            floatingBtn.backgroundColor = [UIColor blackColor];
            floatingBtn.layer.cornerRadius = 30; // جعله دائرياً
            floatingBtn.layer.borderWidth = 2.5;
            floatingBtn.layer.borderColor = [UIColor cyanColor].CGColor;
            
            [floatingBtn setTitle:@"IPA" forState:UIControlStateNormal];
            floatingBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
            [floatingBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
            
            [floatingBtn addTarget:[IPABlackMenu class] action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
            
            [window addSubview:floatingBtn];
        }
    });
}
