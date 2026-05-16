//  Tweak.xm
//  Anti‑Ad Surge – 2026‑05‑16
//
//  该文件实现对中国移动等应用的全方位开屏广告拦截，并对其核心类做双重兜底，
//  兼顾白屏/黑屏防护，保证一次性注入即可彻底根除开屏与插页广告。

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* ---------- 动态类声明 ----------
   自定义声明的类会在后方的 %hook 中使用，保证能被全局检测及编译链接。 */
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUSplashAdView : UIView @end
@interface BaiduMobAdSplash : NSObject @end
@interface KSAdSplashViewController : UIViewController @end
@interface CMSplashManager : NSObject @end
@interface CMSplashViewController : UIViewController @end
@interface CMSplashAd : UIView @end
@interface BiddingSplashAd : NSObject @end
@interface CMAdSplashView : UIView @end
@interface GADAppOpenAd : NSObject @end
@interface GADInterstitialAd : NSObject @end
@interface PAGAppOpenAd : NSObject @end
@interface PAGInterstitialAd : NSObject @end
@interface GADAdError : NSObject @end

/* ---------- 统一辅助工具 ----------
   1. 强制恢复子视图； 2. 兼容 iOS13+ 获取 KeyWindow； 3. 模拟 delegate 回调。 */
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count) forceRestoreSubViews(sub);
    }
}

static UIWindow* get_keyWindow(void) {
    UIWindow *found = nil;
    if (@available(iOS 13.0,*)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) { found = w; break; }
                }
            }
            if (found) break;
        }
    }
    if (!found) found = [[UIApplication sharedApplication] valueForKey:@"keyWindow"];
    return found;
}

static void dispatchDelegateCallback(id instance, SEL selector) {
    if (![instance respondsToSelector:selector]) return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id delegate = [instance performSelector:@selector(delegate)];
    if (!delegate) { return; }
    const struct {
        SEL sel;
        const char *name;
    } callbacks[] = {
        {@selector(splashAdClosed:), "splashAdClosed:"},
        {@selector(splashAdDidDismissFullScreenContent:), "splashAdDidDismissFullScreenContent:"},
        {@selector(splashAdDidClose:), "splashAdDidClose:"},
        {@selector(splashDidDismissScreen:), "splashDidDismissScreen:"}
    };
    for (int i = 0; i < sizeof(callbacks)/sizeof(callbacks[0]); i++) {
        if ([delegate respondsToSelector:callbacks[i].sel]) {
            [delegate performSelector:callbacks[i].sel withObject:instance];
            break;
        }
    }
#pragma clang diagnostic pop
}

/* ---------- 隐藏并清理所有 Splash Window ----------
   包括已完成创建的、延迟创建的以及挂载在子视图中的。 */
static void hideSplashWindows(NSArray *windows) {
    if (!windows) return;
    for (UIWindow *w in windows) {
        NSString *cls = NSStringFromClass([w class]);
        // 主要匹配已知窗口类
        if ([cls containsString:@"Splash"] ||
            [cls containsString:@"AdWindow"] ||
            [cls containsString:@"PAGWindow"] ||
            [cls containsString:@"CSJWindow"] ||
            [cls containsString:@"CSJSplash"] ||
            [cls containsString:@"KSAdSplashWindow"] ||
            [cls containsString:@"GDTWindow"] ||
            [cls containsString:@"GDTViewWindows"]) {
            [w setHidden:YES];
            [w setUserInteractionEnabled:NO];
            dispatchDelegateCallback(w, @selector(splashAdClosed:));
            continue;
        }
        // 针对可嵌套的子视图窗口
        for (UIView *sub in w.subviews) {
            NSString *subCls = NSStringFromClass([sub class]);
            if ([subCls containsString:@"Splash"] ||
                [subCls containsString:@"AdWindow"] ||
                [subCls containsString:@"PAGWindow"] ||
                [subCls containsString:@"CSJWindow"]) {
                [sub setHidden:YES];
            }
        }
    }
}

