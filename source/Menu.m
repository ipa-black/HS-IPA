#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <sys/stat.h>
#import <unistd.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>

// ====================================================
// دوال الذاكرة (النظام فقط)
// ====================================================
void write_memory(uint64_t address, void *data, size_t size) {
    vm_write(mach_task_self(), (vm_address_t)address, (vm_offset_t)data, (vm_size_t)size);
}

void read_memory(uint64_t address, void *buffer, size_t size) {
    size_t outsize;
    vm_read_overwrite(mach_task_self(), (vm_address_t)address, (vm_size_t)size, (vm_address_t)buffer, &outsize);
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
// البحث عن الأنماط (يستخدم vm_read_overwrite)
// ====================================================
uint64_t find_pattern_in_library(const char *libName, const char *pattern) {
    uint64_t base = get_base_address(libName);
    if (base == 0) return 0;
    
    unsigned char bytes[64];
    char mask[64];
    size_t length = 0;
    
    const char *p = pattern;
    while (*p) {
        if (p[0] == '?' && p[1] == '?') {
            bytes[length] = 0x00;
            mask[length] = '?';
            p += 2;
        } else {
            unsigned int val;
            sscanf(p, "%02X", &val);
            bytes[length] = (unsigned char)val;
            mask[length] = 'x';
            p += 2;
        }
        length++;
        if (*p == ' ') p++;
    }
    
    uint64_t searchSize = 0x8000000; // 128 ميجابايت
    for (uint64_t addr = base; addr < base + searchSize - length; addr++) {
        bool found = true;
        for (size_t i = 0; i < length; i++) {
            if (mask[i] == 'x') {
                unsigned char current;
                size_t outsize;
                vm_read_overwrite(mach_task_self(), (vm_address_t)(addr + i), 1, (vm_address_t)&current, &outsize);
                if (current != bytes[i]) {
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
// واجهة الرسم (OverlayView)
// ====================================================
@interface OverlayView : UIView
@property (nonatomic, strong) NSArray *pocketPositions;   // مصفوفة CGPoint
@property (nonatomic, assign) CGFloat pocketRadius;        // نصف قطر الجيب
@property (nonatomic, assign) BOOL showPockets;            // إظهار الجيوب فقط
@property (nonatomic, assign) BOOL showGuideLines;         // إظهار خطوط التوجيه
@property (nonatomic, assign) CGPoint cueBallPosition;     // موقع الكرة البيضاء
@property (nonatomic, assign) float aimAngle;              // زاوية التصويب (بالراديان)
@end

@implementation OverlayView

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctx, 2.5);
    
    // رسم الجيوب
    if (self.showPockets && self.pocketPositions) {
        for (NSValue *val in self.pocketPositions) {
            CGPoint p = [val CGPointValue];
            CGRect circle = CGRectMake(p.x - self.pocketRadius, p.y - self.pocketRadius,
                                       self.pocketRadius * 2, self.pocketRadius * 2);
            CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.0 green:0.8 blue:0.9 alpha:0.7].CGColor);
            CGContextFillEllipseInRect(ctx, circle);
            CGContextSetStrokeColorWithColor(ctx, [UIColor cyanColor].CGColor);
            CGContextStrokeEllipseInRect(ctx, circle);
        }
    }
    
    // رسم خطوط التوجيه من الكرة البيضاء إلى الجيوب
    if (self.showGuideLines && self.pocketPositions) {
        for (NSValue *val in self.pocketPositions) {
            CGPoint pocket = [val CGPointValue];
            
            float dx = pocket.x - self.cueBallPosition.x;
            float dy = pocket.y - self.cueBallPosition.y;
            float angleToPocket = atan2f(dy, dx);
            
            float diff = fabsf(angleToPocket - self.aimAngle);
            if (diff > M_PI) diff = 2 * M_PI - diff;
            
            UIColor *lineColor;
            if (diff < 0.15) {
                lineColor = [UIColor redColor];        // الكرة البيضاء قد تدخل
            } else if (diff < 0.4) {
                lineColor = [UIColor yellowColor];     // قريب
            } else {
                lineColor = [UIColor cyanColor];       // بعيد
            }
            
            CGContextSetStrokeColorWithColor(ctx, lineColor.CGColor);
            CGContextMoveToPoint(ctx, self.cueBallPosition.x, self.cueBallPosition.y);
            CGContextAddLineToPoint(ctx, pocket.x, pocket.y);
            CGContextStrokePath(ctx);
        }
    }
}

@end

// ====================================================
// واجهة القائمة
// ====================================================
@interface IPABlackMenu : NSObject
@end

@implementation IPABlackMenu

static UIView *menuContainer = nil;
static OverlayView *overlayView = nil;
static uint64_t cachedLongLineAddress = 0;

// الإعدادات
static BOOL pocketsOverlayEnabled = NO;
static BOOL guideLinesEnabled = NO;
static CGFloat pocketRadius = 15.0;

// بيانات الكرة البيضاء (افتراضياً - يجب ربطها بالذاكرة لاحقاً)
static CGPoint cueBallPosition = {200, 400};
static float aimAngleValue = 0.0;

+ (void)showMenu {
    if (menuContainer) return;
    
    UIWindow *window = getKeyWindow();
    if (!window) return;
    
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 400)];
    menuContainer.center = window.center;
    menuContainer.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
    menuContainer.layer.cornerRadius = 15;
    menuContainer.clipsToBounds = YES;
    menuContainer.layer.borderWidth = 1.5;
    menuContainer.layer.borderColor = [UIColor cyanColor].CGColor;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 340, 30)];
    title.text = @"IPA Black";
    title.textColor = [UIColor whiteColor];
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:20];
    [menuContainer addSubview:title];
    
    UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 55, 340, 20)];
    subTitle.text = @"8 Ball Pool - VIP Hack";
    subTitle.textColor = [UIColor cyanColor];
    subTitle.textAlignment = NSTextAlignmentCenter;
    subTitle.font = [UIFont systemFontOfSize:13];
    [menuContainer addSubview:subTitle];
    
    int startY = 100;
    
    // السهم الطويل
    [self addSwitchToView:menuContainer yPos:startY title:@"السهم الطويل" action:@selector(toggleLongLineAction:)];
    
    // تحديد الجيوب
    [self addSwitchToView:menuContainer yPos:startY+45 title:@"تحديد الجيوب" action:@selector(togglePocketsOverlay:)];
    
    // خطوط التوجيه الذكية
    [self addSwitchToView:menuContainer yPos:startY+90 title:@"خطوط التوجيه الذكية" action:@selector(toggleGuideLines:)];
    
    // أزرار تكبير/تصغير الجيوب
    UIButton *increaseBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    increaseBtn.frame = CGRectMake(25, startY+140, 130, 35);
    [increaseBtn setTitle:@"جيب أكبر +" forState:UIControlStateNormal];
    [increaseBtn addTarget:self action:@selector(increasePocketSize) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:increaseBtn];
    
    UIButton *decreaseBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    decreaseBtn.frame = CGRectMake(170, startY+140, 130, 35);
    [decreaseBtn setTitle:@"جيب أصغر -" forState:UIControlStateNormal];
    [decreaseBtn addTarget:self action:@selector(decreasePocketSize) forControlEvents:UIControlEventTouchUpInside];
    [menuContainer addSubview:decreaseBtn];
    
    // زر الإغلاق
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(60, startY+200, 200, 45);
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

