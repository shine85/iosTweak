#import <UIKit/UIKit.h>
#import <substrate.h>

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

// ---------- reward video handling ----------
static void rewardTrigger(id self, SEL _cmd, ...) {
    // Assume the delegate responds to reward method named adDidReward:
    id delegate = nil;
    // Try common ivar/property names
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
    // Single %init with class assignments
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          CMSplashManager=objc_getClass("CMSplashManager"),
          CMAdManager=objc_getClass("CMAdManager"));

    // Helper macro for safe hooking
    #define SAFE_HOOK(cls, sel, imp, origPtr) \
        if (cls) { \
            MSHookMessageEx(cls, sel, (IMP)imp, (IMP *)origPtr); \
        }

    // Hook splash related methods (void returning)
    SAFE_HOOK(GDTSplashAd, @selector(loadAdAndShowInWindow:), emptyVoid, NULL);
    SAFE_HOOK(GDTSplashAd, @selector(showAdInWindow:), emptyVoid, NULL);
    SAFE_HOOK(CSJSplashAd, @selector(loadAdAndShowInWindow:), emptyVoid, NULL);
    SAFE_HOOK(CSJSplashAd, @selector(showAdInWindow:), emptyVoid, NULL);
    SAFE_HOOK(BUSplashAdView, @selector(loadAdAndShowInWindow:), emptyVoid, NULL);
    SAFE_HOOK(BUSplashAdView, @selector(showAdInWindow:), emptyVoid, NULL);
    SAFE_HOOK(BaiduMobAdSplash, @selector(loadAndShowInWindow:), emptyVoid, NULL);
    SAFE_HOOK(BaiduMobAdSplash, @selector(showInWindow:), emptyVoid, NULL);
    SAFE_HOOK(KSAdSplashViewController, @selector(loadAd), emptyVoid, NULL);
    SAFE_HOOK(KSAdSplashViewController, @selector(showAdInWindow:), emptyVoid, NULL);
    SAFE_HOOK(CMSplashManager, @selector(loadSplashAd), emptyVoid, NULL);
    SAFE_HOOK(CMSplashManager, @selector(showSplashAdInWindow:), emptyVoid, NULL);
    SAFE_HOOK(CMAdManager, @selector(requestAd), emptyVoid, NULL);
    SAFE_HOOK(CMAdManager, @selector(isAdReady), returnYES, NULL);

    // Reward video hooks (example selectors)
    // Adjust countdown to 3 seconds
    SAFE_HOOK(objc_getClass("RewardVideoAd"), @selector(remainingTime), returnThree, NULL);
    // Adjust countdown to 4 seconds (generic splash countdown)
    SAFE_HOOK(objc_getClass("SplashCountdownManager"), @selector(remainingTime), returnFour, NULL);
    // Directly trigger reward callback
    SAFE_HOOK(objc_getClass("RewardVideoAd"), @selector(didEarnReward), rewardTrigger, NULL);

    #undef SAFE_HOOK
}
