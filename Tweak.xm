#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <sys/types.h>

// ==========================================
// حماية المود (Anti-Debugging)
// ==========================================
static __attribute__((constructor)) void anti_debug_protection() {
    void *handle = dlopen(0, RTLD_GLOBAL | RTLD_NOW);
    typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);
    ptrace_ptr_t ptrace_ptr = (ptrace_ptr_t)dlsym(handle, "ptrace");
    if (ptrace_ptr) { ptrace_ptr(31, 0, 0, 0); }
}

// ==========================================
// 1. تعريف الكلاسات (Interfaces)
// ==========================================
@interface GBModMenu : UIView
- (void)tabChanged:(UISegmentedControl *)sender;
- (void)openChannel;
- (void)openDev;
@end

// ==========================================
// 2. تغيير الأسماء الأصلية (Hooks)
// ==========================================
%hook UILabel
- (void)setText:(NSString *)text {
    @try {
        if (text != nil && [text isKindOfClass:[NSString class]]) {
            NSString *newText = text;
            if ([text containsString:@"i3rby Store"]) { newText = @"IPA BLACK"; }
            else if ([text containsString:@"ايفون بالعربي"]) { newText = @""; }
            else if ([text containsString:@"وضع الكسر"] || [text containsString:@"توقع الكسر"]) { newText = @"توقع الكسرة"; }
            else if ([text containsString:@"البشرنة"]) { newText = @"أسلوب اللعب"; }
            else if ([text isEqualToString:@"الرسوم"]) { newText = @"طريقة العرض"; }
            else if ([text containsString:@"السحب الابتدائي"]) { newText = @"توقع الضربه القويه"; }
            else if ([text containsString:@"الكره الخاطئة"]) { newText = @"تنبيه الكره الخاطئة"; }
            %orig(newText);
        } else {
            %orig(text);
        }
    } @catch (NSException *exception) {
        %orig(text);
    }
}
%end

// ==========================================
// 3. محرك البناء والخطف الدقيق
// ==========================================
static UILabel* findLabel(UIView *root, NSString *searchText) {
    if (!root) return nil;
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

static void hijackRow(UIView *row, UIScrollView *scroll, CGFloat *offset) {
    if (!row || !scroll) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        row.tag = 9999; 
        
        @try {
            [row removeFromSuperview];
            row.translatesAutoresizingMaskIntoConstraints = YES;
        } @catch (NSException *e) {}
        
        CGFloat h = 45; 
        row.frame = CGRectMake(15, *offset, 550, h);
        row.backgroundColor = [UIColor clearColor];
        
        UIColor *goldColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
        
        for (UIView *v in row.subviews) {
            if ([v isKindOfClass:[UILabel class]]) {
                UILabel *lbl = (UILabel *)v;
                lbl.textColor = [UIColor whiteColor]; 
                lbl.font = [UIFont boldSystemFontOfSize:17]; 
                [lbl sizeToFit];
            } else if ([v isKindOfClass:[UISwitch class]]) {
                UISwitch *sw = (UISwitch *)v;
                sw.onTintColor = goldColor; 
            } else if ([v isKindOfClass:[UISlider class]]) {
                UISlider *sl = (UISlider *)v;
                sl.minimumTrackTintColor = goldColor;
                sl.thumbTintColor = goldColor;
            } else if ([v isKindOfClass:[UISegmentedControl class]]) {
                UISegmentedControl *seg = (UISegmentedControl *)v;
                if (@available(iOS 13.0, *)) seg.selectedSegmentTintColor = goldColor;
                else seg.tintColor = goldColor;
                [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
                [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]} forState:UIControlStateSelected];
            }
        }
        
        [scroll addSubview:row];
        *offset += h + 10; 
        scroll.contentSize = CGSizeMake(580, *offset + 20); 
    });
}

