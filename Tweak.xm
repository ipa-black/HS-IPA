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
// 1. تعريف الكلاسات
// ==========================================
@interface GBModMenu : UIView
- (void)tabChanged:(UISegmentedControl *)sender;
- (void)openChannel;
- (void)openDev;
- (void)handlePan:(UIPanGestureRecognizer *)recognizer;
- (void)toggleSize;
@end

@interface CBToggle : UIButton
@property (nonatomic, weak) UISwitch *targetSwitch; 
@property (nonatomic, strong) NSString *baseTitle;
- (void)updateLook;
@end

// ==========================================
// 2. برمجة زر الصح (حفظ الإعدادات)
// ==========================================
@implementation CBToggle
- (void)btnTapped {
    if (!self.targetSwitch) return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL newState = !self.targetSwitch.isOn;
        [self.targetSwitch setOn:newState animated:YES];
        [self.targetSwitch sendActionsForControlEvents:UIControlEventValueChanged];
        [self.targetSwitch sendActionsForControlEvents:UIControlEventTouchUpInside];
        
        NSString *saveKey = [NSString stringWithFormat:@"IPABLACK_SAVE_%@", self.baseTitle];
        [[NSUserDefaults standardUserDefaults] setBool:newState forKey:saveKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self updateLook];
    });
}
- (void)updateLook {
    if (!self.targetSwitch) return;
    
    UIColor *goldColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
    
    if (self.targetSwitch.isOn) {
        [self setTitle:[NSString stringWithFormat:@"✔  %@", self.baseTitle] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:0.85];
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = goldColor.CGColor;
    } else {
        [self setTitle:[NSString stringWithFormat:@"☐  %@", self.baseTitle] forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:0.5].CGColor;
    }
}
@end

// ==========================================
// 3. تغيير الأسماء الأصلية (Hooks)
// ==========================================
%hook UILabel
- (void)setText:(NSString *)text {
    @try {
        if (text != nil && [text isKindOfClass:[NSString class]]) {
            NSString *newText = text;
            if ([text containsString:@"i3rby Store"]) { newText = @"IPA BLACK"; }
            else if ([text containsString:@"ايفون بالعربي"]) { newText = @""; }
            // [إصلاح ذكي]: المطابقة الدقيقة لأسماء الأزرار فقط لعدم تدمير نسبة الكسرة العائمة
            else if ([text isEqualToString:@"وضع الكسر"] || [text isEqualToString:@"توقع الكسر"]) { newText = @"توقع الكسرة"; }
            else if ([text isEqualToString:@"البشرنة"]) { newText = @"أسلوب اللعب"; }
            else if ([text isEqualToString:@"السحب الابتدائي"]) { newText = @"توقع الضربه القويه"; }
            else if ([text isEqualToString:@"الكره الخاطئة"]) { newText = @"تنبيه الكره الخاطئة"; }
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
// 4. محرك البناء والخطف الدقيق
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

static void hijackRow(UIView *row, NSString *targetName, UIScrollView *scroll, CGFloat *offset) {
    if (!row || !scroll) return;
    
    // --- [فلتر الذكاء الاصطناعي]: التأكد أن هذا الصف هو زر للمنيو وليس نص عائم (كنسبة الكسرة) ---
    BOOL hasControlElement = NO;
    for (UIView *v in row.subviews) {
        if ([v isKindOfClass:[UISwitch class]] || [v isKindOfClass:[UISlider class]] || [v isKindOfClass:[UISegmentedControl class]]) {
            hasControlElement = YES;
            break;
        }
    }
    if (!hasControlElement) return; // إذا كان مجرد نص عائم للعبة، اتركه في حاله!
    
    row.tag = 9999; 
    
    @try {
        [row removeFromSuperview];
        row.translatesAutoresizingMaskIntoConstraints = YES;
    } @catch (NSException *e) {}
    
    CGFloat h = 45; 
    row.frame = CGRectMake(15, *offset, 550, h);
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
        
        NSString *saveKey = [NSString stringWithFormat:@"IPABLACK_SAVE_%@", targetName];
        if ([[[NSUserDefaults standardUserDefaults] dictionaryRepresentation].allKeys containsObject:saveKey]) {
            BOOL savedState = [[NSUserDefaults standardUserDefaults] boolForKey:saveKey];
            if (sw.isOn != savedState) {
                [sw setOn:savedState animated:NO];
                [sw sendActionsForControlEvents:UIControlEventValueChanged];
            }
        }
        
        CBToggle *btn = [CBToggle buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, 0, 550, h);
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 15, 0, 0);
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:17];
        btn.layer.cornerRadius = 10;
        btn.baseTitle = targetName;
        btn.targetSwitch = sw;
        
        [btn addTarget:btn action:@selector(btnTapped) forControlEvents:UIControlEventTouchUpInside];
        [btn updateLook]; 
        
        [row addSubview:btn];
    } else {
        UIColor *goldColor = [UIColor colorWithRed:1.0 green:0.84 blue:0.0 alpha:1.0];
        
        if (txt) { txt.textColor = [UIColor whiteColor]; txt.font = [UIFont boldSystemFontOfSize:17]; }
        if (sl) { sl.minimumTrackTintColor = goldColor; sl.thumbTintColor = goldColor; }
        if (seg) {
            if (@available(iOS 13.0, *)) seg.selectedSegmentTintColor = goldColor;
            else seg.tintColor = goldColor;
            [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
            [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor]} forState:UIControlStateSelected];
        }
    }
    
    [scroll addSubview:row];
    *offset += h + 10; 
    scroll.contentSize = CGSizeMake(580, *offset + 20); 
}

