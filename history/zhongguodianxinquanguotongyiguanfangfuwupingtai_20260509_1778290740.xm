#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>
#import <objc/message.h>

/* ---------- Helper Functions (global scope) ---------- */
static inline void hookIfExists(const char *className, SEL selector, IMP newImp) {
    Class cls = objc_getClass(className);
    if (cls) {
        MSHookMessageEx(cls, selector, newImp, NULL);
    }
}

/* Empty implementation that does nothing */
static void blockVoid(id self, SEL _cmd, ...) { }

/* Implementation that always returns YES */
static BOOL blockYES(id self, SEL _cmd) {
    return YES;
}

/* Implementation that forces a 3‑second countdown */
static NSInteger blockCountdown(id self, SEL _cmd) {
    return 3;
}

/* Call reward delegate if possible */
static void invokeReward(id self, SEL _cmd) {
    id delegate = ((id (*)(id, SEL))objc_msgSend)(self, sel_getUid("delegate"));
    if (delegate && [delegate respondsToSelector:sel_getUid("rewardUser")]) {
        ((void (*)(id, SEL))objc_msgSend)(delegate, sel_getUid("rewardUser"));
    }
}

/* ---------- UI Filtering ---------- */
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName rangeOfString:@"Splash"].location != NSNotFound ||
        [clsName rangeOfString:@"Ad"].location != NSNotFound) {
        self.view.hidden = YES;
        return;
    }
    %orig;
}
%end

/* ---------- Constructor ---------- */
%ctor {
    /* Merge all %init into a single statement */
    %init(UIViewController=objc_getClass("UIViewController"));

    /* Configuration list for dynamic hooks */
    struct {
        const char *cls;
        const char *sel;
        IMP imp;
    } hookConfigs[] = {
        {"GDTSplashAd",                 "loadAdAndShowInWindow:", (IMP)blockVoid},
        {"GDTSplashAd",                 "showAdInWindow:",        (IMP)blockVoid},
        {"GDTSplashAd",                 "loadAd",               (IMP)blockVoid},
        {"CSJSplashAd",                "loadAdAndShowInWindow:", (IMP)blockVoid},
        {"CSJSplashAd",                "showAdInWindow:",        (IMP)blockVoid},
        {"CSJSplashAd",                "loadAd",               (IMP)blockVoid},
        {"BUSplashAdView",              "loadAndShow",         (IMP)blockVoid},
        {"BUSplashAdView",              "loadAd",              (IMP)blockVoid},
        {"BaiduMobAdSplash",           "startAdLoad",         (IMP)blockVoid},
        {"BaiduMobAdSplash",           "loadAd",              (IMP)blockVoid},
        {"KSAdSplashViewController",   "loadAd",             (IMP)blockVoid},

        /* Reward video related hooks */
        {"GDTRewardVideoAd",            "loadAd",             (IMP)blockVoid},
        {"GDTRewardVideoAd",            "showAdFromRootViewController:", (IMP)blockVoid},
        {"GDTRewardVideoAd",            "rewardedVideoAdDidRewardUser:", (IMP)invokeReward},
        {"GDTRewardVideoAd",            "remainingTime",       (IMP)blockCountdown},

        {"KSRewardVideoAd",            "loadAd",             (IMP)blockVoid},
        {"KSRewardVideoAd",            "showAdFromRootViewController:", (IMP)blockVoid},
        {"KSRewardVideoAd",            "rewardedVideoAdDidRewardUser:", (IMP)invokeReward},
        {"KSRewardVideoAd",            "remainingTime",       (IMP)blockCountdown},

        {"BURewardedVideoAd",          "loadAdData",         (IMP)blockVoid},
        {"BURewardedVideoAd",          "showAdFromRootViewController:", (IMP)blockVoid},
        {"BURewardedVideoAd",           "rewardedVideoAdDidRewardUser:", (IMP)invokeReward},
        {"BURewardedVideoAd",          "remainingTime",       (IMP)blockCountdown}
    };

    size_t count = sizeof(hookConfigs) / sizeof(hookConfigs[0]);
    for (size_t i = 0; i < count; ++i) {
        hookIfExists(hookConfigs[i].cls, sel_getUid(hookConfigs[i].sel), hookConfigs[i].imp);
    }
}
