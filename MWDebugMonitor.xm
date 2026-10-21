
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface MWMonitor : NSObject
@property(nonatomic,strong) UIButton *bubble;
@property(nonatomic,strong) UITextView *panel;
@property(nonatomic,strong) NSMutableArray *events;

+ (instancetype)shared;
- (void)install;
- (void)record:(NSString *)message;
- (void)toggle;
@end

@implementation MWMonitor

+ (instancetype)shared {
    static MWMonitor *monitor = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        monitor = [[MWMonitor alloc] init];
        monitor.events = [NSMutableArray array];
    });

    return monitor;
}

- (void)record:(NSString *)message {
    if (!message) return;

    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *line = [NSString stringWithFormat:
            @"%@ | %@", [NSDate date], message];

        [self.events addObject:line];

        if (self.events.count > 200) {
            [self.events removeObjectAtIndex:0];
        }

        NSString *log =
            [self.events componentsJoinedByString:@"\n"];

        NSString *directory =
            NSSearchPathForDirectoriesInDomains(
                NSCachesDirectory,
                NSUserDomainMask,
                YES
            ).firstObject;

        NSString *path =
            [directory stringByAppendingPathComponent:
                @"MWDebugMonitor.log"];

        [log writeToFile:path
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:nil];

        self.panel.text = log;
    });
}

- (void)install {
    if (self.bubble) return;

    UIWindow *window = nil;

    for (UIScene *scene in
         UIApplication.sharedApplication.connectedScenes) {

        if (![scene isKindOfClass:UIWindowScene.class])
            continue;

        if (scene.activationState !=
            UISceneActivationStateForegroundActive)
            continue;

        for (UIWindow *candidate in
             ((UIWindowScene *)scene).windows) {

            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }

        if (window) break;
    }

    if (!window) return;

    CGFloat width = window.bounds.size.width;

    self.bubble =
        [UIButton buttonWithType:UIButtonTypeSystem];

    self.bubble.frame =
        CGRectMake(width - 70, 100, 56, 44);

    self.bubble.backgroundColor =
        [UIColor colorWithRed:0.08
                       green:0.12
                        blue:0.18
                       alpha:0.95];

    [self.bubble setTitle:@"MW"
                forState:UIControlStateNormal];

    [self.bubble setTitleColor:UIColor.whiteColor
                     forState:UIControlStateNormal];

    self.bubble.layer.cornerRadius = 12;

    [self.bubble addTarget:self
                    action:@selector(toggle)
          forControlEvents:UIControlEventTouchUpInside];

    [window addSubview:self.bubble];

    self.panel =
        [[UITextView alloc] initWithFrame:
            CGRectMake(12, 154, width - 24, 260)];

    self.panel.backgroundColor =
        [UIColor colorWithWhite:0.07 alpha:0.95];

    self.panel.textColor = UIColor.greenColor;

    self.panel.font =
        [UIFont monospacedSystemFontOfSize:11
                                   weight:UIFontWeightRegular];

    self.panel.editable = NO;
    self.panel.hidden = YES;
    self.panel.layer.cornerRadius = 12;

    [window addSubview:self.panel];

    [self record:@"MW Monitor initialized"];
}

- (void)toggle {
    self.panel.hidden = !self.panel.hidden;
}

@end

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    NSString *name =
        NSStringFromClass([self class]);

    if (![name containsString:@"Keyboard"] &&
        ![name hasPrefix:@"UIInput"]) {

        [[MWMonitor shared] record:
            [NSString stringWithFormat:
                @"SCREEN: %@", name]];
    }

    [[MWMonitor shared] install];
}

%end

%hook UIApplication

- (BOOL)sendAction:(SEL)action
                to:(id)target
              from:(id)sender
          forEvent:(UIEvent *)event {

    if (target != [MWMonitor shared] &&
        [sender isKindOfClass:UIControl.class]) {

        NSString *targetName = target
            ? NSStringFromClass([target class])
            : @"nil";

        [[MWMonitor shared] record:
            [NSString stringWithFormat:
                @"BUTTON: %@ | TARGET: %@ | ACTION: %@",
                NSStringFromClass([sender class]),
                targetName,
                NSStringFromSelector(action)]];
    }

    return %orig;
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[MWMonitor] Dylib loaded");
        NSLog(@"[MWMonitor] Diagnostic mode");
    }
}