static CGFloat tabOffset0 = 10; 

static UIWindow* getModernKeyWindow() {
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) return window;
                }
            }
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
}

static void continuousRadar(__weak UIView *mainMenu, __weak UIView *ipaBlackUI) {
    if (!mainMenu || !ipaBlackUI) return; 
    
    // --- 1. رادار الأيقونة العائمة ---
    static BOOL didChangeFloatingButton = NO;
    if (!didChangeFloatingButton) {
        UIWindow *window = getModernKeyWindow();
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
    
    // --- 2. رادار القوائم (قسم التوقع والإعدادات فقط) ---
    UIScrollView *tabPredict = (UIScrollView *)[ipaBlackUI viewWithTag:8000];
    
    // إزالة كلمات "الكسر" العامة لتجنب سحب النصوص العائمة
    NSArray *predictionTargets = @[
        @"خطوط التوقع", @"توقع الخصم", @"حدود الطاولة", @"تنبيه الكره الخاطئة", @"الكره الخاطئة", 
        @"حماية البث", @"مؤشرات الجيوب", @"نقاط النهاية", @"مسارات دقيقة", @"توقع الكسرة", @"وضع الكسر", 
        @"توقع الضربه القويه", @"السحب الابتدائي", @"الوان الكرات", @"ألوان الكرات", @"الكرات", 
        @"تمييز", @"تميز", @"سادة ومخطط", @"عصا", @"طول العصا", @"طويلة", @"الرسوم", @"طريقة العرض"
    ];
    
    if (tabPredict) {
        for (NSString *name in predictionTargets) {
            UILabel *lbl = findLabel(mainMenu, name);
            if (lbl) hijackRow(getRowForLabel(lbl), name, tabPredict, &tabOffset0);
        }
    }
    
    for (UIView *sub in mainMenu.subviews) {
        if (sub.tag != 7777) {
            sub.alpha = 0.0;
            sub.userInteractionEnabled = NO;
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        continuousRadar(mainMenu, ipaBlackUI);
    });
}

// ==========================================
// 5. دوال مساعدة
// ==========================================
static NSString* decodeBase64(NSString *encoded) {
    if (!encoded) return @""; 
    NSData *data = [[NSData alloc] initWithBase64EncodedString:encoded options:0];
    if (!data) return @"";
    NSString *decoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return decoded ? decoded : @"";
}

// ==========================================
// 6. بناء الواجهة الرئيسية
// ==========================================
%hook GBModMenu

%new
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    UIView *ipaBlackUI = [self viewWithTag:7777];
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self];
        ipaBlackUI.center = CGPointMake(ipaBlackUI.center.x + translation.x, ipaBlackUI.center.y + translation.y);
        [recognizer setTranslation:CGPointZero inView:self];
    }
}

%new
- (void)toggleSize {
    UIView *ipaBlackUI = [self viewWithTag:7777];
    UIView *miniLogo = [ipaBlackUI viewWithTag:5555];
    UIButton *btnMax = (UIButton *)[ipaBlackUI viewWithTag:5556];
    
    BOOL isMin = ipaBlackUI.bounds.size.width < 100;

    [UIView animateWithDuration:0.3 animations:^{
        if (!isMin) {
            ipaBlackUI.bounds = CGRectMake(0, 0, 60, 60);
            ipaBlackUI.layer.cornerRadius = 30;
            for (UIView *sub in ipaBlackUI.subviews) {
                if (sub.tag != 5555 && sub.tag != 5556) sub.alpha = 0.0;
            }
            miniLogo.alpha = 1.0;
            btnMax.hidden = NO;
        } else {
            ipaBlackUI.bounds = CGRectMake(0, 0, 620, 400);
            ipaBlackUI.layer.cornerRadius = 15;
            for (UIView *sub in ipaBlackUI.subviews) {
                if (sub.tag != 5555 && sub.tag != 5556) {
                    if (sub.tag == 8000 || sub.tag == 8001) {
                        UISegmentedControl *tabs = (UISegmentedControl *)[ipaBlackUI viewWithTag:12345];
                        if (tabs && (sub.tag - 8000) != tabs.selectedSegmentIndex) {
                            sub.alpha = 0.0;
                        } else {
                            sub.alpha = 1.0;
                        }
                    } else {
                        sub.alpha = 1.0;
                    }
                }
            }
            miniLogo.alpha = 0.0;
            btnMax.hidden = YES;
        }
    }];
}