static void killSplashWindow(void) {
    NSArray *windows = nil;
    if (@available(iOS 13.0,*)) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            [tmp addObjectsFromArray:scene.windows];
        }
        windows = [tmp copy];
    } else {
        windows = [UIApplication sharedApplication].windows;
    }
    hideSplashWindows(windows);
    // 保证业务主窗口可见与可交互
    UIWindow *keyW = get_keyWindow();
    if (keyW) {
        if (![keyW isKeyWindow]) [keyW makeKeyAndVisible];
        if (keyW.hidden) keyW.hidden = NO;
        forceRestoreSubViews(keyW);
    }
}

/* ---------- 一次性初始化 ----------
   载入后立即清理，随后以 0.5 秒间隔持续监测。 */
%ctor {
    killSplashWindow();
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
            killSplashWindow();
        }];
    });
}

/* ---------- Core Hook ----------
   1. UIWindow：拦截关键方法，隐藏广告窗口。 */
%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *name = NSStringFromClass([self class]);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"AdWindow"] ||
        [name containsString:@"PAGWindow"] ||
        [name containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    NSString *name = NSStringFromClass([self class]);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"AdWindow"] ||
        [name containsString:@"PAGWindow"] ||
        [name containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden {
    NSString *name = NSStringFromClass([self class]);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"AdWindow"] ||
        [name containsString:@"PAGWindow"] ||
        [name containsString:@"CSJWindow"]) {
        if (!hidden) { %orig(YES); return; }
    }
    %orig(hidden);
}
- (void)addSubview:(UIView *)view {
    if (!view) {
        %orig(view);
        return;
    }
    NSString *cls = NSStringFromClass([view class]);
    if ([cls containsString:@"Splash"] ||
        [cls containsString:@"AdWindow"] ||
        [cls containsString:@"PAGWindow"] ||
        [cls containsString:@"CSJWindow"]) {
        [view setHidden:YES];
        return;
    }
    %orig(view);
}
%end

/* ---------- UIViewController ---------- */
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    Class cls = [self class];
    NSString *name = NSStringFromClass(cls);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"Bidding"] ||
        [name containsString:@"AdViewController"] ||
        [name containsString:@"CMAd"] ||
        [name containsString:@"Ad"]) {
        ((UIViewController *)self).view.hidden = YES;
        return;
    }
    %orig(animated);
}
- (void)viewDidAppear:(BOOL)animated {
    Class cls = [self class];
    NSString *name = NSStringFromClass(cls);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"Bidding"] ||
        [name containsString:@"AdViewController"] ||
        [name containsString:@"CMAd"] ||
        [name containsString:@"Ad"]) {
        UIViewController *vc = (UIViewController *)self;
        if (vc.presentingViewController) {
            [vc.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        } else {
            vc.view.hidden = YES;
        }
        dispatchDelegateCallback(self, @selector(splashAdClosed:));
        return;
    }
    %orig(animated);
}
%end

/* ---------- 广告 SDK ---------- */
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
- (void)showAdInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
- (void)showAdInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook BUSplashAdView
- (void)loadAd { }
- (void)showInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook BaiduMobAdSplash
- (void)loadAd { }
- (void)showInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook KSAdSplashViewController
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    dispatchDelegateCallback(self,@selector(splashAdClosed:));
}
%end

%hook CMSplashManager
- (instancetype)init { return nil; }
%end

%hook CMSplashViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil { return nil; }
- (instancetype)init { return nil; }
- (void)viewDidLoad { }
%end

%hook CMSplashAd
- (void)loadAd { }
- (void)show { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook BiddingSplashAd
- (instancetype)init { return nil; }
%end

%hook CMAdSplashView
- (void)layoutSubviews { }
- (void)didMoveToSuperview { }
%end

/* ---------- AdMob / PAG ---------- */
%hook GADAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)viewController completionHandler:(void (^)(GADAdError * _Nullable))completionHandler {
    if (completionHandler) completionHandler(nil);
}
%end

%hook GADInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook PAGAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook PAGInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

/* ---------- 通用弹窗防止误杀 ----------
   针对可在视图层面隐藏的广告子视图。 */
%hook UIView
- (void)didMoveToSuperview {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] ||
        [cls containsString:@"Ad"] ||
        [cls containsString:@"Banner"] ||
        [cls containsString:@"Loading"] ) {
        [self setHidden:YES];
    }
    %orig;
}
%end