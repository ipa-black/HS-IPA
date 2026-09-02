#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <sys/syscall.h>
#import <unistd.h>

// ====================================================
// 1. نظام الحماية المتقدم (Anti-Debugging & Anti-Tampering)
// ====================================================
static __inline__ __attribute__((always_inline)) void apply_military_protection() {
    // منع ربط أي Debugger باللعبة
    syscall(26, 31, 0, 0, 0);
    
    // فحص النواة (Sysctl) للتأكد من عدم وجود مراقب للذاكرة
    int mib[4];
    struct kinfo_proc info;
    size_t size = sizeof(info);
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    sysctl(mib, 4, &info, &size, NULL, 0);
    
    if (info.kp_proc.p_flag & P_TRACED) {
        NSLog(@"[ATTACK VIP] Debugger Detected! Terminating...");
        // انهيار متعمد للعبة لحماية الأكواد
        int *ptr = NULL;
        *ptr = 1; 
        exit(0);
    }
}

// ====================================================
// 2. المتغيرات العامة للهاك
// ====================================================
static BOOL isLongLineEnabled = NO;

// ====================================================
// 3. قسم الهاك النقي (Pure Objective-C Runtime)
// ====================================================
// تعريف المؤشرات لحفظ الدوال الأصلية
static BOOL (*orig_showCueBallTrajectory)(id, SEL);
static BOOL (*orig_wideGuideline)(id, SEL);
static BOOL (*orig_noGuidelinesOffline)(id, SEL);

// الدوال البديلة (Hooks) المجهزة بحماية ضد الانهيار
static BOOL hook_showCueBallTrajectory(id self, SEL _cmd) {
    if (isLongLineEnabled) return YES;
    return orig_showCueBallTrajectory ? orig_showCueBallTrajectory(self, _cmd) : NO;
}

static BOOL hook_wideGuideline(id self, SEL _cmd) {
    if (isLongLineEnabled) return YES;
    return orig_wideGuideline ? orig_wideGuideline(self, _cmd) : NO;
}

static BOOL hook_noGuidelinesOffline(id self, SEL _cmd) {
    if (isLongLineEnabled) return NO;
    return orig_noGuidelinesOffline ? orig_noGuidelinesOffline(self, _cmd) : YES;
}

// دالة مساعدة لعمل التبديل الآمن (Method Swizzling)
static void hookMethod(Class targetClass, SEL targetSelector, void *replacement, void **original) {
    Method method = class_getInstanceMethod(targetClass, targetSelector);
    if (method) {
        *original = method_setImplementation(method, (IMP)replacement);
    } else {
        NSLog(@"[ATTACK VIP] لم يتم العثور على الدالة: %@", NSStringFromSelector(targetSelector));
    }
}

// ====================================================
// 4. واجهة القائمة والزر العائم (تصميم ATTACK VIP العصري)
// ====================================================
@interface AttackVIPMenu : NSObject
+ (void)showMenu;
+ (void)closeMenu;
@end

@implementation AttackVIPMenu

static UIView *menuContainer = nil;

+ (void)showMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (menuContainer) return;
        
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive) {
                    window = scene.windows.firstObject;
                    break;
                }
            }
        }
        if (!window) window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;
        
        @try {
            menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
            menuContainer.center = window.center;
            menuContainer.layer.shadowColor = [UIColor blackColor].CGColor;
            menuContainer.layer.shadowOffset = CGSizeMake(0, 10);
            menuContainer.layer.shadowOpacity = 0.5;
            menuContainer.layer.shadowRadius = 15;
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurView.frame = menuContainer.bounds;
            blurView.layer.cornerRadius = 20;
            blurView.clipsToBounds = YES;
            blurView.layer.borderWidth = 0.5;
            blurView.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.3].CGColor;
            [menuContainer addSubview:blurView];
            
            UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 320, 30)];
            title.text = @"ATTACK VIP";
            title.textColor = [UIColor whiteColor];
            title.textAlignment = NSTextAlignmentCenter;
            title.font = [UIFont systemFontOfSize:22 weight:UIFontWeightHeavy];
            title.layer.shadowColor = [UIColor cyanColor].CGColor;
            title.layer.shadowRadius = 5.0;
            title.layer.shadowOpacity = 0.8;
            title.layer.shadowOffset = CGSizeZero;
            [menuContainer addSubview:title];
            
            UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 320, 20)];
            subTitle.text = @"8 Ball Pool Pro Features";
            subTitle.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
            subTitle.textAlignment = NSTextAlignmentCenter;
            subTitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
            [menuContainer addSubview:subTitle];
            
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(30, 85, 260, 1)];
            separator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
            [menuContainer addSubview:separator];
            
            UIView *featureCell = [[UIView alloc] initWithFrame:CGRectMake(20, 100, 280, 55)];
            featureCell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
            featureCell.layer.cornerRadius = 12;
            [menuContainer addSubview:featureCell];
            
            UILabel *lblLongLine = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, 150, 55)];
            lblLongLine.text = @"مسار الكرة الطويل";
            lblLongLine.textColor = [UIColor whiteColor];
            lblLongLine.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
            [featureCell addSubview:lblLongLine];
            
            UISwitch *toggleLongLine = [[UISwitch alloc] initWithFrame:CGRectMake(215, 12.5, 50, 30)];
            toggleLongLine.onTintColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0];
            toggleLongLine.on = isLongLineEnabled;
            toggleLongLine.transform = CGAffineTransformMakeScale(0.85, 0.85);
            [toggleLongLine addTarget:self action:@selector(toggleLongLineAction:) forControlEvents:UIControlEventValueChanged];
            [featureCell addSubview:toggleLongLine];
            
            UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            closeBtn.frame = CGRectMake(20, 175, 280, 45);
            [closeBtn setTitle:@"إخفاء القائمة" forState:UIControlStateNormal];
            closeBtn.backgroundColor = [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:0.8];
            [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            closeBtn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
            closeBtn.layer.cornerRadius = 12;
            [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
            [menuContainer addSubview:closeBtn];
            
            [window addSubview:menuContainer];
            
            menuContainer.transform = CGAffineTransformMakeScale(0.7, 0.7);
            menuContainer.alpha = 0;
            [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                menuContainer.transform = CGAffineTransformIdentity;
                menuContainer.alpha = 1;
            } completion:nil];
            
        } @catch (NSException *exception) {
            NSLog(@"[ATTACK VIP] خطأ في رسم القائمة: %@", exception.reason);
        }
    });
}

