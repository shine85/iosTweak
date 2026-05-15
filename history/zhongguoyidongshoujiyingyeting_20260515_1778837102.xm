#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* ---------- 动态类声明 ---------- */
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
@class GADAdError;     /* 前向声明 */

/* ---------- 工具函数 ---------- */
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
    const struct { SEL sel; const char *name; } callbacks[] = {
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

/* ---------- 销毁开屏窗口 ---------- */
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
    for (UIWindow *w in windows) {
        NSString *name = NSStringFromClass([w class]);
        if ([name containsString:@"Splash"] ||
            [name containsString:@"AdWindow"] ||
            [name containsString:@"PAGWindow"] ||
            [name containsString:@"CSJWindow"] ||
            [name containsString:@"CSJSplash"] ||
            [name containsString:@"KSAdSplashWindow"] ||
            [name containsString:@"GDTWindow"]) {
            [w setHidden:YES];
        }
    }
}

/* ---------- 预处理 ---------- */
%ctor {
    killSplashWindow();
    UIWindow *keyW = get_keyWindow();
    if (keyW) {
        // 确保业务主窗口可见
        if (![keyW isKeyWindow]) {
            [keyW makeKeyAndVisible];
        }
        // 再次遍历隐藏潜在的广告窗口
        killSplashWindow();
    }
}

/* ---------- Core Hook ---------- */
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
%end

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    Class cls = [self class];
    NSString *name = NSStringFromClass(cls);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"Bidding"] ||
        [name containsString:@"AdViewController"] ||
        [name containsString:@"CMAd"]) {
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
        [name containsString:@"CMAd"]) {
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