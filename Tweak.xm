/*  Tweak.xm
    目标应用: cn.suanya.zhixingHC (智行火车票‑12306官网出票)
    功能: 一次性完全消除所有常见广告(开屏、插屏、弹窗、Banner 等)
*/

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

/* ----------------- 标准辅助函数 ----------------- */
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count) forceRestoreSubViews(sub);
    }
}

/* ----------------- 防止对象属性点语法崩溃 ----------------- */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

/* ----------------- 统一代理回调封装 ----------------- */
static void callDelegateMethod(NSObject *adObj, SEL sel) {
    if ([adObj respondsToSelector:@selector(delegate)]) {
        id delegate = [adObj performSelector:@selector(delegate)];
        if ([delegate respondsToSelector:sel]) {
            [delegate performSelector:sel withObject:adObj];
        }
    }
}

/* ----------------- 预声明未知类 ----------------- */
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUMNativeSplash : NSObject @end
@interface BUSplashAdView : NSObject @end
@interface BUMSplashZoomOutView : NSObject @end
@interface BaiduMobAdSplash : NSObject @end
@interface KSAdSplashViewController : NSObject @end
@interface PAGLAppOpenAd : NSObject @end
@interface ABUSplashAd : NSObject @end

@interface GDTUnifiedInterstitialAd : NSObject @end
@interface BUInterstitialAd : NSObject @end
@interface BUNativeExpressInterstitialAd : NSObject @end
@interface CSJInterstitialAd : NSObject @end
@interface KSInterstitialAd : NSObject @end
@interface KSAdInterstitialViewController : NSObject @end
@interface BaiduMobAdInterstitial : NSObject @end
@interface RewardVideoAd : NSObject @end
@interface xPopupAd : NSObject @end
@interface MarketingDialog : NSObject @end
@interface MarketingPopup : NSObject @end

@interface SplashWindow : UIWindow @end
@interface AdWindow : UIWindow @end
@interface PAGWindow : UIWindow @end
@interface AdContainerView : UIView @end

/* ----------------- Hook 初始化 ----------------- */
%ctor {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:UIDeviceOrientationDidChangeNotification
                      object:nil
                       queue:nil
                  usingBlock:^(NSNotification *note) {
        // 维持主窗口
        UIApplication *app = [UIApplication sharedApplication];
        UIWindow *key = app.keyWindow ?: app.windows.firstObject;
        if (key.hidden) {
            if (key) key.hidden = NO;
        }
        forceRestoreSubViews(key);
    }];

    NSLog(@"[!!!] Tweak 注入成功 (cn.suanya.zhixingHC)");
}

#pragma clang diagnostic pop

/* ==================== 开屏广告 Hooks ==================== */
%group SplashHooks
%init(GDTSplashAd=objc_getClass("GDTSplashAd"));
%hook GDTSplashAd
- (BOOL)loadAd { return NO; }
- (void)showAdInWindow:(UIWindow *)window { /* 阻止展示 */ }
%end

%init(CSJSplashAd=objc_getClass("CSJSplashAd"));
%hook CSJSplashAd
- (BOOL)loadAd { return NO; }
- (void)showAdInWindow:(UIWindow *)window { }
%end

%init(BUMNativeSplash=objc_getClass("BUMNativeSplash"));
%hook BUMNativeSplash
- (BOOL)loadAd { return NO; }
- (void)showAd { }
%end

%init(BUSplashAdView=objc_getClass("BUSplashAdView"));
%hook BUSplashAdView
- (void)loadAd { return; }
- (void)showAd { return; }
%end

%init(BUMSplashZoomOutView=objc_getClass("BUMSplashZoomOutView"));
%hook BUMSplashZoomOutView
- (void)loadAd { return; }
- (void)showAd { return; }
%end

