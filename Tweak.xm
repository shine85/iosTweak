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
        if ([sub isKindOfClass:[UIButton class]]) {
            NSString *title = ((UIButton *)sub).currentTitle;
            if (title && ([title containsString:@"跳过"] || [title containsString:@"Skip"] || [title containsString:@"关闭"])) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sub setHidden:NO];
                    if (sub.superview) [sub.superview setHidden:NO];
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

static void scheduleSplashSkipCheck(UIView *root, NSInteger attempt) {
    const NSInteger maxAttempts = 15;
    const double interval = 0.35;
    if (attempt >= maxAttempts) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (!hideSplashIfButtonFound(root)) {
            scheduleSplashSkipCheck(root, attempt + 1);
        }
    });
}

/* 更谨慎的广告视图隐藏(避免误杀主界面) */
static void hideWindowSplashIfNeeded(UIWindow *window) {
    if (!window) return;
    for (UIView *v in window.subviews) {
        NSString *cls = NSStringFromClass([v class]);
        if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"] || 
            [cls containsString:@"Launch"] || [cls containsString:@"Advert"] ||
            [cls containsString:@"CT"] || [cls containsString:@"Telecom"] || 
            [cls containsString:@"GDTSplash"] || [cls containsString:@"CSJSplash"] ||
            [cls containsString:@"BUSplash"] || [cls containsString:@"BaiduMobAd"]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [v setHidden:YES];
                [v removeFromSuperview];
            });
        } else {
            hideWindowSplashIfNeeded((UIWindow *)v);
        }
    }
}

static void hideAllSplashViews(void) {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIWindow *win in app.windows) {
        hideWindowSplashIfNeeded(win);
    }
    UIWindow *keyWin = [app keyWindow];
    if (keyWin) {
        hideWindowSplashIfNeeded(keyWin);
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
static IMP CTAdSplashManager_fetchSplash_orig = NULL;
static IMP CTAdSplashManager_show_orig = NULL;

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

static void CTAdSplashManager_fetchSplash_hook(id self, SEL _cmd) { }
static void CTAdSplashManager_show_hook(id self, SEL _cmd, UIWindow *window) { }

/* ---------- 空类 Hook ---------- */
%hook GDTSplashAd %end
%hook CSJSplashAd %end
%hook BUSplashAdView %end
%hook BaiduMobAdSplash %end
%hook KSAdSplashViewController %end
%hook CtSplashManager %end
%hook CTAdSplashManager %end

/* ---------- UIViewController 关键点拦截(优化版，降低误杀) ---------- */
%hook UIViewController
- (void)viewDidLoad {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    BOOL isSplash = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                    [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"] ||
                    [clsName containsString:@"CTAd"] || [clsName containsString:@"TelecomSplash"];
    
    if (isSplash) {
        [[self view] setHidden:YES];
        UIWindow *win = [[self view] window];
        if (win) hideWindowSplashIfNeeded(win);
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            ((void (*)(id, SEL, BOOL, id))objc_msgSend)(self, @selector(dismissViewControllerAnimated:completion:), YES, nil);
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    BOOL isSplash = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                    [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"] ||
                    [clsName containsString:@"CTAd"] || [clsName containsString:@"TelecomSplash"];
    
    if (isSplash) {
        UIWindow *win = [[self view] window];
        if (win) hideWindowSplashIfNeeded(win);
        [[self view] setHidden:YES];
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            ((void (*)(id, SEL, BOOL, id))objc_msgSend)(self, @selector(dismissViewControllerAnimated:completion:), YES, nil);
        }
    } else {
        // 非开屏页面才尝试查找跳过按钮
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            scheduleSplashSkipCheck([self view], 0);
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    BOOL isSplash = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                    [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"];
    if (isSplash) {
        [[self view] setHidden:YES];
    }
}
%end

/* 拦截 UIWindow 添加子视图(增加白名单保护) */
%hook UIWindow
- (void)addSubview:(UIView *)view {
    if (!view) {
        %orig;
        return;
    }
    NSString *cls = NSStringFromClass([view class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"] || 
        [cls containsString:@"Launch"] || [cls containsString:@"GDTSplash"] ||
        [cls containsString:@"CSJSplash"] || [cls containsString:@"BUSplash"]) {
        return; // 阻断广告视图添加
    }
    %orig;
}
%end

/* 确保主界面可见 */
%hook UIApplication
- (void)setStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation {
    %orig(NO, animation);
}
%end

/* ---------- 构造函数 ---------- */
%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"), CSJSplashAd=objc_getClass("CSJSplashAd"), BUSplashAdView=objc_getClass("BUSplashAdView"), BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"), KSAdSplashViewController=objc_getClass("KSAdSplashViewController"), CtSplashManager=objc_getClass("CtSplashManager"), CTAdSplashManager=objc_getClass("CTAdSplashManager"));

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

    hookIfExists("CTAdSplashManager", @selector(fetchSplash), (IMP)CTAdSplashManager_fetchSplash_hook, &CTAdSplashManager_fetchSplash_orig);
    hookIfExists("CTAdSplashManager", @selector(show:), (IMP)CTAdSplashManager_show_hook, &CTAdSplashManager_show_orig);

    /* 启动后多次清理 + 保护主界面 */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllSplashViews();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllSplashViews();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllSplashViews();
    });
}
