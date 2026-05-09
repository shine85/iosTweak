#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>

/* ---------- 辅助函数 ---------- */
static void hookIfExists(const char *clsName, SEL sel, IMP newImp, IMP *orig) {
    Class cls = objc_getClass(clsName);
    if (cls) {
        MSHookMessageEx(cls, sel, newImp, orig);
    }
}

/* 递归搜索子视图中是否有标题含 “跳过” / “Skip” 的 UIButton */
static BOOL hideSplashIfButtonFound(UIView *root) {
    for (UIView *sub in root.subviews) {
        if (object_getClass(sub) == objc_getClass("UIButton")) {
            NSString *title = ((UIButton *)sub).currentTitle;
            if (title && ([title containsString:@"跳过"] || [title containsString:@"Skip"])) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sub setHidden:YES];
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

/* 采用定时多次检查的方式，确保延迟出现的跳过按钮也能被隐藏 */
static void scheduleSplashSkipCheck(UIView *root, NSInteger attempt) {
    const NSInteger maxAttempts = 12;
    const double interval = 0.5;
    if (attempt >= maxAttempts) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (!hideSplashIfButtonFound(root)) {
            scheduleSplashSkipCheck(root, attempt + 1);
        }
    });
}

/* 隐藏窗口内可能的开屏/广告视图 */
static void hideWindowSplashIfNeeded(UIWindow *window) {
    for (UIView *v in window.subviews) {
        NSString *cls = NSStringFromClass([v class]);
        if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"] || [cls containsString:@"Launch"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [v setHidden:YES];
            });
        }
    }
}

/* 遍历所有窗口并统一隐藏 */
static void hideAllSplashViews(void) {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIWindow *win in app.windows) {
        hideWindowSplashIfNeeded(win);
    }
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

/* ---------- Hook 实现(全部阻断) ---------- */
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

/* ---------- 空类 Hook(满足 %init 要求) ---------- */
%hook GDTSplashAd %end
%hook CSJSplashAd %end
%hook BUSplashAdView %end
%hook BaiduMobAdSplash %end
%hook KSAdSplashViewController %end
%hook CtSplashManager %end
%hook CSJRewardedVideoAd %end

/* ---------- UIViewController 关键点拦截 ---------- */
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] ||
        [clsName containsString:@"Ad"] ||
        [clsName containsString:@"Launch"]) {

        UIWindow *win = [[self view] window];
        if (win) {
            hideWindowSplashIfNeeded(win);
        }
        [[self view] setHidden:YES];
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            ((void (*)(id, SEL, BOOL, id))objc_msgSend)(self,
                                                       @selector(dismissViewControllerAnimated:completion:),
                                                       NO, nil);
        }
    } else {
        scheduleSplashSkipCheck([self view], 0);
    }
}
%end

/* ---------- 构造函数：统一初始化、延迟清理 ---------- */
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

    /* 应用启动后立即尝试清理残余的开屏视图 */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        hideAllSplashViews();
    });
}