%init(BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"));
%hook BaiduMobAdSplash
- (void)startWithViewController:(UIViewController *)vc { return; }
- (void)show { return; }
%end

%init(KSAdSplashViewController=objc_getClass("KSAdSplashViewController"));
%hook KSAdSplashViewController
- (void)loadAd { return; }
- (void)show { return; }
%end

%init(PAGLAppOpenAd=objc_getClass("PAGLAppOpenAd"));
%hook PAGLAppOpenAd
- (BOOL)loadAd { return NO; }
- (void)showAdInWindow:(UIWindow *)window { }
%end

%init(ABUSplashAd=objc_getClass("ABUSplashAd"));
%hook ABUSplashAd
- (void)displayInWindow:(UIWindow *)window { }
- (BOOL)loadAd { return NO; }
%end
%end

/* ==================== 插屏/弹窗广告 Hooks ==================== */
%group InterstitialHooks
%init(GDTUnifiedInterstitialAd=objc_getClass("GDTUnifiedInterstitialAd"));
%hook GDTUnifiedInterstitialAd
- (void)loadAd { return; }
- (void)showAdFromRootViewController:(UIViewController *)root { return; }
%end

%init(BUInterstitialAd=objc_getClass("BUInterstitialAd"));
%hook BUInterstitialAd
- (void)loadAd { return; }
- (void)showAdWithRootViewController:(UIViewController *)root { return; }
%end

%init(BUNativeExpressInterstitialAd=objc_getClass("BUNativeExpressInterstitialAd"));
%hook BUNativeExpressInterstitialAd
- (void)loadAd { return; }
- (void)showInRootViewController:(UIViewController *)root { return; }
%end

%init(CSJInterstitialAd=objc_getClass("CSJInterstitialAd"));
%hook CSJInterstitialAd
- (void)loadAd { return; }
- (void)showFromRootViewController:(UIViewController *)root { return; }
%end

%init(KSInterstitialAd=objc_getClass("KSInterstitialAd"));
%hook KSInterstitialAd
- (void)loadAd { return; }
- (void)showFromViewController:(UIViewController *)root { return; }
%end

%init(KSAdInterstitialViewController=objc_getClass("KSAdInterstitialViewController"));
%hook KSAdInterstitialViewController
- (void)loadAndShow { return; }
- (void)displayWithRootVC:(UIViewController *)root { return; }
%end

%init(BaiduMobAdInterstitial=objc_getClass("BaiduMobAdInterstitial"));
%hook BaiduMobAdInterstitial
- (void)loadAd { return; }
- (void)showInRoot:(UIViewController *)root { return; }
%end

%init(RewardVideoAd=objc_getClass("RewardVideoAd"));
%hook RewardVideoAd
- (void)loadAd { return; }
- (void)show { return; }
%end

%init(xPopupAd=objc_getClass("xPopupAd"));
%hook xPopupAd
- (void)show { return; }
- (void)loadAd { return; }
%end

%init(MarketingDialog=objc_getClass("MarketingDialog"));
%hook MarketingDialog
- (void)show { return; }
- (void)loadAd { return; }
%end

%init(MarketingPopup=objc_getClass("MarketingPopup"));
%hook MarketingPopup
- (void)show { return; }
- (void)loadAd { return; }
%end
%end

/* ==================== 广告弹窗窗口兜底 Hooks ==================== */
%group WindowHooks
%init(SplashWindow=objc_getClass("SplashWindow"));
%hook SplashWindow
- (void)makeKeyAndVisible { [self setHidden:YES]; }
- (void)becomeKeyWindow { [self setHidden:YES]; }
- (void)setHidden:(BOOL)hidden { /* 阻止隐藏 */ }
%end

%init(AdWindow=objc_getClass("AdWindow"));
%hook AdWindow
- (void)makeKeyAndVisible { [self setHidden:YES]; }
- (void)becomeKeyWindow { [self setHidden:YES]; }
- (void)setHidden:(BOOL)hidden { /* 阻止 */ }
%end

%init(PAGWindow=objc_getClass("PAGWindow"));
%hook PAGWindow
- (void)makeKeyAndVisible { [self setHidden:YES]; }
- (void)becomeKeyWindow { [self setHidden:YES]; }
- (void)setHidden:(BOOL)hidden { /* 阻止 */ }
%end

%init(AdContainerView=objc_getClass("AdContainerView"));
%hook AdContainerView
- (void)layoutSubviews { /* 让广告视图不可见 */; }
%end
%end

/* ==================== 视图控制器层面全杀 ==================== */
%group ViewControllerHooks
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    Class cl = object_getClass(self);
    NSString *clsName = NSStringFromClass(cl);
    // 只拦截带广告关键字的类名
    if ([clsName containsString:@"Interstitial"] ||
        [clsName containsString:@"Ad"] ||
        [clsName containsString:@"Reward"] ||
        [clsName containsString:@"Popup"] ||
        [clsName containsString:@"Marketing"]) {
        // 隐藏并销毁
        [((UIViewController *)self) dismissViewControllerAnimated:NO completion:nil];
        [((UIViewController *)self).view setHidden:YES];
        [((UIViewController *)self).view removeFromSuperview];
    }
}
%end
%end

/* ==================== 其他全局兜底 ==================== */
%group GlobalHooks
%hook UIApplication
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    %orig(app, options);
    // 让主窗口始终存在
    UIWindow *key = [app.keyWindow isHidden] ? app.windows.firstObject : app.keyWindow;
    if (key) key.hidden = NO;
    return YES;
}
%end
%end