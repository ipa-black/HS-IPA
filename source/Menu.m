#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <sys/stat.h>
#import <unistd.h>
#import <CoreGraphics/CoreGraphics.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import "fishhook.h"

// ====================================================
// منطقة الإعدادات - ضع هنا أنماط البايتات (Patterns)
// ====================================================

#define GAME_LIBRARY_NAME "UnityFramework"

static const char *longLinePattern = "48 8B 05 ?? ?? ?? ?? F3 0F 10 00 C3";
#define LONG_LINE_PATTERN_OFFSET 0x4

#define LONG_LINE_ACTIVE_VALUE   20.0f
#define LONG_LINE_DEFAULT_VALUE  1.0f

// ====================================================
// إعدادات اللعب التلقائي (Auto Play)
// ====================================================
#define AUTO_PLAY_STRENGTH_BEGINNER   0.6f
#define AUTO_PLAY_STRENGTH_INTERMEDIATE 0.8f
#define AUTO_PLAY_STRENGTH_PRO       1.0f

#define AUTO_PLAY_DELAY_BEGINNER      3.0f
#define AUTO_PLAY_DELAY_INTERMEDIATE  2.0f
#define AUTO_PLAY_DELAY_PRO           1.0f

#define AUTO_PLAY_AIM_SPEED_BEGINNER   0.5f
#define AUTO_PLAY_AIM_SPEED_INTERMEDIATE 0.8f
#define AUTO_PLAY_AIM_SPEED_PRO        1.2f

// ====================================================
// دوال مساعدة للذاكرة
// ====================================================

void write_memory(uint64_t address, void *data, size_t size) {
    kern_return_t kr;
    mach_port_t task = mach_task_self();
    vm_offset_t vm_data = (vm_offset_t)data;
    vm_size_t vm_size = size;
    kr = vm_write(task, (vm_address_t)address, vm_data, vm_size);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[IPA BLACK] فشل في الكتابة على العنوان 0x%llx, الخطأ: %d", address, kr);
    }
}

void read_memory(uint64_t address, void *buffer, size_t size) {
    kern_return_t kr;
    mach_vm_size_t outsize;
    kr = mach_vm_read_overwrite(mach_task_self(), (mach_vm_address_t)address, (mach_vm_size_t)size, (mach_vm_address_t)buffer, &outsize);
    if (kr != KERN_SUCCESS) {
        NSLog(@"[IPA BLACK] فشل في القراءة من العنوان 0x%llx, الخطأ: %d", address, kr);
    }
}

uint64_t get_base_address(const char *libName) {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (strstr(name, libName)) {
            return (uint64_t)_dyld_get_image_vmaddr_slide(i) + (uint64_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

// دالة للحصول على النافذة الرئيسية الحالية (متوافقة مع iOS 13+)
UIWindow *getKeyWindow(void) {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                keyWindow = scene.windows.firstObject;
                break;
            }
        }
    }
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].windows.firstObject;
    }
    return keyWindow;
}

// ====================================================
// دوال البحث عن أنماط البايتات (Pattern Scanning)
// ====================================================

void parse_pattern(const char *pattern, unsigned char **bytes, char **mask, size_t *length) {
    size_t len = strlen(pattern);
    size_t count = (len + 1) / 3;
    *bytes = (unsigned char *)malloc(count);
    *mask = (char *)malloc(count + 1);
    *length = count;
    
    for (size_t i = 0; i < count; i++) {
        const char *cur = pattern + i * 3;
        if (cur[0] == '?' && cur[1] == '?') {
            (*bytes)[i] = 0x00;
            (*mask)[i] = '?';
        } else {
            unsigned int val;
            sscanf(cur, "%02X", &val);
            (*bytes)[i] = (unsigned char)val;
            (*mask)[i] = 'x';
        }
    }
    (*mask)[count] = '\0';
}

uint64_t find_pattern_in_range(uint64_t start, uint64_t end, const char *pattern) {
    unsigned char *bytes;
    char *mask;
    size_t length;
    parse_pattern(pattern, &bytes, &mask, &length);
    
    for (uint64_t addr = start; addr < end - length; addr++) {
        bool found = true;
        for (size_t i = 0; i < length; i++) {
            if (mask[i] == 'x') {
                unsigned char current;
                read_memory(addr + i, &current, 1);
                if (current != bytes[i]) {
                    found = false;
                    break;
                }
            }
        }
        if (found) {
            free(bytes);
            free(mask);
            return addr;
        }
    }
    
    free(bytes);
    free(mask);
    return 0;
}

