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

/* 增强版广告/弹窗视图隐藏 - 针对开屏 + 进入后中间弹窗广告 */
static void hideWindowAdViewsIfNeeded(UIView *view) {
    if (!view) return;
    for (UIView *v in view.subviews) {
        NSString *cls = NSStringFromClass([v class]);
        BOOL isAdView = [cls containsString:@"Splash"] || [cls containsString:@"Ad"] || 
                        [cls containsString:@"Launch"] || [cls containsString:@"Advert"] ||
                        [cls containsString:@"GDTSplash"] || [cls containsString:@"CSJSplash"] ||
                        [cls containsString:@"BUSplash"] || [cls containsString:@"BaiduMobAd"] ||
                        [cls containsString:@"KSAd"] || [cls containsString:@"CTSplash"] ||
                        [cls containsString:@"TelecomSplash"] || [cls containsString:@"CtSplash"] ||
                        [cls containsString:@"CTAd"] || [cls containsString:@"ChinaTelecom"] ||
                        [cls containsString:@"Popup"] || [cls containsString:@"Dialog"] ||
                        [cls containsString:@"Alert"] || [cls containsString:@"Promotion"];
        
        BOOL isCentralPopup = isAdView && 
                             (v.frame.size.width > 200 && v.frame.size.height > 200) &&
                             (CGRectGetMidX(v.frame) > CGRectGetWidth(view.bounds)*0.3 && 
                              CGRectGetMidX(v.frame) < CGRectGetWidth(view.bounds)*0.7);
        
        if (isAdView || isCentralPopup) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [v setHidden:YES];
                [v removeFromSuperview];
            });
        } else {
            if (![cls containsString:@"UIViewControllerWrapperView"] && 
                ![cls containsString:@"UILayoutContainerView"] &&
                ![cls containsString:@"UINavigationController"] &&
                ![cls containsString:@"UITabBarController"] &&
                ![cls containsString:@"UIWindow"] &&
                ![cls containsString:@"UITabBar"] &&
                ![cls containsString:@"UINavigationBar"] &&
                ![cls containsString:@"UITransitionView"]) {
                hideWindowAdViewsIfNeeded(v);
            }
        }
    }
}

static void forceMainUIVisible(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIApplication *app = [UIApplication sharedApplication];
        for (UIWindow *win in app.windows) {
            [win setHidden:NO];
            [win setAlpha:1.0];
            [win setBackgroundColor:[UIColor whiteColor]];
            [win layoutIfNeeded];
            
            if (win.rootViewController) {
                UIView *rootView = [win.rootViewController view];
                [rootView setHidden:NO];
                [rootView setAlpha:1.0];
                [rootView setBackgroundColor:[UIColor whiteColor]];
                [rootView layoutIfNeeded];
                
                for (UIView *sub in rootView.subviews) {
                    [sub setHidden:NO];
                    [sub setAlpha:1.0];
                }
            }
        }
        
        UIWindow *keyWin = [app keyWindow];
        if (keyWin) {
            [keyWin setHidden:NO];
            [keyWin setAlpha:1.0];
            [keyWin setBackgroundColor:[UIColor whiteColor]];
            [keyWin layoutIfNeeded];
            
            if (keyWin.rootViewController) {
                UIView *rootView = [keyWin.rootViewController view];
                [rootView setHidden:NO];
                [rootView setAlpha:1.0];
                [rootView layoutIfNeeded];
            }
        }
    });
}

static void hideAllAdViews(void) {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIWindow *win in app.windows) {
        hideWindowAdViewsIfNeeded(win);
    }
    UIWindow *keyWin = [app keyWindow];
    if (keyWin) {
        hideWindowAdViewsIfNeeded(keyWin);
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

/* ---------- UIViewController 关键点拦截(强化弹窗移除) ---------- */
%hook UIViewController
- (void)viewDidLoad {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    BOOL isAd = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"] ||
                [clsName containsString:@"CTAd"] || [clsName containsString:@"TelecomSplash"] ||
                [clsName containsString:@"CtSplashView"] || [clsName containsString:@"ChinaTelecom"] ||
                [clsName containsString:@"Popup"] || [clsName containsString:@"Dialog"];
    
    if (isAd) {
        [[self view] setHidden:YES];
        [[self view] setAlpha:0.0];
        UIWindow *win = [[self view] window];
        if (win) hideWindowAdViewsIfNeeded(win);
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
    BOOL isAd = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"] ||
                [clsName containsString:@"CTAd"] || [clsName containsString:@"TelecomSplash"] ||
                [clsName containsString:@"CtSplashView"] || [clsName containsString:@"ChinaTelecom"] ||
                [clsName containsString:@"Popup"] || [clsName containsString:@"Dialog"];
    
    if (isAd) {
        [[self view] setHidden:YES];
        [[self view] setAlpha:0.0];
        UIWindow *win = [[self view] window];
        if (win) hideWindowAdViewsIfNeeded(win);
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ((void (*)(id, SEL, BOOL, id))objc_msgSend)(self, @selector(dismissViewControllerAnimated:completion:), YES, nil);
            });
        }
    } else {
        /* 非广告页面 - 进入APP后重点清理中间弹窗广告 */
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hideAllAdViews();
            forceMainUIVisible();
            scheduleSplashSkipCheck([self view], 0);
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hideAllAdViews();
            forceMainUIVisible();
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hideAllAdViews();
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    BOOL isAd = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"] ||
                [clsName containsString:@"Telecom"] || [clsName containsString:@"Popup"];
    if (isAd) {
        [[self view] setHidden:YES];
        [[self view] setAlpha:0.0];
    }
}
%end

/* 拦截 UIWindow 添加子视图 - 强化阻断中间弹窗 */
%hook UIWindow
- (void)addSubview:(UIView *)view {
    if (!view) {
        %orig;
        return;
    }
    NSString *cls = NSStringFromClass([view class]);
    BOOL isAdSubview = [cls containsString:@"Splash"] || [cls containsString:@"Ad"] || 
                       [cls containsString:@"Launch"] || [cls containsString:@"GDTSplash"] ||
                       [cls containsString:@"CSJSplash"] || [cls containsString:@"BUSplash"] ||
                       [cls containsString:@"CtSplash"] || [cls containsString:@"TelecomSplash"] ||
                       [cls containsString:@"ChinaTelecom"] || [cls containsString:@"Popup"] ||
                       [cls containsString:@"Dialog"] || [cls containsString:@"Promotion"];
    
    if (isAdSubview) {
        return; // 阻断添加
    }
    %orig;
}

- (void)setHidden:(BOOL)hidden {
    NSString *winCls = NSStringFromClass([self class]);
    if (hidden && ([winCls containsString:@"Splash"] || [winCls containsString:@"Ad"] || [winCls containsString:@"Telecom"] || [winCls containsString:@"Popup"])) {
        return;
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

    /* 针对电信进入APP后中间弹窗广告的多次清理 */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
    });
}