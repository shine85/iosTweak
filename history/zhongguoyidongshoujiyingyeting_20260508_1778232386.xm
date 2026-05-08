#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/message.h>

@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUSplashAdView : NSObject @end
@interface BaiduMobAdSplash : NSObject @end
@interface KSAdSplashViewController : UIViewController @end
@interface CMSplashManager : NSObject @end
@interface CMAdManager : NSObject @end

// ---------- empty implementations ----------
static void emptyVoid(id self, SEL _cmd, ...) { }
static BOOL returnYES(id self, SEL _cmd, ...) { return YES; }
static NSInteger returnThree(id self, SEL _cmd, ...) { return 3; }
static NSInteger returnFour(id self, SEL _cmd, ...) { return 4; }

// ---------- reward handling ----------
static void rewardTrigger(id self, SEL _cmd, ...) {
    id delegate = nil;
    if ([self respondsToSelector:@selector(delegate)]) {
        delegate = ((id (*)(id, SEL))objc_msgSend)(self, @selector(delegate));
    } else if ([self respondsToSelector:@selector(adDelegate)]) {
        delegate = ((id (*)(id, SEL))objc_msgSend)(self, @selector(adDelegate));
    }
    if (delegate && [delegate respondsToSelector:@selector(adDidReward:)]) {
        ((void (*)(id, SEL, id))objc_msgSend)(delegate, @selector(adDidReward:), self);
    }
}

// ---------- UI filtering ----------
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        if (self.view) {
            self.view.hidden = YES;
        }
        return;
    }
    %orig;
}
%end

%hook UIView
- (void)didMoveToWindow {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        self.hidden = YES;
    }
    %orig;
}
%end

%ctor {
    // ---------- single %init ----------
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          CMSplashManager=objc_getClass("CMSplashManager"),
          CMAdManager=objc_getClass("CMAdManager"));

    // ---------- safe hook helper ----------
    static inline void hookIfExists(const char *clsName, SEL sel, IMP newImp, IMP *origPtr) {
        Class cls = objc_getClass(clsName);
        if (cls && sel) {
            MSHookMessageEx(cls, sel, newImp, (IMP *)origPtr);
        }
    }

    // ---------- hook list ----------
    struct {
        const char *cls;
        const char *sel;
        IMP imp;
        IMP *orig;
    } hookList[] = {
        {"GDTSplashAd",            "loadAdAndShowInWindow:",   (IMP)emptyVoid,   NULL},
        {"GDTSplashAd",            "showAdInWindow:",          (IMP)emptyVoid,   NULL},
        {"CSJSplashAd",            "loadAdAndShowInWindow:",   (IMP)emptyVoid,   NULL},
        {"CSJSplashAd",            "showAdInWindow:",          (IMP)emptyVoid,   NULL},
        {"BUSplashAdView",         "loadAdAndShowInWindow:",   (IMP)emptyVoid,   NULL},
        {"BUSplashAdView",         "showAdInWindow:",          (IMP)emptyVoid,   NULL},
        {"BaiduMobAdSplash",      "loadAndShowInWindow:",     (IMP)emptyVoid,   NULL},
        {"BaiduMobAdSplash",      "showInWindow:",            (IMP)emptyVoid,   NULL},
        {"KSAdSplashViewController","loadAd",                 (IMP)emptyVoid,   NULL},
        {"KSAdSplashViewController","showAdInWindow:",        (IMP)emptyVoid,   NULL},
        {"CMSplashManager",        "loadSplashAd",             (IMP)emptyVoid,   NULL},
        {"CMSplashManager",        "showSplashAdInWindow:",   (IMP)emptyVoid,   NULL},
        {"CMAdManager",           "requestAd",                (IMP)emptyVoid,   NULL},
        {"CMAdManager",           "isAdReady",                (IMP)returnYES,   NULL},
        // reward video and countdown
        {"RewardVideoAd",          "remainingTime",            (IMP)returnThree, NULL},
        {"SplashCountdownManager","remainingTime",            (IMP)returnFour,  NULL},
        {"RewardVideoAd",          "didEarnReward",            (IMP)rewardTrigger, NULL},
    };

    // ---------- apply hooks ----------
    for (unsigned i = 0; i < sizeof(hookList)/sizeof(hookList[0]); ++i) {
        hookIfExists(hookList[i].cls,
                     sel_registerName(hookList[i].sel),
                     hookList[i].imp,
                     hookList[i].orig);
    }
}
