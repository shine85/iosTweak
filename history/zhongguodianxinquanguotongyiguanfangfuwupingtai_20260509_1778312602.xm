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
    const NSInteger maxAttempts = 12;
    const double interval = 0.4;
    if (attempt >= maxAttempts) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (!hideSplashIfButtonFound(root)) {
            scheduleSplashSkipCheck(root, attempt + 1);
        }
    });
}

/* 谨慎的广告视图隐藏 - 避免误杀主界面视图 */
static void hideWindowSplashIfNeeded(UIWindow *window) {
    if (!window) return;
    for (UIView *v in window.subviews) {
        NSString *cls = NSStringFromClass([v class]);
        BOOL isSplashView = [cls containsString:@"Splash"] || [cls containsString:@"Ad"] || 
                           [cls containsString:@"Launch"] || [cls containsString:@"Advert"] ||
                           [cls containsString:@"GDTSplash"] || [cls containsString:@"CSJSplash"] ||
                           [cls containsString:@"BUSplash"] || [cls containsString:@"BaiduMobAd"] ||
                           [cls containsString:@"KSAd"] || [cls containsString:@"CTSplash"] ||
                           [cls containsString:@"TelecomSplash"] || [cls containsString:@"CtSplash"];
        
        if (isSplashView) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [v setHidden:YES];
                [v removeFromSuperview];
            });
        } else {
            /* 仅对子视图继续递归，防止过度深入主界面层级 */
            if (![cls containsString:@"UIViewControllerWrapperView"] && 
                ![cls containsString:@"UILayoutContainerView"]) {
                hideWindowSplashIfNeeded((UIWindow *)v);
            }
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [keyWin setHidden:NO];
            [keyWin setAlpha:1.0];
            [keyWin setBackgroundColor:[UIColor whiteColor]];
        });
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

/* ---------- UIViewController 关键点拦截(优化版，降低误杀 + 修复白屏) ---------- */
%hook UIViewController
- (void)viewDidLoad {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    BOOL isSplash = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                    [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"] ||
                    [clsName containsString:@"CTAd"] || [clsName containsString:@"TelecomSplash"] ||
                    [clsName containsString:@"CtSplashView"];
    
    if (isSplash) {
        [[self view] setHidden:YES];
        UIWindow *win = [[self view] window];
        if (win) hideWindowSplashIfNeeded(win);
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ((void (*)(id, SEL, BOOL, id))objc_msgSend)(self, @selector(dismissViewControllerAnimated:completion:), YES, nil);
            });
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    BOOL isSplash = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                    [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"] ||
                    [clsName containsString:@"CTAd"] || [clsName containsString:@"TelecomSplash"] ||
                    [clsName containsString:@"CtSplashView"];
    
    if (isSplash) {
        [[self view] setHidden:YES];
        UIWindow *win = [[self view] window];
        if (win) {
            hideWindowSplashIfNeeded(win);
            dispatch_async(dispatch_get_main_queue(), ^{
                [win setHidden:NO];
                [win setAlpha:1.0];
            });
        }
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ((void (*)(id, SEL, BOOL, id))objc_msgSend)(self, @selector(dismissViewControllerAnimated:completion:), YES, nil);
            });
        }
    } else {
        /* 非开屏页面 - 确保主界面可见并查找跳过按钮 */
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIWindow *keyWin = [[UIApplication sharedApplication] keyWindow];
            if (keyWin) {
                [keyWin setHidden:NO];
                [keyWin setAlpha:1.0];
            }
            [[self view] setHidden:NO];
            [[self view] setAlpha:1.0];
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
    BOOL isSplashSubview = [cls containsString:@"Splash"] || [cls containsString:@"Ad"] || 
                          [cls containsString:@"Launch"] || [cls containsString:@"GDTSplash"] ||
                          [cls containsString:@"CSJSplash"] || [cls containsString:@"BUSplash"] ||
                          [cls containsString:@"CtSplash"] || [cls containsString:@"TelecomSplash"];
    
    if (isSplashSubview) {
        return; // 阻断广告视图添加
    }
    %orig;
}

- (void)setHidden:(BOOL)hidden {
    /* 防止主窗口被意外隐藏 */
    if (!hidden) {
        %orig;
    } else {
        NSString *winCls = NSStringFromClass([self class]);
        if (![winCls containsString:@"Splash"] && ![winCls containsString:@"Ad"]) {
            %orig;
        }
    }
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
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"), 
          CSJSplashAd=objc_getClass("CSJSplashAd"), 
          BUSplashAdView=objc_getClass("BUSplashAdView"), 
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"), 
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"), 
          CtSplashManager=objc_getClass("CtSplashManager"), 
          CTAdSplashManager=objc_getClass("CTAdSplashManager"));

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

    /* 启动后多次清理 + 重点保护主界面可见性(修复白屏) */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllSplashViews();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllSplashViews();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllSplashViews();
        /* 强制恢复主窗口 */
        UIWindow *keyWin = [[UIApplication sharedApplication] keyWindow];
        if (keyWin) {
            [keyWin setHidden:NO];
            [keyWin setAlpha:1.0];
            [keyWin setBackgroundColor:[UIColor whiteColor]];
            [keyWin layoutIfNeeded];
        }
    });
}