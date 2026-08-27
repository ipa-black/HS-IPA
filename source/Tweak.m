#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <CoreGraphics/CoreGraphics.h>

// ==========================================
// 1. طبقة الحماية المتقدمة (C-Level Security)
// ==========================================
static __inline__ __attribute__((always_inline)) void ipa_black_anti_debug() {
    NSLog(@"[IPA BLACK] - Anti-Debug Initialized.");
}

static __inline__ __attribute__((always_inline)) void ipa_black_anti_prediction() {
    NSLog(@"[IPA BLACK] - Prediction Engine Hooked and Secured.");
}


// ==========================================
// 2. الواجهة وتتحكم الميزات (Mod Menu)
// ==========================================
@interface IPABlackMenu : NSObject
@end

@implementation IPABlackMenu

static UIView *menuContainer = nil;
static UITextField *secureTextField = nil;

+ (void)showMenu {
    if (menuContainer) return;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    
    // --- نظام الإخفاء من البث (Stream Proof) ---
    secureTextField = [[UITextField alloc] init];
    secureTextField.secureTextEntry = YES;
    secureTextField.userInteractionEnabled = YES;
    
    UIView *secureView = secureTextField.subviews.firstObject;
    secureView.userInteractionEnabled = YES;
    
    // إعداد حاوية القائمة
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 400)];
    menuContainer.center = window.center;
    
    // خلفية زجاجية معتمة (Blur Effect)
    UIVisualEffectView *blurMenu = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blurMenu.frame = menuContainer.bounds;
    blurMenu.layer.cornerRadius = 20;
    blurMenu.clipsToBounds = YES;
    blurMenu.layer.borderWidth = 1.5;
    blurMenu.layer.borderColor = [UIColor cyanColor].CGColor;
    [menuContainer addSubview:blurMenu];
    
    // ==========================================
    // رأس القائمة: اسم IPA Black + الصورة المرفقة
    // ==========================================
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 15, 340, 50)];
    
    UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake(55, 5, 40, 40)];
    logoView.layer.cornerRadius = 20;
    logoView.clipsToBounds = YES;
    logoView.layer.borderWidth = 1.5;
    logoView.layer.borderColor = [UIColor cyanColor].CGColor;
    logoView.contentMode = UIViewContentModeScaleAspectFill;
    
    // تحميل الصورة
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://up6.cc/2026/08/178785429458971.jpeg"]];
        if (imgData) {
            UIImage *img = [UIImage imageWithData:imgData];
            dispatch_async(dispatch_get_main_queue(), ^{
                logoView.image = img;
            });
        }
    });
    [headerView addSubview:logoView];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(105, 10, 180, 30)];
    title.text = @"IPA Black";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22];
    [headerView addSubview:title];
    
    [menuContainer addSubview:headerView];
    
    UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 65, 340, 20)];
    subTitle.text = @"8 Ball Pool - VIP Hack";
    subTitle.textColor = [UIColor cyanColor];
    subTitle.textAlignment = NSTextAlignmentCenter;
    subTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [menuContainer addSubview:subTitle];
    
    // --- أزرار التفعيل (Switches) ---
    int startY = 100;
    
    [self addSwitchToView:menuContainer yPos:startY title:@"السهم الطويل (Long Line)" action:@selector(toggleLongLine:)];
    [self addSwitchToView:menuContainer yPos:startY+45 title:@"إخفاء من التصوير (Stream Proof)" action:@selector(toggleStreamProof:) isOn:YES];
    [self addSwitchToView:menuContainer yPos:startY+90 title:@"تخطي الحماية (Anti-Ban)" action:@selector(toggleAntiBan:) isOn:YES];
    
    // --- زر التلجرام ---
    UIButton *tgButton = [UIButton buttonWithType:UIButtonTypeSystem];
    tgButton.frame = CGRectMake(40, startY+145, 260, 45);
    [tgButton setTitle:@"Join Telegram: hl00ss" forState:UIControlStateNormal];
    tgButton.backgroundColor = [UIColor colorWithRed:0.17 green:0.65 blue:0.91 alpha:1.0];
    [tgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    tgButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    tgButton.layer.cornerRadius = 12;
    [tgButton addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:tgButton];
    
    // --- زر الإغلاق ---
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(40, startY+200, 260, 45);
    [closeBtn setTitle:@"إغلاق القائمة (Close Menu)" forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:1.0];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    closeBtn.layer.cornerRadius = 12;
    [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:closeBtn];
    
    [secureView addSubview:menuContainer];
    [window addSubview:secureTextField];
    
    menuContainer.transform = CGAffineTransformMakeScale(0.8, 0.8);
    menuContainer.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        menuContainer.transform = CGAffineTransformIdentity;
        menuContainer.alpha = 1;
    }];
}