// مسافات التمرير للأقسام الثلاثة التي تحتوي على أزرار
static CGFloat tabOffset0 = 10; 
static CGFloat tabOffset1 = 10; 
static CGFloat tabOffset2 = 10; 

static void continuousRadar(__weak UIView *mainMenu, __weak UIView *ipaBlackUI) {
    if (!mainMenu || !ipaBlackUI) return; 
    
    // --- 1. رادار الأيقونة العائمة ---
    static BOOL didChangeFloatingButton = NO;
    if (!didChangeFloatingButton) {
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            for (UIView *view in window.subviews) {
                BOOL isFloatingButton = NO;
                for (UIGestureRecognizer *rec in view.gestureRecognizers) {
                    if ([rec isKindOfClass:[UIPanGestureRecognizer class]]) {
                        isFloatingButton = YES; break;
                    }
                }
                
                if (isFloatingButton && view.bounds.size.width >= 35 && view.bounds.size.width <= 90) {
                    if ([view isKindOfClass:[UIButton class]]) {
                        [(UIButton *)view setImage:nil forState:UIControlStateNormal];
                        [(UIButton *)view setBackgroundImage:nil forState:UIControlStateNormal];
                    }
                    
                    UIImageView *iconOverlay = [view viewWithTag:888999];
                    if (!iconOverlay) {
                        iconOverlay = [[UIImageView alloc] initWithFrame:view.bounds];
                        iconOverlay.tag = 888999;
                        iconOverlay.layer.cornerRadius = view.bounds.size.width / 2.0;
                        iconOverlay.clipsToBounds = YES;
                        iconOverlay.userInteractionEnabled = NO;
                        iconOverlay.contentMode = UIViewContentModeScaleAspectFill;
                        
                        UIColor *goldColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
                        iconOverlay.layer.borderWidth = 2.0;
                        iconOverlay.layer.borderColor = goldColor.CGColor;
                        
                        [view addSubview:iconOverlay];
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://up6.cc/2026/09/178839084819181.jpeg"]];
                            if (imgData) {
                                UIImage *img = [UIImage imageWithData:imgData];
                                if (img) {
                                    dispatch_async(dispatch_get_main_queue(), ^{ iconOverlay.image = img; });
                                }
                            }
                        });
                    }
                    didChangeFloatingButton = YES;
                    break;
                }
            }
        }
    }
    
    // --- 2. رادار القوائم (توقع، طريقة العرض، لعب تلقائي) ---
    UIScrollView *tabPredict = (UIScrollView *)[ipaBlackUI viewWithTag:8000];
    UIScrollView *tabVisuals = (UIScrollView *)[ipaBlackUI viewWithTag:8001];
    UIScrollView *tabAutoPlay = (UIScrollView *)[ipaBlackUI viewWithTag:8002];
    
    // تم إضافة جميع الأزرار والخصائص لكل قسم
    NSArray *predictionTargets = @[@"خطوط التوقع", @"توقع الخصم", @"حدود الطاولة", @"تنبيه الكره الخاطئة", @"حماية البث", @"مؤشرات الجيوب", @"نقاط النهاية", @"مسارات دقيقة", @"توقع الكسرة", @"توقع الضربه القويه"];
    NSArray *visualTargets = @[@"طريقة العرض", @"إزاحة Y", @"إزاحة X", @"مقياس X", @"مقياس Y", @"سمك الخط", @"شفافية الخط", @"حلقة الجيب"];
    NSArray *autoPlayTargets = @[@"زر الاختصار", @"إيقاف عند اللمس", @"نمط دوران", @"وضع التصويب", @"أسلوب اللعب", @"مستوى اللعب", @"قوة التصويب", @"سرعة تصويب"];
    
    if (tabPredict) {
        for (NSString *name in predictionTargets) {
            UILabel *lbl = findLabel(mainMenu, name);
            if (lbl) hijackRow(getRowForLabel(lbl), tabPredict, &tabOffset0);
        }
    }
    if (tabVisuals) {
        for (NSString *name in visualTargets) {
            UILabel *lbl = findLabel(mainMenu, name);
            if (lbl) hijackRow(getRowForLabel(lbl), tabVisuals, &tabOffset1);
        }
    }
    if (tabAutoPlay) {
        for (NSString *name in autoPlayTargets) {
            UILabel *lbl = findLabel(mainMenu, name);
            if (lbl) hijackRow(getRowForLabel(lbl), tabAutoPlay, &tabOffset2);
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        continuousRadar(mainMenu, ipaBlackUI);
    });
}

