/* ======== Tweak.xm ======== */
#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/* ---------- 全部类声明 ---------- */
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUMNativeSplash : NSObject @end
@interface BUSplashAdView : NSObject @end
@interface BUSplashZoomOutView : NSObject @end
@interface BaiduMobAdSplash : NSObject @end
@interface KSAdSplashViewController : UIViewController @end
@interface PAGLAppOpenAd : NSObject @end
@interface ABUSplashAd : NSObject @end
@interface GDTUnifiedInterstitialAd : NSObject @end
@interface BUInterstitialAd : NSObject @end
@interface BUNativeExpressInterstitialAd : NSObject @end
@interface CSJInterstitialAd : NSObject @end
@interface KSInterstitialAd : NSObject @end
@interface KSAdInterstitialViewController : UIViewController @end
@interface BaiduMobAdInterstitial : NSObject @end
@interface RewardVideoAd : NSObject @end
@interface xPopupAd : NSObject @end
@interface MarketingDialog : UIViewController @end
@interface GDTBannerView : UIView @end
@interface CSJBannerView : UIView @end
@interface BUNativeExpressBannerView : UIView @end
@interface KSBannerAdView : UIView @end
@interface BaiduMobAdBanner : UIView @end
@interface AdMobBannerView : UIView @end
@interface PAGLRewardedAd : NSObject @end
@interface SigmobBanner : UIView @end
/* ---------- 其它可能出现的弹窗类 ---------- */
@interface AdsPopupWindow : UIWindow @end
@interface AdsDialogViewController : UIViewController @end
/* ---------- 工具方法 ---------- */
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}
/* ---------- 全局窗口拦截 ---------- */
%group GlobalWindowHook
%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] ||
        [cls containsString:@"Ad"] ||
        [cls containsString:@"Ads"] ||
        [cls containsString:@"Popup"]) {
        if (!self.hidden) {
            [self setHidden:YES];
            [self resignKeyWindow];
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (keyWindow && keyWindow.hidden) [keyWindow setHidden:NO];
        }
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] ||
        [cls containsString:@"Ad"] ||
        [cls containsString:@"Ads"] ||
        [cls containsString:@"Popup"]) {
        if (!self.hidden) {
            [self setHidden:YES];
            [self resignKeyWindow];
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (keyWindow && keyWindow.hidden) [keyWindow setHidden:NO];
        }
        return;
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] ||
        [cls containsString:@"Ad"] ||
        [cls containsString:@"Ads"] ||
        [cls containsString:@"Popup"]) {
        return;
    }
    %orig(hidden);
}
%end
%end
/* ---------- 全局 VC 拦截 ---------- */
%group GlobalVCHook
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Interstitial"] ||
        [cls containsString:@"Reward"] ||
        [cls containsString:@"Popup"] ||
        [cls containsString:@"Ads"] ||
        [cls containsString:@"Banner"]) {
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [(UIViewController *)self dismissViewControllerAnimated:NO completion:nil];
        }
    }
    %orig(animated);
}
%end
%end
/* ---------- 插屏/弹窗广告拦截 ---------- */
%group InterstitialHook
%hook GDTUnifiedInterstitialAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook BUInterstitialAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook BUNativeExpressInterstitialAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook CSJInterstitialAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook KSInterstitialAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook KSAdInterstitialViewController
- (void)presentFromRootViewController:(UIViewController *)rootVC completion:(void (^)(void))completion {}
- (void)showInWindow:(UIWindow *)window {}
%end
%hook BaiduMobAdInterstitial
- (void)loadAd {}
- (void)showInWindow:(UIWindow *)window {}
%end
%hook RewardVideoAd
- (void)loadAd {}
- (void)presentFromViewController:(UIViewController *)vc completion:(void (^)(void))completion {}
%end
%hook xPopupAd
- (void)loadAd {}
- (void)presentFromViewController:(UIViewController *)vc completion:(void (^)(void))completion {}
%end
%hook MarketingDialog
- (void)showInView:(UIView *)view {}
%end
%hook AdsPopupWindow
- (void)makeKeyAndVisible { return; }
- (void)becomeKeyWindow { return; }
- (void)setHidden:(BOOL)hidden { return; }
%end
%hook AdsDialogViewController
- (void)viewWillAppear:(BOOL)animated { return; }
- (void)viewDidAppear:(BOOL)animated { return; }
%end
%end
/* ---------- 开屏广告拦截 ---------- */
%group SplashHook
%hook GDTSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)loadAdWithCompletion:(void (^)(void))completion {}
- (void)loadAd { return; }
%end
%hook CSJSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook BUMNativeSplash
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook BUSplashAdView
- (void)requestAd {}
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook BUSplashZoomOutView
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook BaiduMobAdSplash
- (void)loadAd {}
- (void)showInWindow:(UIWindow *)window {}
%end
%hook KSAdSplashViewController
- (void)presentFromRootViewController:(UIViewController *)rootVC completion:(void (^)(void))completion {}
- (void)showInWindow:(UIWindow *)window {}
%end
%hook PAGLAppOpenAd
- (void)loadAd {}
- (void)presentFromRootViewController:(UIViewController *)rootVC animated:(BOOL)animated completion:(void (^)(void))completion {}
%end
%hook ABUSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%end
/* ---------- 横幅广告拦截 ---------- */
%group BannerHook
%hook GDTBannerView
- (void)loadAd {}
- (void)layoutAdView {}
%end
%hook CSJBannerView
- (void)loadAd {}
- (void)layoutAdView {}
%end
%hook BUNativeExpressBannerView
- (void)loadAd {}
- (void)layoutAdView {}
%end
%hook KSBannerAdView
- (void)loadAd {}
- (void)layoutAdView {}
%end
%hook BaiduMobAdBanner
- (void)loadAd {}
- (void)layoutAdView {}
%end
%hook AdMobBannerView
- (void)loadAd {}
- (void)layoutAdView {}
%end
%hook PAGLRewardedAd
- (void)loadAd {}
- (void)presentFromRootViewController:(UIViewController *)rootVC animated:(BOOL)animated completion:(void (^)(void))completion {}
%end
%hook SigmobBanner
- (void)loadAd {}
- (void)layoutAdView {}
%end
%end
/* ---------- 应用启动日志 ---------- */
%group AppLaunchHook
%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"[!!!] Tweak 注入成功");
    return %orig;
}
%end
%end
/* ---------- 构造器 ---------- */
%ctor {
    /* win hook */
    %init(GlobalWindowHook);
    /* vc hook */
    %init(GlobalVCHook);
    /* interstitial & popup hook */
    %init(InterstitialHook);
    /* splash ad hook */
    %init(SplashHook);
    /* banner/adview hook */
    %init(BannerHook);
    /* launch hook */
    %init(AppLaunchHook);
}
#pragma clang diagnostic pop