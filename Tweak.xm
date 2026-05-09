#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ---------- Helper ----------
static void hookIfExists(const char *clsName, SEL sel, IMP newImp, IMP *orig) {
    Class cls = objc_getClass(clsName);
    if (cls) {
        MSHookMessageEx(cls, sel, newImp, orig);
    }
}

// ---------- Original IMP placeholders ----------
static IMP GDTSplashAd_loadAdAndShowInWindow_orig = NULL;
static IMP GDTSplashAd_loadAd_orig = NULL;

static IMP CSJSplashAd_loadAdAndShowInWindow_orig = NULL;
static IMP CSJSplashAd_loadAd_orig = NULL;

static IMP BUSplashAdView_loadAdAndShowInWindow_orig = NULL;
static IMP BUSplashAdView_loadAd_orig = NULL;

static IMP BaiduMobAdSplash_loadAdAndShowInWindow_orig = NULL;
static IMP BaiduMobAdSplash_loadAd_orig = NULL;

static IMP KSAdSplashViewController_loadAdAndShowInWindow_orig = NULL;
static IMP KSAdSplashViewController_loadAd_orig = NULL;

static IMP CtSplashManager_fetchSplash_orig = NULL;
static IMP CtSplashManager_showSplashInWindow_orig = NULL;

static IMP CSJRewardedVideoAd_isReady_orig = NULL;
static IMP CSJRewardedVideoAd_loadAd_orig = NULL;
static IMP CSJRewardedVideoAd_showAdFromRootViewController_orig = NULL;
static IMP CSJRewardedVideoAd_startCountdown_orig = NULL;

// ---------- Hook implementations ----------
static void GDTSplashAd_loadAdAndShowInWindow_hook(id self, SEL _cmd, UIWindow *window) { }
static void GDTSplashAd_loadAd_hook(id self, SEL _cmd) { }

static void CSJSplashAd_loadAdAndShowInWindow_hook(id self, SEL _cmd, UIWindow *window) { }
static void CSJSplashAd_loadAd_hook(id self, SEL _cmd) { }

static void BUSplashAdView_loadAdAndShowInWindow_hook(id self, SEL _cmd, UIWindow *window) { }
static void BUSplashAdView_loadAd_hook(id self, SEL _cmd) { }

static void BaiduMobAdSplash_loadAdAndShowInWindow_hook(id self, SEL _cmd, UIWindow *window) { }
static void BaiduMobAdSplash_loadAd_hook(id self, SEL _cmd) { }

static void KSAdSplashViewController_loadAdAndShowInWindow_hook(id self, SEL _cmd, UIWindow *window) { }
static void KSAdSplashViewController_loadAd_hook(id self, SEL _cmd) { }

static void CtSplashManager_fetchSplash_hook(id self, SEL _cmd) { }
static void CtSplashManager_showSplashInWindow_hook(id self, SEL _cmd, UIWindow *window) { }

