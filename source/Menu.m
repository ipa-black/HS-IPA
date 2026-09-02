#import <UIKit/UIKit.h>

// متغير عام لحفظ حالة التفعيل
static BOOL isLongLineEnabled = NO;

// ====================================================
// واجهة القائمة والزر العائم (تصميم عصري)
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
            // الحاوية الأساسية للقائمة
            menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 240)];
            menuContainer.center = window.center;
            menuContainer.layer.shadowColor = [UIColor blackColor].CGColor;
            menuContainer.layer.shadowOffset = CGSizeMake(0, 10);
            menuContainer.layer.shadowOpacity = 0.5;
            menuContainer.layer.shadowRadius = 15;
            
            // خلفية زجاجية ضبابية (Dark Blur)
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurView.frame = menuContainer.bounds;
            blurView.layer.cornerRadius = 20;
            blurView.clipsToBounds = YES;
            
            // حدود نحيفة جداً بلون سماوي شفاف
            blurView.layer.borderWidth = 0.5;
            blurView.layer.borderColor = [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.3].CGColor;
            [menuContainer addSubview:blurView];
            
            // العنوان الرئيسي (ATTACK STORE)
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
            
            // العنوان الفرعي
            UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 320, 20)];
            subTitle.text = @"8 Ball Pool Pro Features";
            subTitle.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
            subTitle.textAlignment = NSTextAlignmentCenter;
            subTitle.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
            [menuContainer addSubview:subTitle];
            
            // خط فاصل
            UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(30, 85, 260, 1)];
            separator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
            [menuContainer addSubview:separator];
            
            // خلية التفعيل (Cell) للهاك
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
            // تصغير حجم الـ Switch قليلاً ليتناسب مع التصميم العصري
            toggleLongLine.transform = CGAffineTransformMakeScale(0.85, 0.85);
            [toggleLongLine addTarget:self action:@selector(toggleLongLineAction:) forControlEvents:UIControlEventValueChanged];
            [featureCell addSubview:toggleLongLine];
            
            // زر الإغلاق العصري
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
            
            // حركات الظهور (Spring Animation)
            menuContainer.transform = CGAffineTransformMakeScale(0.7, 0.7);
            menuContainer.alpha = 0;
            [UIView animateWithDuration:0.5 
                                  delay:0.0 
                 usingSpringWithDamping:0.7 
                  initialSpringVelocity:0.5 
                                options:UIViewAnimationOptionCurveEaseInOut 
                             animations:^{
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
    
    // إضافة اهتزاز خفيف (Haptic Feedback) عند التفعيل
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback impactOccurred];
}

+ (void)closeMenu {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 
                              delay:0.0 
                            options:UIViewAnimationOptionCurveEaseIn 
                         animations:^{
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
// دالة تحريك الزر العائم
// ====================================================
@implementation UIButton (Draggable)
- (void)panAction:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [pan setTranslation:CGPointZero inView:self.superview];
    
    // إضافة تأثير مرن عند إفلات الزر
    if (pan.state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            // يمكنك إضافة كود هنا لالتصاق الزر بحواف الشاشة إذا رغبت مستقبلاً
            self.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else if (pan.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformMakeScale(1.1, 1.1); // تكبير الزر أثناء السحب
        }];
    }
}
@end

// ====================================================
// دالة البناء للزر العائم بتصميم الزجاج
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
            
            // بناء الزر العائم الأساسي
            UIButton *floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            floatingBtn.frame = CGRectMake(20, 100, 55, 55);
            floatingBtn.layer.cornerRadius = 27.5;
            floatingBtn.layer.shadowColor = [UIColor cyanColor].CGColor;
            floatingBtn.layer.shadowOffset = CGSizeMake(0, 4);
            floatingBtn.layer.shadowOpacity = 0.6;
            floatingBtn.layer.shadowRadius = 8;
            
            // إضافة خلفية ضبابية للزر
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurView.frame = floatingBtn.bounds;
            blurView.layer.cornerRadius = 27.5;
            blurView.clipsToBounds = YES;
            blurView.userInteractionEnabled = NO;
            [floatingBtn insertSubview:blurView atIndex:0];
            
            // حواف الزر
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
            NSLog(@"[ATTACK VIP] حدث خطأ في رسم الزر: %@", exception.reason);
        }
    });
}

// ====================================================
// نقطة الانطلاق
// ====================================================
%ctor {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                setupFloatingButton();
            });
        });
    }];
}

// ====================================================
// قسم الهاك (Logos Hooks)
// ====================================================
%hook UserSettingsManager

- (_Bool)showCueBallTrajectory {
    if (isLongLineEnabled) return YES;
    return %orig;
}

- (_Bool)wideGuideline {
    if (isLongLineEnabled) return YES;
    return %orig;
}

- (_Bool)noGuidelinesOffline {
    if (isLongLineEnabled) return NO;
    return %orig;
}

%end