// ==========================================
// 4. دوال مساعدة
// ==========================================
static NSString* decodeBase64(NSString *encoded) {
    if (!encoded) return @""; 
    NSData *data = [[NSData alloc] initWithBase64EncodedString:encoded options:0];
    if (!data) return @"";
    NSString *decoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return decoded ? decoded : @"";
}

// ==========================================
// 5. بناء الواجهة الرئيسية (Main UI)
// ==========================================
%hook GBModMenu

%new
- (void)tabChanged:(UISegmentedControl *)sender {
    UIView *ipaBlackUI = [self viewWithTag:7777];
    // لدينا 4 أقسام الآن (توقع، عرض، لعب تلقائي، إعدادات)
    for (int i = 0; i < 4; i++) {
        UIView *container = [ipaBlackUI viewWithTag:8000 + i];
        container.hidden = (i != sender.selectedSegmentIndex);
    }
}

%new
- (void)openChannel {
    NSString *url = decodeBase64(@"aHR0cHM6Ly90Lm1lL2hsMDBzcw=="); 
    if (url.length > 0) { [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil]; }
}

%new
- (void)openDev {
    NSString *url = decodeBase64(@"aHR0cHM6Ly90Lm1lL2lwYV9ibGFjaw==");
    if (url.length > 0) { [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil]; }
}