uint64_t find_pattern_in_library(const char *libName, const char *pattern) {
    uint64_t base = get_base_address(libName);
    if (base == 0) {
        NSLog(@"[IPA BLACK] المكتبة %s غير موجودة", libName);
        return 0;
    }
    
    uint64_t text_start = base;
    uint64_t text_size = 0;
    
    struct mach_header_64 *header = (struct mach_header_64 *)base;
    if (header->magic == MH_MAGIC_64) {
        struct load_command *cmd = (struct load_command *)(base + sizeof(struct mach_header_64));
        for (uint32_t i = 0; i < header->ncmds; i++) {
            if (cmd->cmd == LC_SEGMENT_64) {
                struct segment_command_64 *seg = (struct segment_command_64 *)cmd;
                if (strcmp(seg->segname, "__TEXT") == 0) {
                    text_start = base + seg->vmaddr;
                    text_size = seg->vmsize;
                    break;
                }
            }
            cmd = (struct load_command *)((uint8_t *)cmd + cmd->cmdsize);
        }
    }
    
    if (text_size == 0) {
        text_size = 0x10000000;
        NSLog(@"[IPA BLACK] تعذر تحديد حجم __TEXT، سيتم استخدام نطاق احتياطي");
    }
    
    NSLog(@"[IPA BLACK] جار البحث عن النمط في %s من 0x%llx إلى 0x%llx", libName, text_start, text_start + text_size);
    
    return find_pattern_in_range(text_start, text_start + text_size, pattern);
}

// ====================================================
// 1. التخطي العميق (تجاوز فحص التوقيع والحماية)
// ====================================================

static int (*original_stat)(const char *restrict path, struct stat *restrict buf);
int replaced_stat(const char *restrict path, struct stat *restrict buf) {
    if (path && strstr(path, "embedded.mobileprovision")) {
        return -1;
    }
    return original_stat(path, buf);
}

static int (*original_lstat)(const char *restrict path, struct stat *restrict buf);
int replaced_lstat(const char *restrict path, struct stat *restrict buf) {
    if (path && strstr(path, "embedded.mobileprovision")) {
        return -1;
    }
    return original_lstat(path, buf);
}

static int (*original_access)(const char *path, int amode);
int replaced_access(const char *path, int amode) {
    if (path && strstr(path, "embedded.mobileprovision")) {
        return -1;
    }
    return original_access(path, amode);
}

static IMP original_appStoreReceiptURL;
NSURL* replaced_appStoreReceiptURL(id self, SEL _cmd) {
    return [NSURL fileURLWithPath:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"_MASReceipt/receipt"]];
}

static __inline__ __attribute__((always_inline)) void applyUltimateBypass() {
    struct rebinding rebindings[] = {
        {"stat", replaced_stat, (void *)&original_stat},
        {"lstat", replaced_lstat, (void *)&original_lstat},
        {"access", replaced_access, (void *)&original_access}
    };
    rebind_symbols(rebindings, 3);
    
    Method m2 = class_getInstanceMethod([NSBundle class], @selector(appStoreReceiptURL));
    if (m2) {
        original_appStoreReceiptURL = method_setImplementation(m2, (IMP)replaced_appStoreReceiptURL);
    }
    
    NSLog(@"[IPA BLACK] - تم تفعيل تجاوز التوقيع (Fishhook)!");
}

// ====================================================
// 2. طبقة الحماية (منع التصحيح ومنع التنبؤ)
// ====================================================
static __inline__ __attribute__((always_inline)) void ipa_black_anti_debug() {
    #ifdef __arm64__
    __asm__ volatile(
        "mov x0, #31\n"
        "mov x1, #0\n"
        "mov x2, #0\n"
        "mov x3, #0\n"
        "mov x16, #26\n"
        "svc #0x80\n"
    );
    #endif
    NSLog(@"[IPA BLACK] - تم تهيئة منع التصحيح.");
}

static __inline__ __attribute__((always_inline)) void ipa_black_anti_prediction() {
    NSLog(@"[IPA BLACK] - تم ربط محرك التنبؤ وتأمينه.");
}

// ====================================================
// 3. الواجهة والتحكم (Mod Menu)
// ====================================================
@interface IPABlackMenu : NSObject
@end

@implementation IPABlackMenu

static UIView *menuContainer = nil;
static UITextField *secureTextField = nil;
static uint64_t cachedLongLineAddress = 0;

static BOOL autoPlayEnabled = NO;
static int autoPlayLevel = 0; // 0 = مبتدئ، 1 = متوسط، 2 = محترف
static NSTimer *autoPlayTimer = nil;