+ (void)toggleLongLineAction:(UISwitch *)sender {
    isLongLineEnabled = sender.isOn;
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback impactOccurred];
}

+ (void)closeMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            menuContainer.transform = CGAffineTransformMakeScale(0.8, 0.8);
            menuContainer.alpha = 0;
        } completion:^(BOOL finished) {
            [menuContainer removeFromSuperview];
            menuContainer = nil;
        }];
    });
}

@end

// ====================================================
// 5. دالة تحريك الزر العائم
// ====================================================
@implementation UIButton (Draggable)
- (void)panAction:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.superview];
    
    if (pan.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else if (pan.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeScale(1.1, 1.1);
        }];
    }
}
@end

// ====================================================
// 6. بناء الزر العائم الأساسي
// ====================================================
static void setupFloatingButton() {
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            UIWindow *window = nil;
            if (@available(iOS 13.0, *)) {
                for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                    if (scene.activationState == UISceneActivationStateForegroundActive) {
                        window = scene.windows.firstObject;
                        break;
                    }
                }
            }
            if (!window) window = [UIApplication sharedApplication].keyWindow;
            
            if (!window) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    setupFloatingButton();
                });
                return;
            }
            
            UIButton *floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            floatingBtn.frame = CGRectMake(20, 100, 55, 55);
            floatingBtn.layer.cornerRadius = 27.5;
            floatingBtn.layer.shadowColor = [UIColor cyanColor].CGColor;
            floatingBtn.layer.shadowOffset = CGSizeMake(0, 4);
            floatingBtn.layer.shadowOpacity = 0.6;
            floatingBtn.layer.shadowRadius = 8;
            
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurView.frame = floatingBtn.bounds;
            blurView.layer.cornerRadius = 27.5;
            blurView.clipsToBounds = YES;
            blurView.userInteractionEnabled = NO;
            [floatingBtn insertSubview:blurView atIndex:0];
            
            floatingBtn.layer.borderWidth = 1.0;
            floatingBtn.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
            
            [floatingBtn setTitle:@"ATK" forState:UIControlStateNormal];
            [floatingBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
            floatingBtn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBlack];
            
            [floatingBtn addTarget:[AttackVIPMenu class] action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
            
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:floatingBtn action:@selector(panAction:)];
            [floatingBtn addGestureRecognizer:pan];
            
            [window addSubview:floatingBtn];
        } @catch (NSException *exception) {
            NSLog(@"[ATTACK VIP] خطأ في رسم الزر: %@", exception.reason);
        }
    });
}

// ====================================================
// 7. نقطة الانطلاق الأساسية للتطبيق (Constructor)
// ====================================================
static void __attribute__((constructor)) ATTACK_VIP_INIT() {
    
    // 1. تشغيل الحماية فوراً قبل أي شيء
    apply_military_protection();
    
    // 2. تطبيق الهاك (Method Swizzling) بمجرد بدء اللعبة
    Class targetClass = objc_getClass("UserSettingsManager");
    if (targetClass) {
        hookMethod(targetClass, NSSelectorFromString(@"showCueBallTrajectory"), (void *)hook_showCueBallTrajectory, (void **)&orig_showCueBallTrajectory);
        hookMethod(targetClass, NSSelectorFromString(@"wideGuideline"), (void *)hook_wideGuideline, (void **)&orig_wideGuideline);
        hookMethod(targetClass, NSSelectorFromString(@"noGuidelinesOffline"), (void *)hook_noGuidelinesOffline, (void **)&orig_noGuidelinesOffline);
        NSLog(@"[ATTACK VIP] تم حقن أكواد الخطوط بنجاح!");
    } else {
        NSLog(@"[ATTACK VIP] فشل في العثور على كلاس UserSettingsManager");
    }

    // 3. تفعيل واجهة المستخدم عند اكتمال التحميل
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                setupFloatingButton();
            });
        });
    }];
}
