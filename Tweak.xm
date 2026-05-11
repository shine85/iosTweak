#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dispatch/dispatch.h>

@class GDTSplashAd;
@class CSJSplashAd;
@class BUSplashAdView;
@class BaiduMobAdSplash;
@class KSAdSplashViewController;
@class CtSplashManager;
@class CTAdSplashManager;

// 辅助函数声明
static void hookIfExists(const char *clsName, SEL sel, IMP newImp, IMP *orig);
static BOOL hideSplashIfButtonFound(UIView *root);
static void scheduleSplashSkipCheck(UIView *root, NSInteger attempt);
static void hideWindowAdViewsIfNeeded(UIView *view);
static UIWindow *getKeyWindow(void);
static void forceRestoreSubViews(UIView *view);
static void forceMainUIVisible(void);
static void aggressiveRestoreUI(void);
static void hideAllAdViews(void);
static BOOL isLikelyMainContentView(UIView *view);

// 辅助函数定义
static void hookIfExists(const char *clsName, SEL sel, IMP newImp, IMP *orig) {
    Class cls = objc_getClass(clsName);
    if (cls) {
        MSHookMessageEx(cls, sel, newImp, orig);
    }
}

static BOOL isLikelyMainContentView(UIView *view) {
    if (!view) return NO;
    NSString *cls = NSStringFromClass([view class]);
    return [cls containsString:@"Home"] || [cls containsString:@"Main"] || 
           [cls containsString:@"Content"] || [cls containsString:@"Tab"] || 
           [cls containsString:@"Root"] || [cls containsString:@"Scroll"] ||
           [cls containsString:@"Table"] || [cls containsString:@"Collection"] ||
           [cls containsString:@"ViewController"];
}

static BOOL hideSplashIfButtonFound(UIView *root) {
    for (UIView *sub in root.subviews) {
        if ([sub isKindOfClass:[UIButton class]]) {
            NSString *title = ((UIButton *)sub).currentTitle;
            if (title && ([title containsString:@"跳过"] || [title containsString:@"Skip"] || 
                         [title containsString:@"关闭"] || [title containsString:@"取消"] || 
                         [title containsString:@"进入"])) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sub setHidden:NO];
                    if (sub.superview) [sub.superview setHidden:NO];
                    if ([sub respondsToSelector:@selector(sendActionsForControlEvents:)]) {
                        [(UIControl *)sub sendActionsForControlEvents:UIControlEventTouchUpInside];
                    }
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
    const NSInteger maxAttempts = 80;
    const double interval = 0.08;
    if (attempt >= maxAttempts) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (!hideSplashIfButtonFound(root)) {
            scheduleSplashSkipCheck(root, attempt + 1);
        }
    });
}

static void hideWindowAdViewsIfNeeded(UIView *view) {
    if (!view) return;
    for (UIView *v in view.subviews) {
        NSString *cls = NSStringFromClass([v class]);
        BOOL isAdView = [cls containsString:@"Splash"] || [cls containsString:@"Ad"] || 
                        [cls containsString:@"GDTSplash"] || [cls containsString:@"CSJSplash"] ||
                        [cls containsString:@"BUSplash"] || [cls containsString:@"BaiduMobAd"] ||
                        [cls containsString:@"KSAd"] || [cls containsString:@"CTSplash"] ||
                        [cls containsString:@"CtSplash"] || [cls containsString:@"CTAd"] ||
                        [cls containsString:@"TelecomSplash"] || [cls containsString:@"ChinaTelecomSplash"] ||
                        [cls containsString:@"Promotion"] || [cls containsString:@"Dialog"] ||
                        [cls containsString:@"LaunchScreen"] || [cls containsString:@"Modal"] ||
                        [cls containsString:@"FullScreen"] || [cls containsString:@"Cover"];
        
        BOOL isCentralPopup = (v.frame.size.width > 120 && v.frame.size.height > 120) &&
                             (CGRectGetMidX(v.frame) > CGRectGetWidth(view.bounds)*0.1 && 
                              CGRectGetMidX(v.frame) < CGRectGetWidth(view.bounds)*0.9) &&
                             (CGRectGetMidY(v.frame) > CGRectGetHeight(view.bounds)*0.1 && 
                              CGRectGetMidY(v.frame) < CGRectGetHeight(view.bounds)*0.9);
        
        if (isAdView || isCentralPopup) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [v setHidden:YES];
                [v setAlpha:0.0];
                [v removeFromSuperview];
            });
        } else if (!isLikelyMainContentView(v)) {
            hideWindowAdViewsIfNeeded(v);
        }
    }
}