static BOOL CSJRewardedVideoAd_isReady_hook(id self, SEL _cmd) { return YES; }
static void CSJRewardedVideoAd_loadAd_hook(id self, SEL _cmd) { }
static void CSJRewardedVideoAd_showAdFromRootViewController_hook(id self, SEL _cmd, UIViewController *vc) {
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = ((id (*)(id, SEL))objc_msgSend)(self, @selector(delegate));
        if (delegate && [delegate respondsToSelector:@selector(rewardedVideoAdDidRewardUser:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(delegate, @selector(rewardedVideoAdDidRewardUser:), self);
        }
    }
}
static void CSJRewardedVideoAd_startCountdown_hook(id self, SEL _cmd, NSInteger seconds) { 
    // force countdown to 3 seconds; original call omitted
}

// ---------- Empty %hook blocks for each class ----------
%hook GDTSplashAd
%end

%hook CSJSplashAd
%end

%hook BUSplashAdView
%end

%hook BaiduMobAdSplash
%end

%hook KSAdSplashViewController
%end

%hook CtSplashManager
%end

%hook CSJRewardedVideoAd
%end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        [[self view] setHidden:YES];
    }
}
%end

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"), CSJSplashAd=objc_getClass("CSJSplashAd"), BUSplashAdView=objc_getClass("BUSplashAdView"), BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"), KSAdSplashViewController=objc_getClass("KSAdSplashViewController"), CtSplashManager=objc_getClass("CtSplashManager"), CSJRewardedVideoAd=objc_getClass("CSJRewardedVideoAd"));
    
    hookIfExists("GDTSplashAd", @selector(loadAdAndShowInWindow:), (IMP)GDTSplashAd_loadAdAndShowInWindow_hook, &GDTSplashAd_loadAdAndShowInWindow_orig);
    hookIfExists("GDTSplashAd", @selector(loadAd), (IMP)GDTSplashAd_loadAd_hook, &GDTSplashAd_loadAd_orig);
    
    hookIfExists("CSJSplashAd", @selector(loadAdAndShowInWindow:), (IMP)CSJSplashAd_loadAdAndShowInWindow_hook, &CSJSplashAd_loadAdAndShowInWindow_orig);
    hookIfExists("CSJSplashAd", @selector(loadAd), (IMP)CSJSplashAd_loadAd_hook, &CSJSplashAd_loadAd_orig);
    
    hookIfExists("BUSplashAdView", @selector(loadAdAndShowInWindow:), (IMP)BUSplashAdView_loadAdAndShowInWindow_hook, &BUSplashAdView_loadAdAndShowInWindow_orig);
    hookIfExists("BUSplashAdView", @selector(loadAd), (IMP)BUSplashAdView_loadAd_hook, &BUSplashAdView_loadAd_orig);
    
    hookIfExists("BaiduMobAdSplash", @selector(loadAdAndShowInWindow:), (IMP)BaiduMobAdSplash_loadAdAndShowInWindow_hook, &BaiduMobAdSplash_loadAdAndShowInWindow_orig);
    hookIfExists("BaiduMobAdSplash", @selector(loadAd), (IMP)BaiduMobAdSplash_loadAd_hook, &BaiduMobAdSplash_loadAd_orig);
    
    hookIfExists("KSAdSplashViewController", @selector(loadAdAndShowInWindow:), (IMP)KSAdSplashViewController_loadAdAndShowInWindow_hook, &KSAdSplashViewController_loadAdAndShowInWindow_orig);
    hookIfExists("KSAdSplashViewController", @selector(loadAd), (IMP)KSAdSplashViewController_loadAd_hook, &KSAdSplashViewController_loadAd_orig);
    
    hookIfExists("CtSplashManager", @selector(fetchSplash), (IMP)CtSplashManager_fetchSplash_hook, &CtSplashManager_fetchSplash_orig);
    hookIfExists("CtSplashManager", @selector(showSplashInWindow:), (IMP)CtSplashManager_showSplashInWindow_hook, &CtSplashManager_showSplashInWindow_orig);
    
    hookIfExists("CSJRewardedVideoAd", @selector(isReady), (IMP)CSJRewardedVideoAd_isReady_hook, &CSJRewardedVideoAd_isReady_orig);
    hookIfExists("CSJRewardedVideoAd", @selector(loadAd), (IMP)CSJRewardedVideoAd_loadAd_hook, &CSJRewardedVideoAd_loadAd_orig);
    hookIfExists("CSJRewardedVideoAd", @selector(showAdFromRootViewController:), (IMP)CSJRewardedVideoAd_showAdFromRootViewController_hook, &CSJRewardedVideoAd_showAdFromRootViewController_orig);
    hookIfExists("CSJRewardedVideoAd", @selector(startCountdown:), (IMP)CSJRewardedVideoAd_startCountdown_hook, &CSJRewardedVideoAd_startCountdown_orig);
}