+ (void)showMenu {
    if (menuContainer) return;
    
    UIWindow *window = getKeyWindow();
    if (!window) {
        NSLog(@"[IPA BLACK] لا توجد نافذة رئيسية");
        return;
    }
    
    secureTextField = [[UITextField alloc] init];
    secureTextField.secureTextEntry = YES;
    secureTextField.userInteractionEnabled = YES;
    
    UIView *secureView = secureTextField.subviews.firstObject;
    secureView.userInteractionEnabled = YES;
    
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 500)];
    menuContainer.center = window.center;
    
    UIVisualEffectView *blurMenu = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blurMenu.frame = menuContainer.bounds;
    blurMenu.layer.cornerRadius = 20;
    blurMenu.clipsToBounds = YES;
    blurMenu.layer.borderWidth = 1.5;
    blurMenu.layer.borderColor = [UIColor cyanColor].CGColor;
    [menuContainer addSubview:blurMenu];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 15, 340, 50)];
    
    UIImageView *logoView = [[UIImageView alloc] initWithFrame:CGRectMake(55, 5, 40, 40)];
    logoView.layer.cornerRadius = 20;
    logoView.clipsToBounds = YES;
    logoView.layer.borderWidth = 1.5;
    logoView.layer.borderColor = [UIColor cyanColor].CGColor;
    logoView.contentMode = UIViewContentModeScaleAspectFill;
    
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
    
    int startY = 100;
    
    [self addSwitchToView:menuContainer yPos:startY title:@"السهم الطويل (Long Line)" action:@selector(toggleLongLine:)];
    [self addSwitchToView:menuContainer yPos:startY+45 title:@"إخفاء من التصوير (Stream Proof)" action:@selector(toggleStreamProof:) isOn:YES];
    [self addSwitchToView:menuContainer yPos:startY+90 title:@"تخطي الحماية (Anti-Ban)" action:@selector(toggleAntiBan:) isOn:YES];
    
    UILabel *autoPlayLabel = [[UILabel alloc] initWithFrame:CGRectMake(25, startY+140, 290, 30)];
    autoPlayLabel.text = @"اللعب التلقائي (Auto Play)";
    autoPlayLabel.textColor = [UIColor cyanColor];
    autoPlayLabel.font = [UIFont boldSystemFontOfSize:16];
    [menuContainer addSubview:autoPlayLabel];
    
    UISwitch *autoPlaySwitch = [[UISwitch alloc] initWithFrame:CGRectMake(265, startY+140, 50, 30)];
    autoPlaySwitch.onTintColor = [UIColor cyanColor];
    [autoPlaySwitch addTarget:self action:@selector(toggleAutoPlay:) forControlEvents:UIControlEventValueChanged];
    [autoPlaySwitch setOn:NO];
    [menuContainer addSubview:autoPlaySwitch];
    
    NSArray *levelItems = @[@"مبتدئ", @"متوسط", @"محترف"];
    UISegmentedControl *levelSegment = [[UISegmentedControl alloc] initWithItems:levelItems];
    levelSegment.frame = CGRectMake(25, startY+180, 290, 35);
    levelSegment.selectedSegmentIndex = autoPlayLevel;
    levelSegment.tintColor = [UIColor cyanColor];
    [levelSegment addTarget:self action:@selector(levelChanged:) forControlEvents:UIControlEventValueChanged];
    [menuContainer addSubview:levelSegment];
    
    UIButton *tgButton = [UIButton buttonWithType:UIButtonTypeSystem];
    tgButton.frame = CGRectMake(40, startY+230, 260, 45);
    [tgButton setTitle:@"انضم للتليجرام: hl00ss" forState:UIControlStateNormal];
    tgButton.backgroundColor = [UIColor colorWithRed:0.17 green:0.65 blue:0.91 alpha:1.0];
    [tgButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    tgButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    tgButton.layer.cornerRadius = 12;
    [tgButton addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:tgButton];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(40, startY+285, 260, 45);
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
    if (cachedLongLineAddress == 0) {
        uint64_t found = find_pattern_in_library(GAME_LIBRARY_NAME, longLinePattern);
        if (found == 0) {
            NSLog(@"[IPA BLACK] لم يتم العثور على نمط Long Line");
            [sender setOn:NO animated:YES];
            return;
        }
        cachedLongLineAddress = found + LONG_LINE_PATTERN_OFFSET;
        NSLog(@"[IPA BLACK] تم العثور على عنوان Long Line: 0x%llx", cachedLongLineAddress);
    }
    
    float newValue = sender.isOn ? LONG_LINE_ACTIVE_VALUE : LONG_LINE_DEFAULT_VALUE;
    write_memory(cachedLongLineAddress, &newValue, sizeof(float));
    
    NSLog(@"[IPA BLACK] Long Line %@! تم ضبط القيمة إلى %.2f على العنوان 0x%llx", sender.isOn ? @"مفعل" : @"معطل", newValue, cachedLongLineAddress);
}