static UIWindow *getKeyWindow(void) {
    UIApplication *app = [UIApplication sharedApplication];
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in app.connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *win in scene.windows) {
                    if (win.isKeyWindow) return win;
                }
            }
        }
        return app.windows.firstObject;
    } else {
        return [app keyWindow];
    }
}

static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        if (![cls containsString:@"Splash"] && ![cls containsString:@"Ad"] && 
            ![cls containsString:@"Popup"] && ![cls containsString:@"Dialog"] &&
            ![cls containsString:@"TelecomSplash"] && ![cls containsString:@"CtSplash"] &&
            ![cls containsString:@"GDTSplash"] && ![cls containsString:@"CSJSplash"] &&
            ![cls containsString:@"Promotion"] && ![cls containsString:@"Launch"] &&
            ![cls containsString:@"Modal"] && ![cls containsString:@"Cover"]) {
            [sub setHidden:NO];
            [sub setAlpha:1.0];
            [sub setUserInteractionEnabled:YES];
            forceRestoreSubViews(sub);
        }
    }
}

static void forceMainUIVisible(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWin = getKeyWindow();
        if (keyWin) {
            [keyWin setHidden:NO];
            [keyWin setAlpha:1.0];
            [keyWin setBackgroundColor:[UIColor whiteColor]];
            [keyWin layoutIfNeeded];
            
            if (keyWin.rootViewController) {
                UIViewController *rootVC = keyWin.rootViewController;
                UIView *rootView = rootVC.view;
                if (rootView) {
                    [rootView setHidden:NO];
                    [rootView setAlpha:1.0];
                    [rootView setBackgroundColor:[UIColor whiteColor]];
                    [rootView setUserInteractionEnabled:YES];
                    [rootView layoutIfNeeded];
                    [rootView setNeedsLayout];
                    [rootView layoutSubviews];
                    
                    forceRestoreSubViews(rootView);
                }
            }
        }
    });
}

static void aggressiveRestoreUI(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
        
        UIWindow *keyWin = getKeyWindow();
        if (keyWin && keyWin.rootViewController) {
            UIViewController *rootVC = keyWin.rootViewController;
            if (rootVC.view) {
                [rootVC.view setNeedsDisplay];
                [rootVC.view setNeedsLayout];
                [rootVC.view layoutSubviews];
                
                for (UIView *sub in rootVC.view.subviews) {
                    if (isLikelyMainContentView(sub)) {
                        [sub setHidden:NO];
                        [sub setAlpha:1.0];
                        [sub setUserInteractionEnabled:YES];
                    }
                }
            }
        }
    });
}

static void hideAllAdViews(void) {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIWindow *win in app.windows) {
        hideWindowAdViewsIfNeeded(win);
    }
    UIWindow *keyWin = getKeyWindow();
    if (keyWin) hideWindowAdViewsIfNeeded(keyWin);
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

