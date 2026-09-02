#import <UIKit/UIKit.h>

// ==========================================
// تعريف الألوان (الذهبي والزجاجي)
// ==========================================
#define GOLD_COLOR [UIColor colorWithRed:0.83 green:0.69 blue:0.22 alpha:1.0]
#define GLASS_DARK [UIColor colorWithWhite:0.0 alpha:0.4]

// ==========================================
// 1. تعريف الكلاسات (Interfaces)
// ==========================================
@interface GBModMenu : UIView
@end

@interface CBToggle : UIButton
@property (nonatomic, strong) UISwitch *targetSwitch;
@property (nonatomic, strong) NSString *baseTitle;
- (void)updateLook;
@end

// ==========================================
// 2. برمجة زر الصح (الذهبي)
// ==========================================
@implementation CBToggle
- (void)btnTapped {
    BOOL newState = !self.targetSwitch.isOn;
    [self.targetSwitch setOn:newState animated:YES];
    [self.targetSwitch sendActionsForControlEvents:UIControlEventValueChanged];
    [self.targetSwitch sendActionsForControlEvents:UIControlEventTouchUpInside];
    [self updateLook];
}
- (void)updateLook {
    self.layer.cornerRadius = 10;
    if (self.targetSwitch.isOn) {
        [self setTitle:[NSString stringWithFormat:@"✔  %@", self.baseTitle] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.backgroundColor = GOLD_COLOR;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = GOLD_COLOR.CGColor;
    } else {
        [self setTitle:[NSString stringWithFormat:@"☐  %@", self.baseTitle] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
    }
}
@end

// ==========================================
// 3. تغيير الأسماء الأصلية (Hooks)
// ==========================================
%hook UILabel
- (void)setText:(NSString *)text {
    if (text != nil && [text isKindOfClass:[NSString class]]) {
        NSString *newText = text;
        
        if ([text containsString:@"i3rby Store"]) { newText = @"ipa black"; }
        else if ([text containsString:@"ايفون بالعربي"]) { newText = @""; }
        else if ([text containsString:@"السحب الابتدائي"]) { newText = @"توقع الضربه القويه"; }
        else if ([text containsString:@"البشرنة"]) { newText = @"أسلوب اللعب"; }
        else if ([text isEqualToString:@"الرسوم"]) { newText = @"طريقة العرض"; }
        else if ([text containsString:@"الكره الخاطئة"]) { newText = @"تنبيه الكره الخاطئة"; }
        
        %orig(newText);
    } else {
        %orig(text);
    }
}
%end

// ==========================================
// 4. محرك البناء والخطف الدقيق
// ==========================================
static UILabel* findLabel(UIView *root, NSString *searchText) {
    if (root.tag == 7777 || root.tag == 9999) return nil; 
    
    if ([root isKindOfClass:[UILabel class]]) {
        if ([[(UILabel *)root text] containsString:searchText]) return (UILabel *)root;
    }
    for (UIView *sub in root.subviews) {
        UILabel *found = findLabel(sub, searchText);
        if (found) return found;
    }
    return nil;
}

static UIView* getRowForLabel(UILabel *lbl) {
    UIView *parent = lbl.superview;
    if (parent && parent.bounds.size.height >= 20 && parent.bounds.size.height <= 90) return parent;
    if (parent.superview && parent.superview.bounds.size.height >= 20 && parent.superview.bounds.size.height <= 90) return parent.superview;
    return parent;
}

static void hijackRow(UIView *row, NSString *targetName, UIScrollView *scroll, CGFloat *offset) {
    row.tag = 9999;
    [row removeFromSuperview];
    
    [row removeConstraints:row.constraints];
    row.translatesAutoresizingMaskIntoConstraints = YES;
    
    CGFloat h = row.bounds.size.height;
    if (h < 30 || h > 90) h = 50; 
    
    // تم زيادة عرض الزر ليتناسب مع الواجهة العريضة (690 بدلاً من 560)
    row.frame = CGRectMake(10, *offset, 690, h);
    row.backgroundColor = [UIColor clearColor];
    
    UISwitch *sw = nil;
    UISlider *sl = nil;
    UISegmentedControl *seg = nil;
    UILabel *txt = nil;
    
    for (UIView *v in row.subviews) {
        if ([v isKindOfClass:[UISwitch class]]) sw = (UISwitch *)v;
        else if ([v isKindOfClass:[UISlider class]]) sl = (UISlider *)v;
        else if ([v isKindOfClass:[UISegmentedControl class]]) seg = (UISegmentedControl *)v;
        else if ([v isKindOfClass:[UILabel class]]) txt = (UILabel *)v;
    }
    
    if (sw && txt) {
        sw.alpha = 0.0; 
        txt.alpha = 0.0; 
        
        CBToggle *btn = [CBToggle buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, 0, 690, h);
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        btn.baseTitle = targetName;
        btn.targetSwitch = sw;
        
        [btn addTarget:btn action:@selector(btnTapped) forControlEvents:UIControlEventTouchUpInside];
        [btn updateLook]; 
        
        [row addSubview:btn];
    } else {
        if (txt) { txt.textColor = [UIColor whiteColor]; txt.font = [UIFont boldSystemFontOfSize:15]; }
        if (sl) { sl.minimumTrackTintColor = GOLD_COLOR; sl.thumbTintColor = GOLD_COLOR; }
        if (seg) {
            if (@available(iOS 13.0, *)) seg.selectedSegmentTintColor = GOLD_COLOR;
            else seg.tintColor = GOLD_COLOR;
            [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]} forState:UIControlStateSelected];
            [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        }
    }
    
    [scroll addSubview:row];
    *offset += h + 12; 
    scroll.contentSize = CGSizeMake(710, *offset + 20); 
}

// دالة تغيير الزر العائم الخارجي (Floating Button)
static void changeFloatingButtonImage(UIImage *img) {
    if (!img) return;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    for (UIView *view in window.subviews) {
        if (view.frame.size.width >= 35 && view.frame.size.width <= 80 && view.frame.size.height == view.frame.size.width) {
            if (view.gestureRecognizers.count > 0) {
                for (UIView *sub in view.subviews) {
                    if ([sub isKindOfClass:[UIImageView class]]) {
                        [(UIImageView *)sub setImage:img];
                        view.layer.cornerRadius = view.frame.size.width / 2.0;
                        view.layer.masksToBounds = YES;
                        view.layer.borderWidth = 1.5;
                        view.layer.borderColor = GOLD_COLOR.CGColor;
                    }
                }
                if ([view isKindOfClass:[UIButton class]]) {
                    [(UIButton *)view setBackgroundImage:img forState:UIControlStateNormal];
                    [(UIButton *)view setImage:nil forState:UIControlStateNormal];
                    view.layer.cornerRadius = view.frame.size.width / 2.0;
                    view.layer.masksToBounds = YES;
                    view.layer.borderWidth = 1.5;
                    view.layer.borderColor = GOLD_COLOR.CGColor;
                }
            }
        }
    }
}

static CGFloat tabOffset0 = 10, tabOffset1 = 10, tabOffset2 = 10;
static int radarAttempts = 0; 

static void continuousRadar(UIView *mainMenu, UIView *ipablackUI) {
    if (radarAttempts > 20) return; 
    radarAttempts++;

    UIScrollView *t0 = (UIScrollView *)[ipablackUI viewWithTag:8000];
    UIScrollView *t1 = (UIScrollView *)[ipablackUI viewWithTag:8001];
    UIScrollView *t2 = (UIScrollView *)[ipablackUI viewWithTag:8002];
    
    NSArray *targets0 = @[@"خطوط التوقع", @"توقع الخصم", @"حدود الطاولة", @"تنبيه الكره الخاطئة", @"حماية البث"];
    NSArray *targets1 = @[@"طريقة العرض", @"إزاحة Y", @"إزاحة X", @"مقياس X", @"مقياس Y", @"سمك الخط", @"شفافية الخط", @"نقطة النهاية", @"حلقة الجيب", @"توقع الضربه القويه"];
    NSArray *targets2 = @[@"زر الاختصار", @"إيقاف عند اللمس", @"نمط دوران", @"وضع التصويب", @"أسلوب اللعب", @"مستوى اللعب", @"وضع الكسر", @"قوة التصويب", @"سرعة تصويب"];
    
    if (t0) {
        for (NSString *name in targets0) {
            UILabel *lbl = findLabel(mainMenu, name);
            if (lbl) hijackRow(getRowForLabel(lbl), name, t0, &tabOffset0);
        }
    }
    if (t1) {
        for (NSString *name in targets1) {
            UILabel *lbl = findLabel(mainMenu, name);
            if (lbl) hijackRow(getRowForLabel(lbl), name, t1, &tabOffset1);
        }
    }
    if (t2) {
        for (NSString *name in targets2) {
            UILabel *lbl = findLabel(mainMenu, name);
            if (lbl) hijackRow(getRowForLabel(lbl), name, t2, &tabOffset2);
        }
    }
    
    for (UIView *sub in mainMenu.subviews) {
        if (sub.tag != 7777) { 
            sub.alpha = 0.01; 
            sub.userInteractionEnabled = NO; 
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        continuousRadar(mainMenu, ipablackUI);
    });
}

// ==========================================
// 5. بناء واجهة المنيو الرئيسية (عريضة - Landscape)
// ==========================================
%hook GBModMenu

%new
- (void)ipablackTabChanged:(UISegmentedControl *)sender {
    UIView *ipablackUI = [self viewWithTag:7777];
    for (int i = 0; i < 4; i++) {
        UIView *container = [ipablackUI viewWithTag:8000 + i];
        container.hidden = (i != sender.selectedSegmentIndex);
    }
}

%new
- (void)ipablackOpenChannel {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/hl00ss"] options:@{} completionHandler:nil];
}

%new
- (void)ipablackOpenDev {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://t.me/ipa_black"] options:@{} completionHandler:nil];
}

- (void)layoutSubviews {
    %orig;
    
    UIView *mainMenu = (UIView *)self;
    
    // تم تحويل الأبعاد لتكون بالعرض الشديد (Panoramic)
    CGRect newBounds = mainMenu.bounds;
    newBounds.size.width = 750;  // عرض كبير
    newBounds.size.height = 380; // ارتفاع أنسب
    mainMenu.bounds = newBounds;
    mainMenu.backgroundColor = [UIColor clearColor]; 
    mainMenu.layer.borderWidth = 0;
    
    UIView *ipablackUI = [mainMenu viewWithTag:7777];
    if (!ipablackUI) {
        // الحاوية الشفافة بالأبعاد العريضة الجديدة
        ipablackUI = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 750, 380)];
        ipablackUI.tag = 7777;
        ipablackUI.backgroundColor = [UIColor clearColor]; 
        ipablackUI.layer.cornerRadius = 15.0;
        ipablackUI.layer.borderColor = GOLD_COLOR.CGColor;
        ipablackUI.layer.borderWidth = 1.5;
        ipablackUI.layer.shadowColor = GOLD_COLOR.CGColor;
        ipablackUI.layer.shadowRadius = 15.0;
        ipablackUI.layer.shadowOpacity = 0.5;
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = ipablackUI.bounds;
        blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        blurEffectView.layer.cornerRadius = 15.0;
        blurEffectView.clipsToBounds = YES;
        [ipablackUI addSubview:blurEffectView];
        
        [mainMenu addSubview:ipablackUI];
        
        // الأقسام (Tabs) متمددة لتغطي العرض الجديد
        UISegmentedControl *tabs = [[UISegmentedControl alloc] initWithItems:@[@"التوقع", @"طريقة العرض", @"اللعب التلقائي", @"الإعدادات"]];
        tabs.frame = CGRectMake(20, 15, 710, 45); // العرض أصبح 710
        tabs.selectedSegmentIndex = 0; 
        [tabs addTarget:self action:@selector(ipablackTabChanged:) forControlEvents:UIControlEventValueChanged];
        
        if (@available(iOS 13.0, *)) {
            tabs.selectedSegmentTintColor = GOLD_COLOR;
        } else {
            tabs.tintColor = GOLD_COLOR;
        }
        [tabs setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:14 weight:UIFontWeightMedium]} forState:UIControlStateNormal];
        [tabs setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:14]} forState:UIControlStateSelected];
        [ipablackUI addSubview:tabs];
        
        for (int i = 0; i < 4; i++) {
            // توسيع نافذة التمرير للأزرار
            UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 75, 710, 290)];
            scrollView.tag = 8000 + i; 
            scrollView.backgroundColor = [UIColor clearColor]; 
            scrollView.showsVerticalScrollIndicator = NO; 
            scrollView.alwaysBounceVertical = YES; 
            scrollView.hidden = (i != 0);
            [ipablackUI addSubview:scrollView];
        }
        
        // --- قسم الإعدادات بتوسيط مثالي ---
        UIScrollView *tab3 = (UIScrollView *)[ipablackUI viewWithTag:8003];
        
        // توسيط الصورة بناءً على العرض الجديد (710 / 2 - 50 = 305)
        UIButton *profilePicBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        profilePicBtn.frame = CGRectMake(305, 15, 100, 100);
        profilePicBtn.layer.cornerRadius = 50;
        profilePicBtn.layer.masksToBounds = YES;
        profilePicBtn.layer.borderWidth = 2.0;
        profilePicBtn.layer.borderColor = GOLD_COLOR.CGColor;
        [profilePicBtn addTarget:self action:@selector(ipablackOpenChannel) forControlEvents:UIControlEventTouchUpInside];
        [tab3 addSubview:profilePicBtn];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://up6.cc/2026/09/178838170433251.jpeg"]];
            if (imgData) {
                UIImage *downloadedImg = [UIImage imageWithData:imgData];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [profilePicBtn setBackgroundImage:downloadedImg forState:UIControlStateNormal];
                    changeFloatingButtonImage(downloadedImg);
                });
            }
        });
        
        // توسيط النص
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 125, 710, 30)];
        nameLabel.text = @"ipa black Premium";
        nameLabel.textColor = GOLD_COLOR;
        nameLabel.font = [UIFont boldSystemFontOfSize:24];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        [tab3 addSubview:nameLabel];
        
        // توسيط أزرار التواصل بناءً على العرض الجديد (710 / 2 - 125 = 230)
        UIButton *btnChannel = [UIButton buttonWithType:UIButtonTypeCustom];
        btnChannel.frame = CGRectMake(230, 175, 250, 45);
        [btnChannel setTitle:@"قناة التيليجرام" forState:UIControlStateNormal];
        [btnChannel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btnChannel.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        btnChannel.backgroundColor = GOLD_COLOR;
        btnChannel.layer.cornerRadius = 10;
        [btnChannel addTarget:self action:@selector(ipablackOpenChannel) forControlEvents:UIControlEventTouchUpInside];
        [tab3 addSubview:btnChannel];
        
        UIButton *btnDev = [UIButton buttonWithType:UIButtonTypeCustom];
        btnDev.frame = CGRectMake(230, 235, 250, 45);
        [btnDev setTitle:@"التواصل مع المطور" forState:UIControlStateNormal];
        [btnDev setTitleColor:GOLD_COLOR forState:UIControlStateNormal];
        btnDev.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        btnDev.backgroundColor = GLASS_DARK; 
        btnDev.layer.borderColor = GOLD_COLOR.CGColor;
        btnDev.layer.borderWidth = 1.5;
        btnDev.layer.cornerRadius = 10;
        [btnDev addTarget:self action:@selector(ipablackOpenDev) forControlEvents:UIControlEventTouchUpInside];
        [tab3 addSubview:btnDev];
        
        tab3.contentSize = CGSizeMake(710, 310);
        
        radarAttempts = 0; 
        continuousRadar(mainMenu, ipablackUI);
    }
    
    [mainMenu bringSubviewToFront:ipablackUI];
}
%end