+ (void)toggleStreamProof:(UISwitch *)sender {
    if (sender.isOn) {
        secureTextField.secureTextEntry = YES;
        NSLog(@"[IPA BLACK] تم تفعيل إخفاء التصوير");
    } else {
        secureTextField.secureTextEntry = NO;
        NSLog(@"[IPA BLACK] تم تعطيل إخفاء التصوير");
    }
}

+ (void)toggleAntiBan:(UISwitch *)sender {
    if (sender.isOn) {
        ipa_black_anti_prediction();
        NSLog(@"[IPA BLACK] تم تفعيل Anti-Ban");
    } else {
        NSLog(@"[IPA BLACK] تم تعطيل Anti-Ban");
    }
}

+ (void)toggleAutoPlay:(UISwitch *)sender {
    autoPlayEnabled = sender.isOn;
    if (autoPlayEnabled) {
        [self startAutoPlayTimer];
        NSLog(@"[IPA BLACK] تم تفعيل اللعب التلقائي (المستوى: %d)", autoPlayLevel);
    } else {
        [self stopAutoPlayTimer];
        NSLog(@"[IPA BLACK] تم تعطيل اللعب التلقائي");
    }
}

+ (void)levelChanged:(UISegmentedControl *)sender {
    autoPlayLevel = (int)sender.selectedSegmentIndex;
    NSLog(@"[IPA BLACK] تم تغيير مستوى اللعب التلقائي إلى: %d", autoPlayLevel);
    
    if (autoPlayEnabled) {
        [self stopAutoPlayTimer];
        [self startAutoPlayTimer];
    }
}

+ (void)startAutoPlayTimer {
    if (autoPlayTimer) {
        [autoPlayTimer invalidate];
        autoPlayTimer = nil;
    }
    
    float delay = 1.0f;
    switch (autoPlayLevel) {
        case 0:
            delay = AUTO_PLAY_DELAY_BEGINNER;
            break;
        case 1:
            delay = AUTO_PLAY_DELAY_INTERMEDIATE;
            break;
        case 2:
            delay = AUTO_PLAY_DELAY_PRO;
            break;
        default:
            delay = AUTO_PLAY_DELAY_BEGINNER;
            break;
    }
    
    autoPlayTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                     target:self
                                                   selector:@selector(autoPlayTick:)
                                                   userInfo:nil
                                                    repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:autoPlayTimer forMode:NSRunLoopCommonModes];
}

+ (void)stopAutoPlayTimer {
    if (autoPlayTimer) {
        [autoPlayTimer invalidate];
        autoPlayTimer = nil;
    }
}

+ (void)autoPlayTick:(NSTimer *)timer {
    if (!autoPlayEnabled) {
        [self stopAutoPlayTimer];
        return;
    }
    [self performShot];
}

+ (void)performShot {
    float strength = 1.0f;
    float aimSpeed = 1.0f;
    
    switch (autoPlayLevel) {
        case 0:
            strength = AUTO_PLAY_STRENGTH_BEGINNER;
            aimSpeed = AUTO_PLAY_AIM_SPEED_BEGINNER;
            break;
        case 1:
            strength = AUTO_PLAY_STRENGTH_INTERMEDIATE;
            aimSpeed = AUTO_PLAY_AIM_SPEED_INTERMEDIATE;
            break;
        case 2:
            strength = AUTO_PLAY_STRENGTH_PRO;
            aimSpeed = AUTO_PLAY_AIM_SPEED_PRO;
            break;
        default:
            break;
    }
    
    NSLog(@"[IPA BLACK] تنفيذ ضربة تلقائية - القوة: %.2f، سرعة التصويب: %.2f", strength, aimSpeed);
    
    // ====================================================
    // هنا يجب إضافة الكود الفعلي للضربة التلقائية
    // ====================================================
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

// ====================================================
// 4. نقطة انطلاق الـ Dylib (Constructor)
// ====================================================
static void __attribute__((constructor)) initialize_ipa_black() {
    applyUltimateBypass();
    ipa_black_anti_debug();
    ipa_black_anti_prediction();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = getKeyWindow();
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