/* ---------- UIViewController 强化拦截(针对白屏重点优化) ---------- */
%hook UIViewController
- (void)viewDidLoad {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    BOOL isAd = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"] ||
                [clsName containsString:@"CTAd"] || [clsName containsString:@"TelecomSplash"] ||
                [clsName containsString:@"CtSplashView"] || [clsName containsString:@"ChinaTelecom"] ||
                [clsName containsString:@"Popup"] || [clsName containsString:@"Dialog"] ||
                [clsName containsString:@"Promotion"] || [clsName containsString:@"Cover"];
    
    if (isAd) {
        [[self view] setHidden:YES];
        [[self view] setAlpha:0.0];
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:NO completion:nil];
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
                [clsName containsString:@"Popup"] || [clsName containsString:@"Dialog"] ||
                [clsName containsString:@"Promotion"] || [clsName containsString:@"Cover"];
    
    if (isAd) {
        [[self view] setHidden:YES];
        [[self view] setAlpha:0.0];
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:NO completion:nil];
            });
        }
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hideAllAdViews();
            forceMainUIVisible();
            aggressiveRestoreUI();
            if ([self view]) scheduleSplashSkipCheck([self view], 0);
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hideAllAdViews();
            forceMainUIVisible();
            aggressiveRestoreUI();
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hideAllAdViews();
            forceMainUIVisible();
            aggressiveRestoreUI();
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hideAllAdViews();
            forceMainUIVisible();
            aggressiveRestoreUI();
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            hideAllAdViews();
            forceMainUIVisible();
            aggressiveRestoreUI();
        });
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    BOOL isAd = [clsName containsString:@"Splash"] || [clsName containsString:@"Ad"] || 
                [clsName containsString:@"Launch"] || [clsName containsString:@"CTSplash"] ||
                [clsName containsString:@"Telecom"] || [clsName containsString:@"Popup"] ||
                [clsName containsString:@"Dialog"] || [clsName containsString:@"Cover"];
    if (isAd) {
        [[self view] setHidden:YES];
        [[self view] setAlpha:0.0];
    }
}

- (void)viewDidLayoutSubviews {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    if (![clsName containsString:@"Splash"] && ![clsName containsString:@"Ad"] && 
        ![clsName containsString:@"Popup"] && ![clsName containsString:@"Dialog"] &&
        ![clsName containsString:@"Cover"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            forceMainUIVisible();
            aggressiveRestoreUI();
        });
    }
}

- (void)viewWillLayoutSubviews {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    if (![clsName containsString:@"Splash"] && ![clsName containsString:@"Ad"] && 
        ![clsName containsString:@"Popup"] && ![clsName containsString:@"Dialog"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            forceMainUIVisible();
        });
    }
}
%end

/* 拦截 UIWindow - 加强过滤 */
%hook UIWindow
- (void)addSubview:(UIView *)view {
    if (!view) {
        %orig;
        return;
    }
    NSString *cls = NSStringFromClass([view class]);
    BOOL isAdSubview = [cls containsString:@"Splash"] || [cls containsString:@"Ad"] || 
                       [cls containsString:@"GDTSplash"] || [cls containsString:@"CSJSplash"] ||
                       [cls containsString:@"BUSplash"] || [cls containsString:@"CtSplash"] ||
                       [cls containsString:@"TelecomSplash"] || [cls containsString:@"ChinaTelecom"] ||
                       [cls containsString:@"Popup"] || [cls containsString:@"Dialog"] ||
                       [cls containsString:@"Promotion"] || [cls containsString:@"Modal"] ||
                       [cls containsString:@"Launch"] || [cls containsString:@"Cover"];
    
    if (isAdSubview) {
        return;
    }
    %orig;
}

- (void)setHidden:(BOOL)hidden {
    NSString *winCls = NSStringFromClass([self class]);
    if (hidden && ([winCls containsString:@"Splash"] || [winCls containsString:@"Ad"] || 
                   [winCls containsString:@"Telecom"] || [winCls containsString:@"Popup"] ||
                   [winCls containsString:@"Cover"])) {
        return;
    }
    %orig;
}
%end

%hook UIApplication
- (void)setStatusBarHidden:(BOOL)hidden withAnimation:(UIStatusBarAnimation)animation {
    %orig(NO, animation);
}
%end

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

    // 针对电信APP白屏重点强化：极早触发 + 更高频恢复
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
        aggressiveRestoreUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.08 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
        aggressiveRestoreUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
        aggressiveRestoreUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
        aggressiveRestoreUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
        aggressiveRestoreUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        hideAllAdViews();
        forceMainUIVisible();
        aggressiveRestoreUI();
    });
}