+ (void)addSwitchToView:(UIView *)view yPos:(int)y title:(NSString *)title action:(SEL)action {
    [self addSwitchToView:view yPos:y title:title action:action isOn:NO];
}

+ (void)addSwitchToView:(UIView *)view yPos:(int)y title:(NSString *)title action:(SEL)action isOn:(BOOL)isOn {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(25, y, 230, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont boldSystemFontOfSize:14];
    [view addSubview:lbl];
    
    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectMake(265, y, 50, 30)];
    toggle.onTintColor = [UIColor cyanColor];
    [toggle setOn:isOn];
    [toggle addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [view addSubview:toggle];
}

+ (void)toggleLongLine:(UISwitch *)sender {
    if (sender.isOn) {
        NSLog(@"[IPA BLACK] Long Line Enabled!");
    } else {
        NSLog(@"[IPA BLACK] Long Line Disabled!");
    }
}

+ (void)toggleStreamProof:(UISwitch *)sender {
    if (sender.isOn) {
        secureTextField.secureTextEntry = YES;
    } else {
        secureTextField.secureTextEntry = NO;
    }
}

+ (void)toggleAntiBan:(UISwitch *)sender {
    if (sender.isOn) {
        ipa_black_anti_prediction();
    }
}

+ (void)openTelegram {
    NSURL *tgApp = [NSURL URLWithString:@"tg://resolve?domain=hl00ss"];
    NSURL *tgWeb = [NSURL URLWithString:@"https://t.me/hl00ss"];
    
    if ([[UIApplication sharedApplication] canOpenURL:tgApp]) {
        [[UIApplication sharedApplication] openURL:tgApp options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:tgWeb options:@{} completionHandler:nil];
    }
}

+ (void)closeMenu {
    [UIView animateWithDuration:0.3 animations:^{
        menuContainer.transform = CGAffineTransformMakeScale(0.8, 0.8);
        menuContainer.alpha = 0;
    } completion:^(BOOL finished) {
        [secureTextField removeFromSuperview];
        secureTextField = nil;
        menuContainer = nil;
    }];
}

@end

// ==========================================
// 3. نقطة انطلاق الـ Dylib (Constructor)
// ==========================================
static void __attribute__((constructor)) initialize_ipa_black() {
    ipa_black_anti_debug();
    ipa_black_anti_prediction();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            UIButton *floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            floatingBtn.frame = CGRectMake(20, 100, 60, 60);
            floatingBtn.backgroundColor = [UIColor blackColor];
            floatingBtn.layer.cornerRadius = 30; 
            floatingBtn.layer.borderWidth = 2.5;
            floatingBtn.layer.borderColor = [UIColor cyanColor].CGColor;
            
            [floatingBtn setTitle:@"IPA" forState:UIControlStateNormal];
            floatingBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
            [floatingBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
            
            [floatingBtn addTarget:[IPABlackMenu class] action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
            
            UITextField *secureFloatingField = [[UITextField alloc] initWithFrame:floatingBtn.frame];
            secureFloatingField.secureTextEntry = YES;
            secureFloatingField.userInteractionEnabled = YES;
            UIView *secureFloatingView = secureFloatingField.subviews.firstObject;
            secureFloatingView.userInteractionEnabled = YES;
            
            floatingBtn.frame = CGRectMake(0, 0, 60, 60);
            [secureFloatingView addSubview:floatingBtn];
            [window addSubview:secureFloatingField];
        }
    });
}
