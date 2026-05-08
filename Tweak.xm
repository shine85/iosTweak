#import <UIKit/UIKit.h>
#import <substrate.h>
#import <Foundation/Foundation.h>

/* Forward declarations */
@class GDTSplashAd;
@class CSJSplashAd;
@class BUSplashAdView;
@class BaiduMobAdSplash;
@class KSAdSplashViewController;
@class CMSplashManager;
@class CMAdManager;
@class PAGSplashRequest;
@class RewardedVideoAd;

/* Helper: safe hook */
static void safeHook(Class cls, SEL sel, IMP newImp) {
    if (cls && sel) {
        MSHookMessageEx(cls, sel, newImp, NULL);
    }
}

/* Empty implementation for void methods */
static void emptyVoid(id self, SEL _cmd, ...) {
    /* No operation */
}

/* Forced countdown implementation */
static NSInteger forcedCountdown(id self, SEL _cmd) {
    NSString *selName = NSStringFromSelector(_cmd);
    if ([selName containsString:@"Reward"]) {
        return 3; /* Rewarded video countdown */
    }
    return 4;     /* General splash countdown */
}

/* Direct reward callback trigger */
static void triggerReward(id self, SEL _cmd, id rewardInfo) {
    id delegate = nil;
    @try {
        delegate = [self valueForKey:@"delegate"];
    } @catch (NSException *e) {}
    if (delegate && [delegate respondsToSelector:@selector(rewardedVideoDidRewardUser:)]) {
        [delegate performSelector:@selector(rewardedVideoDidRewardUser:) withObject:rewardInfo];
    }
}

/* UIViewController filtering */
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        self.view.hidden = YES;
        return;
    }
    %orig;
}
%end

/* UIView filtering */
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
    %init(
        GDTSplashAd=objc_getClass("GDTSplashAd"),
        CSJSplashAd=objc_getClass("CSJSplashAd"),
        BUSplashAdView=objc_getClass("BUSplashAdView"),
        BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
        KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
        CMSplashManager=objc_getClass("CMSplashManager"),
        CMAdManager=objc_getClass("CMAdManager"),
        PAGSplashRequest=objc_getClass("PAGSplashRequest"),
        RewardedVideoAd=objc_getClass("RewardedVideoAd")
    );

    /* Splash ad methods to neutralize */
    struct HookInfo {
        Class cls;
        SEL sel;
    } splashHooks[] = {
        {GDTSplashAd, @selector(loadAdAndShowInWindow:)},
        {GDTSplashAd, @selector(showAdInWindow:)},
        {CSJSplashAd, @selector(loadAdAndShowInWindow:)},
        {CSJSplashAd, @selector(showAdInWindow:)},
        {BUSplashAdView, @selector(loadAd)},
        {BUSplashAdView, @selector(showAd)},
        {BaiduMobAdSplash, @selector(loadAndShow)},
        {BaiduMobAdSplash, @selector(showAd)},
        {KSAdSplashViewController, @selector(loadAd)},
        {KSAdSplashViewController, @selector(showAd)},
        {CMSplashManager, @selector(requestSplashAd)},
        {CMAdManager, @selector(fetchSplash)},
        {PAGSplashRequest, @selector(loadRequest)}
    };

    for (size_t i = 0; i < sizeof(splashHooks)/sizeof(splashHooks[0]); i++) {
        safeHook(splashHooks[i].cls, splashHooks[i].sel, (IMP)emptyVoid);
    }

    /* Rewarded video related hooks */
    if (RewardedVideoAd) {
        safeHook(RewardedVideoAd, @selector(countdownDuration), (IMP)forcedCountdown);
        safeHook(RewardedVideoAd, @selector(rewardUserWithInfo:), (IMP)triggerReward);
    }
}