- (void)layoutSubviews {
    %orig;
    
    if (![self isKindOfClass:[UIView class]]) return;
    UIView *mainMenu = (UIView *)self;
    
    if (mainMenu.bounds.size.width != 620 || mainMenu.bounds.size.height != 400) {
        CGRect newBounds = mainMenu.bounds;
        newBounds.size.width = 620;  
        newBounds.size.height = 400; 
        mainMenu.bounds = newBounds;
    }
    
    mainMenu.backgroundColor = [UIColor clearColor]; 
    mainMenu.layer.borderWidth = 0;
    
    UIColor *goldColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    UIColor *darkGrayBg = [UIColor colorWithRed:0.12 green:0.12 blue:0.14 alpha:0.98]; 
    
    UIView *ipaBlackUI = [mainMenu viewWithTag:7777];
    if (!ipaBlackUI) {
        ipaBlackUI = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 620, 400)];
        ipaBlackUI.tag = 7777;
        
        ipaBlackUI.backgroundColor = darkGrayBg; 
        ipaBlackUI.layer.borderColor = goldColor.CGColor;
        ipaBlackUI.layer.borderWidth = 1.5;
        ipaBlackUI.layer.cornerRadius = 15.0;
        ipaBlackUI.layer.shadowColor = goldColor.CGColor;
        ipaBlackUI.layer.shadowRadius = 15.0;
        ipaBlackUI.layer.shadowOpacity = 0.7; 
        
        [mainMenu addSubview:ipaBlackUI];
        
        // --- شريط التبويبات (أربعة أقسام) ---
        UISegmentedControl *tabs = [[UISegmentedControl alloc] initWithItems:@[@"التوقع", @"طريقة العرض", @"اللعب التلقائي", @"الإعدادات"]];
        tabs.frame = CGRectMake(20, 15, 580, 40);
        tabs.selectedSegmentIndex = 0; 
        [tabs addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
        
        if (@available(iOS 13.0, *)) {
            tabs.selectedSegmentTintColor = goldColor;
        } else {
            tabs.tintColor = goldColor;
        }
        [tabs setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:14]} forState:UIControlStateNormal];
        [tabs setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:14]} forState:UIControlStateSelected];
        [ipaBlackUI addSubview:tabs];
        
        // --- إنشاء قوائم التمرير للأقسام الأربعة ---
        for (int i = 0; i < 4; i++) {
            UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 65, 580, 315)];
            scrollView.tag = 8000 + i; 
            scrollView.backgroundColor = [UIColor clearColor]; 
            scrollView.showsVerticalScrollIndicator = NO; 
            scrollView.bounces = NO; 
            scrollView.alwaysBounceVertical = NO; 
            scrollView.hidden = (i != 0);
            [ipaBlackUI addSubview:scrollView];
        }
        
        // --- بناء قسم الإعدادات (أصبح التاج 8003 لأنه التبويب الرابع) ---
        UIScrollView *tabSettings = (UIScrollView *)[ipaBlackUI viewWithTag:8003];
        UIImageView *profilePic = [[UIImageView alloc] initWithFrame:CGRectMake(240, 20, 100, 100)];
        profilePic.layer.cornerRadius = 50;
        profilePic.layer.masksToBounds = YES;
        profilePic.layer.borderWidth = 2.0;
        profilePic.layer.borderColor = goldColor.CGColor;
        profilePic.backgroundColor = [UIColor blackColor];
        [tabSettings addSubview:profilePic];
        
        __weak UIImageView *weakProfilePic = profilePic;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSURL *url = [NSURL URLWithString:@"https://up6.cc/2026/09/178839084819181.jpeg"];
            NSData *imgData = [NSData dataWithContentsOfURL:url];
            if (imgData) {
                UIImage *img = [UIImage imageWithData:imgData];
                if (img) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakProfilePic) weakProfilePic.image = img;
                    });
                }
            }
        });
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 135, 580, 30)];
        nameLabel.text = @"IPA BLACK Premium Mod";
        nameLabel.textColor = goldColor;
        nameLabel.font = [UIFont boldSystemFontOfSize:22];
        nameLabel.textAlignment = NSTextAlignmentCenter;
        [tabSettings addSubview:nameLabel];
        
        UIButton *btnChannel = [UIButton buttonWithType:UIButtonTypeCustom];
        btnChannel.frame = CGRectMake(190, 190, 200, 45);
        [btnChannel setTitle:@"قناة التيليجرام" forState:UIControlStateNormal];
        [btnChannel setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        btnChannel.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        btnChannel.backgroundColor = goldColor;
        btnChannel.layer.cornerRadius = 8;
        [btnChannel addTarget:self action:@selector(openChannel) forControlEvents:UIControlEventTouchUpInside];
        [tabSettings addSubview:btnChannel];
        
        UIButton *btnDev = [UIButton buttonWithType:UIButtonTypeCustom];
        btnDev.frame = CGRectMake(190, 250, 200, 45);
        [btnDev setTitle:@"التواصل مع المطور" forState:UIControlStateNormal];
        [btnDev setTitleColor:goldColor forState:UIControlStateNormal];
        btnDev.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        btnDev.backgroundColor = [UIColor clearColor];
        btnDev.layer.borderColor = goldColor.CGColor;
        btnDev.layer.borderWidth = 1.0;
        btnDev.layer.cornerRadius = 8;
        [btnDev addTarget:self action:@selector(openDev) forControlEvents:UIControlEventTouchUpInside];
        [tabSettings addSubview:btnDev];
        
        tabSettings.contentSize = CGSizeMake(580, 320);
        
        continuousRadar(mainMenu, ipaBlackUI);
    }
    
    if (mainMenu.subviews.lastObject != ipaBlackUI) {
        [mainMenu bringSubviewToFront:ipaBlackUI];
    }
}
%end