+ (void)addSwitchToView:(UIView *)view yPos:(int)y title:(NSString *)title action:(SEL)action {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(25, y, 180, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont boldSystemFontOfSize:14];
    [view addSubview:lbl];
    
    UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectMake(240, y, 50, 30)];
    toggle.onTintColor = [UIColor cyanColor];
    [toggle addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [view addSubview:toggle];
}

// --- السهم الطويل ---
+ (void)toggleLongLineAction:(UISwitch *)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (cachedLongLineAddress == 0) {
            uint64_t found = find_pattern_in_library("UnityFramework", "48 8B 05 ?? ?? ?? ?? F3 0F 10 00 C3");
            if (found == 0) {
                found = find_pattern_in_library("libil2cpp.so", "48 8B 05 ?? ?? ?? ?? F3 0F 10 00 C3");
            }
            if (found == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sender setOn:NO animated:YES];
                });
                return;
            }
            cachedLongLineAddress = found + 0x4;
        }
        
        float value = sender.isOn ? 20.0f : 1.0f;
        write_memory(cachedLongLineAddress, &value, sizeof(float));
    });
}

// --- تحديد الجيوب ---
+ (void)togglePocketsOverlay:(UISwitch *)sender {
    pocketsOverlayEnabled = sender.isOn;
    [self updateOverlayVisibility];
}