%new
- (void)tabChanged:(UISegmentedControl *)sender {
    UIView *ipaBlackUI = [self viewWithTag:7777];
    for (int i = 0; i < 2; i++) {
        UIView *container = [ipaBlackUI viewWithTag:8000 + i];
        container.hidden = (i != sender.selectedSegmentIndex);
        
        if (i == sender.selectedSegmentIndex) {
            container.alpha = 1.0;
        } else {
            container.alpha = 0.0;
        }
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
        tabOffset0 = 10;
        
        ipaBlackUI = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 620, 400)];
        ipaBlackUI.tag = 7777;
        
        ipaBlackUI.backgroundColor = darkGrayBg; 
        ipaBlackUI.layer.borderColor = goldColor.CGColor;
        ipaBlackUI.layer.borderWidth = 1.5;
        ipaBlackUI.layer.cornerRadius = 15.0;
        ipaBlackUI.layer.shadowColor = goldColor.CGColor;
        ipaBlackUI.layer.shadowRadius = 15.0;
        ipaBlackUI.layer.shadowOpacity = 0.7; 
        
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [ipaBlackUI addGestureRecognizer:panGesture];
        
        [mainMenu addSubview:ipaBlackUI];
        
        UIImageView *miniLogo = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        miniLogo.tag = 5555;
        miniLogo.layer.cornerRadius = 30;
        miniLogo.clipsToBounds = YES;
        miniLogo.alpha = 0.0; 
        miniLogo.layer.borderWidth = 2.0;
        miniLogo.layer.borderColor = goldColor.CGColor;
        [ipaBlackUI addSubview:miniLogo];
        
        UIButton *btnMax = [UIButton buttonWithType:UIButtonTypeCustom];
        btnMax.frame = CGRectMake(0, 0, 60, 60);
        btnMax.tag = 5556;
        [btnMax addTarget:self action:@selector(toggleSize) forControlEvents:UIControlEventTouchUpInside];
        btnMax.hidden = YES;
        [ipaBlackUI addSubview:btnMax];
        
        __weak UIImageView *weakMiniLogo = miniLogo;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSData *imgData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://up6.cc/2026/09/178839084819181.jpeg"]];
            if (imgData) {
                UIImage *img = [UIImage imageWithData:imgData];
                if (img) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakMiniLogo) weakMiniLogo.image = img;
                    });
                }
            }
        });

        UIButton *btnMin = [UIButton buttonWithType:UIButtonTypeCustom];
        btnMin.frame = CGRectMake(570, 15, 35, 35);
        [btnMin setTitle:@"➖" forState:UIControlStateNormal];
        btnMin.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
        btnMin.layer.cornerRadius = 8;
        btnMin.layer.borderWidth = 1;
        btnMin.layer.borderColor = goldColor.CGColor;
        [btnMin addTarget:self action:@selector(toggleSize) forControlEvents:UIControlEventTouchUpInside];
        [ipaBlackUI addSubview:btnMin];
        
        UISegmentedControl *tabs = [[UISegmentedControl alloc] initWithItems:@[@"التوقع", @"الإعدادات"]];
        tabs.frame = CGRectMake(20, 15, 530, 40); 
        tabs.tag = 12345;
        tabs.selectedSegmentIndex = 0; 
        [tabs addTarget:self action:@selector(tabChanged:) forControlEvents:UIControlEventValueChanged];
        
        if (@available(iOS 13.0, *)) { tabs.selectedSegmentTintColor = goldColor; } 
        else { tabs.tintColor = goldColor; }
        
        [tabs setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:15]} forState:UIControlStateNormal];
        [tabs setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont boldSystemFontOfSize:15]} forState:UIControlStateSelected];
        [ipaBlackUI addSubview:tabs];
        
        for (int i = 0; i < 2; i++) {
            UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(20, 65, 580, 315)];
            scrollView.tag = 8000 + i; 
            scrollView.backgroundColor = [UIColor clearColor]; 
            scrollView.showsVerticalScrollIndicator = YES; 
            scrollView.bounces = YES; 
            scrollView.alwaysBounceVertical = YES; 
            scrollView.scrollEnabled = YES;
            scrollView.hidden = (i != 0);
            [ipaBlackUI addSubview:scrollView];
        }
        
        UIScrollView *tabSettings = (UIScrollView *)[ipaBlackUI viewWithTag:8001];
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
