#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>

/* ---------- Helper ---------- */
static void hookIfExists(const char *clsName, SEL sel, IMP newImp, IMP *orig) {
    Class cls = objc_getClass(clsName);
    if (cls) {
        MSHookMessageEx(cls, sel, newImp, orig);
    }
}

/* ---------- Splash‑skip 检测 ----------
   递归遍历子视图，寻找标题含 “跳过” 或 “Skip” 的 UIButton。
   若找到则隐藏传入的根视图并返回 YES；否则返回 NO。
   为兼容按钮在 viewDidAppear 之后才出现的情况，外部提供
   scheduleSplashSkipCheck 进行多次轮询。 */
static BOOL hideSplashIfButtonFound(UIView *rootView) {
    for (UIView *sub in rootView.subviews) {
        if (object_getClass(sub) == objc_getClass("UIButton")) {
            NSString *title = ((UIButton *)sub).currentTitle;
            if (title && ([title containsString:@"跳过"] || [title containsString:@"Skip"])) {
                // 隐藏根视图(即整个启动页)
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                               dispatch_get_main_queue(), ^{
                    [rootView setHidden:YES];
                });
                return YES;
            }
        }
        if (hideSplashIfButtonFound(sub)) {
            return YES;
        }
    }
    return NO;
}

/* 轮询检查函数 – 最多 10 次、间隔 0.5 秒 */
static void scheduleSplashSkipCheck(UIView *rootView, NSInteger attempt) {
    const NSInteger maxAttempts = 10;
    const double interval = 0.5; // 秒
    if (attempt >= maxAttempts) return;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(interval * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (!hideSplashIfButtonFound(rootView)) {
            scheduleSplashSkipCheck(rootView, attempt + 1);
        }
    });
}

/* ---------- 原始 IMP 占位 ---------- */
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

/* ---------- Hook 实现 ---------- */
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
            ((void (*)(id, SEL, id))objc_msgSend)(delegate,
                                                @selector(rewardedVideoAdDidRewardUser:),
                                                self);
        }
    }
}
static void CSJRewardedVideoAd_startCountdown_hook(id self, SEL _cmd, NSInteger seconds) { }

/* ---------- 空 Hook 块(保持兼容) ---------- */
%hook GDTSplashAd %end
%hook CSJSplashAd %end
%hook BUSplashAdView %end
%hook BaiduMobAdSplash %end
%hook KSAdSplashViewController %end
%hook CtSplashManager %end
%hook CSJRewardedVideoAd %end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        [[self view] setHidden:YES];
    } else {
        // 首次立即检查一次，随后最多再检查 9 次(共 10 次)
        scheduleSplashSkipCheck([self view], 0);
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
