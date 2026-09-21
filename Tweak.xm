#import <UIKit/UIKit.h>

%ctor {
    // مراقبة التطبيق حتى يفتح بالكامل
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification 
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue] 
                                                  usingBlock:^(NSNotification *note) {
        
        // محاولة استدعاء كلاس أداة FLEX
        Class FLEXManager = NSClassFromString(@"FLEXManager");
        
        if (FLEXManager) {
            id sharedManager = [FLEXManager performSelector:@selector(sharedManager)];
            [sharedManager performSelector:@selector(showExplorer)];
            
            // رسالة تأكيد النجاح في سجل النظام
            NSLog(@"[ATTACK STORE] -> IBABlack FLEX Loader Injected Successfully!");
        } else {
            NSLog(@"[ATTACK STORE] -> Error: FLEXManager not found. Make sure FLEX.dylib is injected.");
        }
    }];
}