// --- خطوط التوجيه ---
+ (void)toggleGuideLines:(UISwitch *)sender {
    guideLinesEnabled = sender.isOn;
    [self updateOverlayVisibility];
}

// تحديث إظهار/إخفاء الطبقة وفق الإعدادات
+ (void)updateOverlayVisibility {
    if (!overlayView) {
        if (pocketsOverlayEnabled || guideLinesEnabled) {
            overlayView = [[OverlayView alloc] initWithFrame:[UIScreen mainScreen].bounds];
            overlayView.backgroundColor = [UIColor clearColor];
            overlayView.userInteractionEnabled = NO;
            overlayView.pocketPositions = [self getPocketPositionsFromMemory];
            overlayView.pocketRadius = pocketRadius;
            overlayView.cueBallPosition = cueBallPosition;
            overlayView.aimAngle = aimAngleValue;
            
            UIWindow *window = getKeyWindow();
            if (window) {
                [window addSubview:overlayView];
            }
        }
    }
    
    if (overlayView) {
        overlayView.showPockets = pocketsOverlayEnabled;
        overlayView.showGuideLines = guideLinesEnabled;
        overlayView.hidden = !(pocketsOverlayEnabled || guideLinesEnabled);
        overlayView.pocketRadius = pocketRadius;
        overlayView.pocketPositions = [self getPocketPositionsFromMemory];
        overlayView.cueBallPosition = cueBallPosition;
        overlayView.aimAngle = aimAngleValue;
        [overlayView setNeedsDisplay];
    }
}

// زيادة حجم الجيب
+ (void)increasePocketSize {
    pocketRadius += 2.0;
    if (pocketRadius > 30.0) pocketRadius = 30.0;
    [self updateOverlayVisibility];
}

// تقليل حجم الجيب
+ (void)decreasePocketSize {
    pocketRadius -= 2.0;
    if (pocketRadius < 5.0) pocketRadius = 5.0;
    [self updateOverlayVisibility];
}

// هذه الدالة يجب أن تملأها بالمنطق الصحيح لقراءة مواقع الجيوب من الذاكرة
+ (NSArray *)getPocketPositionsFromMemory {
    // حالياً نستخدم مواقع ثابتة تقريبية (يجب استبدالها بالقراءة الفعلية)
    NSMutableArray *positions = [NSMutableArray array];
    
    CGPoint p1 = CGPointMake(80, 180);
    CGPoint p2 = CGPointMake(320, 180);
    CGPoint p3 = CGPointMake(80, 550);
    CGPoint p4 = CGPointMake(320, 550);
    CGPoint p5 = CGPointMake(200, 130);
    CGPoint p6 = CGPointMake(200, 600);
    
    [positions addObject:[NSValue valueWithCGPoint:p1]];
    [positions addObject:[NSValue valueWithCGPoint:p2]];
    [positions addObject:[NSValue valueWithCGPoint:p3]];
    [positions addObject:[NSValue valueWithCGPoint:p4]];
    [positions addObject:[NSValue valueWithCGPoint:p5]];
    [positions addObject:[NSValue valueWithCGPoint:p6]];
    
    return positions;
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
