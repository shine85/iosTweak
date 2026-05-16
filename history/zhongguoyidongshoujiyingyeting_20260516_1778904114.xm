// Tweak.xm
#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* ---------------- 动态类声明 ---------------- */
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
/* ------------ 其他 SDK 类 ------------ */
@interface GDTUnifiedInterstitialAd : NSObject @end
@interface BUInterstitialAd : NSObject @end
@interface BUNativeExpressInterstitialAd : NSObject @end
@interface CSJInterstitialAd : NSObject @end
@interface KSInterstitialAd : NSObject @end
@interface KSAdInterstitialViewController : UIViewController @end
@interface BaiduMobAdInterstitial : NSObject @end
@interface RewardVideoAd : NSObject @end

/* ---------------- 辅助工具 ---------------- */
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        [sub setHidden:NO];
        [sub setAlpha:1.0];
        if (sub.subviews.count) forceRestoreSubViews(sub);
    }
}

static UIWindow *getKeyWindow(void) {
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
    if (!delegate) return;
    const struct {
        SEL sel;
        const char *name;
    } callbacks[] = {
        { @selector(splashAdClosed:), "splashAdClosed:" },
        { @selector(splashAdDidDismissFullScreenContent:), "splashAdDidDismissFullScreenContent:" },
        { @selector(splashAdDidClose:), "splashAdDidClose:" },
        { @selector(splashDidDismissScreen:), "splashDidDismissScreen:" },
        { @selector(interstitialAdDidClose:), "interstitialAdDidClose:" }
    };
    for (int i = 0; i < sizeof(callbacks)/sizeof(callbacks[0]); i++) {
        if ([delegate respondsToSelector:callbacks[i].sel]) {
            [delegate performSelector:callbacks[i].sel withObject:instance];
            break;
        }
    }
#pragma clang diagnostic pop
}

static void hideSplashWindows(NSArray *windows) {
    if (!windows) return;
    for (UIWindow *w in windows) {
        NSString *cls = NSStringFromClass([w class]);
        if ([cls containsString:@"Splash"] ||
            [cls containsString:@"AdWindow"] ||
            [cls containsString:@"PAGWindow"] ||
            [cls containsString:@"CSJWindow"] ||
            [cls containsString:@"CSJSplash"] ||
            [cls containsString:@"KSAdSplashWindow"] ||
            [cls containsString:@"GDTWindow"]  ||
            [cls containsString:@"GDTViewWindows"])
        {
            [w setHidden:YES];
            [w setUserInteractionEnabled:NO];
            dispatchDelegateCallback(w, @selector(splashAdClosed:));
            continue;
        }
        for (UIView *sub in w.subviews) {
            NSString *subCls = NSStringFromClass([sub class]);
            if ([subCls containsString:@"Splash"] ||
                [subCls containsString:@"AdWindow"] ||
                [subCls containsString:@"PAGWindow"] ||
                [subCls containsString:@"CSJWindow"])
            {
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
    UIWindow *keyW = getKeyWindow();
    if (keyW) {
        if (![keyW isKeyWindow]) [keyW makeKeyAndVisible];
        if (keyW.hidden) keyW.hidden = NO;
        forceRestoreSubViews(keyW);
    }
}

/* ------------ 注入成功日志 ------------ */
%hook UIApplication
- (BOOL)applicationDidFinishLaunching:(UIApplication *)application {
    BOOL ret = %orig;
    NSLog(@"[!!!] Tweak 注入成功");
    return ret;
}
%end

/* ---------------- 初始化 ---------------- */
%ctor {
    killSplashWindow();
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
            killSplashWindow();
        }];
    });
}

/* ---------------- UIWindow Hook ---------------- */
%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *name = NSStringFromClass([self class]);
    if ([name containsString:@"Splash"] || [name containsString:@"AdWindow"] ||
        [name containsString:@"PAGWindow"] || [name containsString:@"CSJWindow"])
    {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    NSString *name = NSStringFromClass([self class]);
    if ([name containsString:@"Splash"] || [name containsString:@"AdWindow"] ||
        [name containsString:@"PAGWindow"] || [name containsString:@"CSJWindow"])
    {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden {
    NSString *name = NSStringFromClass([self class]);
    if ([name containsString:@"Splash"] || [name containsString:@"AdWindow"] ||
        [name containsString:@"PAGWindow"] || [name containsString:@"CSJWindow"])
    {
        if (!hidden) { %orig(YES); return; }
    }
    %orig(hidden);
}
- (void)addSubview:(UIView *)view {
    if (!view) { %orig(view); return; }
    NSString *cls = NSStringFromClass([view class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"AdWindow"] ||
        [cls containsString:@"PAGWindow"] || [cls containsString:@"CSJWindow"])
    {
        [view setHidden:YES];
        return;
    }
    %orig(view);
}
%end

/* ---------------- UIViewController Hook ---------------- */
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    Class cls = [self class];
    NSString *name = NSStringFromClass(cls);
    if ([name containsString:@"Splash"]  || [name containsString:@"Bidding"] ||
        [name containsString:@"AdViewController"]|| [name containsString:@"CMAd"] ||
        [name containsString:@"Ad"] || [name containsString:@"Interstitial"] ||
        [name containsString:@"Reward"] || [name containsString:@"Popup"])
    {
        [((UIViewController *)self) setViewHidden:YES];
        return;
    }
    %orig(animated);
}
- (void)viewDidAppear:(BOOL)animated {
    Class cls = [self class];
    NSString *name = NSStringFromClass(cls);
    if ([name containsString:@"Splash"]  || [name containsString:@"Bidding"] ||
        [name containsString:@"AdViewController"]|| [name containsString:@"CMAd"] ||
        [name containsString:@"Ad"] || [name containsString:@"Interstitial"] ||
        [name containsString:@"Reward"] || [name containsString:@"Popup"])
    {
        UIViewController *vc = (UIViewController *)self;
        if (vc.presentingViewController) {
            [((UIViewController *)self) dismissViewControllerAnimated:NO completion:nil];
        } else {
            [((UIViewController *)self) setViewHidden:YES];
        }
        dispatchDelegateCallback(self, @selector(splashAdClosed:));
        return;
    }
    %orig(animated);
}
%end

/* ------------ SDK Hooks -------------- */

/* 开屏 */
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

/* 插屏 / 弹窗 */
%hook GDTUnifiedInterstitialAd
- (void)loadAd { }
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook BUInterstitialAd
- (void)loadAd { }
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook BUNativeExpressInterstitialAd
- (void)loadAd { }
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook CSJInterstitialAd
- (void)loadAd { }
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook KSInterstitialAd
- (void)loadAd { }
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook KSAdInterstitialViewController
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    dispatchDelegateCallback(self,@selector(interstitialAdDidClose:));
}
%end

%hook BaiduMobAdInterstitial
- (void)loadAd { }
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook RewardVideoAd
- (void)showFromRootViewController:(UIViewController *)rootViewController { }
%end

/* 广告 SDK */
%hook GADAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)viewController
               completionHandler:(void (^)(GADAdError * _Nullable))completionHandler {
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

/* 视图层防误杀 */
%hook UIView
- (void)didMoveToSuperview {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"] ||
        [cls containsString:@"Banner"] || [cls containsString:@"Loading"])
    {
        [self setHidden:YES];
    }
    %orig;
}
%end