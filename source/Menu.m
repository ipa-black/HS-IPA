#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// ====================================================
// دوال الذاكرة (آمنة)
// ====================================================
void write_memory(uint64_t address, void *data, size_t size) {
    vm_write(mach_task_self(), (vm_address_t)address, (vm_offset_t)data, (vm_size_t)size);
}

void read_memory(uint64_t address, void *buffer, size_t size) {
    size_t outsize;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)address, (vm_size_t)size, (vm_address_t)buffer, &outsize);
    if (kr != KERN_SUCCESS) {
        // لا نفعل شيئًا عند الفشل
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

// ====================================================
// الحصول على النافذة الرئيسية
// ====================================================
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
// البحث عن النمط (مع حماية من الوصول الخاطئ)
// ====================================================
uint64_t find_pattern_in_library(const char *libName, const char *pattern) {
    uint64_t base = get_base_address(libName);
    if (base == 0) return 0;
    
    unsigned char bytes[64];
    char mask[64];
    size_t length = 0;
    
    const char *p = pattern;
    while (*p && length < 63) {
        if (p[0] == '?' && p[1] == '?') {
            bytes[length] = 0x00;
            mask[length] = '?';
            p += 2;
        } else {
            unsigned int val;
            if (sscanf(p, "%02X", &val) != 1) break;
            bytes[length] = (unsigned char)val;
            mask[length] = 'x';
            p += 2;
        }
        length++;
        if (*p == ' ') p++;
    }
    
    if (length == 0) return 0;
    
    // نبحث في نطاق محدود (50 ميجابايت) لتجنب المشاكل
    uint64_t searchSize = 0x5000000;
    for (uint64_t addr = base; addr < base + searchSize - length; addr++) {
        bool found = true;
        for (size_t i = 0; i < length; i++) {
            if (mask[i] == 'x') {
                unsigned char current;
                size_t outsize;
                kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)(addr + i), 1, (vm_address_t)&current, &outsize);
                if (kr != KERN_SUCCESS || current != bytes[i]) {
                    found = false;
                    break;
                }
            }
        }
        if (found) return addr;
    }
    return 0;
}

// ====================================================
// واجهة القائمة (مع السهم الطويل فقط)
// ====================================================
@interface IPABlackMenu : NSObject
@end

@implementation IPABlackMenu

static UIView *menuContainer = nil;
static uint64_t cachedLongLineAddress = 0;

+ (void)showMenu {
    if (menuContainer) return;
    
    UIWindow *window = getKeyWindow();
    if (!window) return;
    
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    menuContainer.center = window.center;
    menuContainer.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
    menuContainer.layer.cornerRadius = 15;
    menuContainer.layer.borderWidth = 1.5;
    menuContainer.layer.borderColor = [UIColor cyanColor].CGColor;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 300, 30)];
    title.text = @"IPA Black";
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:20];
    [menuContainer addSubview:title];
    
    UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 55, 300, 20)];
    subTitle.text = @"8 Ball Pool - VIP Hack";
    subTitle.textColor = [UIColor cyanColor];
    subTitle.textAlignment = NSTextAlignmentCenter;
    subTitle.font = [UIFont systemFontOfSize:13];
    [menuContainer addSubview:subTitle];
    
    // مفتاح السهم الطويل
    UILabel *lblLongLine = [[UILabel alloc] initWithFrame:CGRectMake(25, 100, 150, 30)];
    lblLongLine.text = @"السهم الطويل";
    lblLongLine.textColor = [UIColor whiteColor];
    lblLongLine.font = [UIFont boldSystemFontOfSize:15];
    [menuContainer addSubview:lblLongLine];
    
    UISwitch *toggleLongLine = [[UISwitch alloc] initWithFrame:CGRectMake(220, 100, 50, 30)];
    toggleLongLine.onTintColor = [UIColor cyanColor];
    [toggleLongLine addTarget:self action:@selector(toggleLongLineAction:) forControlEvents:UIControlEventValueChanged];
    [menuContainer addSubview:toggleLongLine];
    
    // زر الإغلاق
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(50, 140, 200, 45);
    [closeBtn setTitle:@"إغلاق" forState:UIControlStateNormal];
    closeBtn.backgroundColor = [UIColor redColor];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.layer.cornerRadius = 10;
    [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:closeBtn];
    
    [window addSubview:menuContainer];
    
    menuContainer.transform = CGAffineTransformMakeScale(0.8, 0.8);
    menuContainer.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        menuContainer.transform = CGAffineTransformIdentity;
        menuContainer.alpha = 1;
    }];
}

+ (void)toggleLongLineAction:(UISwitch *)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (cachedLongLineAddress == 0) {
            // ابحث في UnityFramework ثم libil2cpp.so
            uint64_t found = find_pattern_in_library("UnityFramework", "48 8B 05 ?? ?? ?? ?? F3 0F 10 00 C3");
            if (found == 0) {
                found = find_pattern_in_library("libil2cpp.so", "48 8B 05 ?? ?? ?? ?? F3 0F 10 00 C3");
            }
            if (found == 0) {
                // إذا لم نجد النمط، نرجع المفتاح إلى OFF ونخبر المستخدم
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sender setOn:NO animated:YES];
                });
                NSLog(@"[IPA BLACK] لم يتم العثور على نمط السهم الطويل");
                return;
            }
            cachedLongLineAddress = found + 0x4; // الإزاحة بعد النمط
            NSLog(@"[IPA BLACK] تم العثور على عنوان السهم الطويل: 0x%llx", cachedLongLineAddress);
        }
        
        float value = sender.isOn ? 20.0f : 1.0f;
        write_memory(cachedLongLineAddress, &value, sizeof(float));
        NSLog(@"[IPA BLACK] السهم الطويل %@ (%.2f)", sender.isOn ? @"مفعل" : @"معطل", value);
    });
}

+ (void)closeMenu {
    [UIView animateWithDuration:0.3 animations:^{
        menuContainer.alpha = 0;
    } completion:^(BOOL finished) {
        [menuContainer removeFromSuperview];
        menuContainer = nil;
    }];
}

@end

// ====================================================
// نقطة الانطلاق (تأخير 30 ثانية)
// ====================================================
static void __attribute__((constructor)) initialize_ipa_black() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = getKeyWindow();
        if (window) {
            UIButton *floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            floatingBtn.frame = CGRectMake(20, 100, 60, 60);
            floatingBtn.backgroundColor = [UIColor blackColor];
            floatingBtn.layer.cornerRadius = 30;
            floatingBtn.layer.borderWidth = 2.0;
            floatingBtn.layer.borderColor = [UIColor cyanColor].CGColor;
            [floatingBtn setTitle:@"IPA" forState:UIControlStateNormal];
            [floatingBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
            [floatingBtn addTarget:[IPABlackMenu class] action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
            [window addSubview:floatingBtn];
        }
    });
}
