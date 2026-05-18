/* ======== Tweak.xm ======== */
#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-arc"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
/* ---------- 预先声明所有可能出现的广告类 ---------- */
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUMNativeSplash : NSObject @end
@interface BUSplashAdView : UIView @end
@interface BUSplashZoomOutView : UIView @end
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
@interface AdsPopupWindow : UIWindow @end
@interface AdsDialogViewController : UIViewController @end

@interface MTGNativeAd : NSObject @end
@interface MTGAdManager : NSObject @end
@interface MTGVideoView : UIView @end

@interface NAAAdVideoPlayerController : NSObject @end
@interface NAAMediationPrivateAdLoader : NSObject @end

@interface UADisplayAdsAdapter : NSObject @end
@interface UnityAdsPlugin : NSObject @end

@interface GADInterstitialAd : NSObject @end
@interface GADBannerView : UIView @end

@interface GDTBannerView : UIView @end
@interface CSJBannerView : UIView @end
@interface BUNativeExpressBannerView : UIView @end
@interface KSBannerAdView : UIView @end
@interface BaiduMobAdBanner : UIView @end
@interface AdMobBannerView : UIView @end
@interface PAGLRewardedAd : UIView @end
@interface SigmobBanner : UIView @end

@interface APPBanners : NSObject @end
#pragma clang diagnostic pop

/* ---------- 工具方法 ---------- */
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

/* ---------- 全局窗口的非侵入式拦截 ---------- */
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

/* ---------- 全局 VC 的弹窗拦截 ---------- */
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

/* ---------- 插屏 / 弹窗广告拦截 ---------- */
%group InterstitialHook
%hook GDTUnifiedInterstitialAd
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook BUInterstitialAd
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook BUNativeExpressInterstitialAd
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook CSJInterstitialAd
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook KSInterstitialAd
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook KSAdInterstitialViewController
- (void)presentFromRootViewController:(UIViewController *)rootVC completion:(void (^)(void))completion { return; }
- (void)showInWindow:(UIWindow *)window { return; }
%end
%hook BaiduMobAdInterstitial
- (void)loadAd { return; }
- (void)showInWindow:(UIWindow *)window { return; }
%end
%hook RewardVideoAd
- (void)loadAd { return; }
- (void)presentFromViewController:(UIViewController *)vc completion:(void (^)(void))completion { return; }
%end
%hook xPopupAd
- (void)loadAd { return; }
- (void)presentFromViewController:(UIViewController *)vc completion:(void (^)(void))completion { return; }
%end
%hook MarketingDialog
- (void)showInView:(UIView *)view { return; }
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
%hook MTGAdManager
- (void)loadAd { return; }
- (void)presentAdIfAvailable { return; }
%end
%hook MTGVideoView
- (void)loadAd { return; }
- (void)presentAd { return; }
%end
%hook NAAMediationPrivateAdLoader
- (void)loadAd { return; }
- (void)presentAd { return; }
%end
%hook NAAAdVideoPlayerController
- (void)loadAd { return; }
- (void)presentAd { return; }
%end
%hook UADisplayAdsAdapter
- (void)loadAd { return; }
- (void)presentAd { return; }
%end
%hook UnityAdsPlugin
- (void)loadAd { return; }
- (void)presentAd { return; }
%end
%hook GADInterstitialAd
- (void)loadRequest:(id)request { return; }
- (void)presentFromRootViewController:(UIViewController *)rootViewController completionHandler:(void (^)(id))handler { return; }
%end
%end

/* ---------- 开屏广告拦截 ---------- */
%group SplashHook
%hook GDTSplashAd
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
- (void)loadAdWithCompletion:(void (^)(void))completion { return; }
%end
%hook CSJSplashAd
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook BUMNativeSplash
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook BUSplashAdView
- (void)requestAd { return; }
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook BUSplashZoomOutView
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook BaiduMobAdSplash
- (void)loadAd { return; }
- (void)showInWindow:(UIWindow *)window { return; }
%end
%hook KSAdSplashViewController
- (void)presentFromRootViewController:(UIViewController *)rootVC completion:(void (^)(void))completion { return; }
- (void)showInWindow:(UIWindow *)window { return; }
%end
%hook PAGLAppOpenAd
- (void)loadAd { return; }
- (void)presentFromRootViewController:(UIViewController *)rootVC animated:(BOOL)animated completion:(void (^)(void))completion { return; }
%end
%hook ABUSplashAd
- (void)loadAd { return; }
- (void)showAdInWindow:(UIWindow *)window { return; }
%end
%hook MTGAdManager
- (void)presentAd { return; }
%end
%hook MTGVideoView
- (void)presentAd { return; }
%end
%hook NAAMediationPrivateAdLoader
- (void)presentAd { return; }
%end
%hook NAAAdVideoPlayerController
- (void)presentAd { return; }
%end
%hook UADisplayAdsAdapter
- (void)presentAd { return; }
%end
%hook UnityAdsPlugin
- (void)presentAd { return; }
%end
%hook GADInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)rootViewController completionHandler:(void (^)(id))handler { return; }
%end
%end

/* ---------- 横幅广告拦截 ---------- */
%group BannerHook
%hook GDTBannerView
- (void)loadAd { return; }
- (void)layoutAdView { return; }
%end
%hook CSJBannerView
- (void)loadAd { return; }
- (void)layoutAdView { return; }
%end
%hook BUNativeExpressBannerView
- (void)loadAd { return; }
- (void)layoutAdView { return; }
%end
%hook KSBannerAdView
- (void)loadAd { return; }
- (void)layoutAdView { return; }
%end
%hook BaiduMobAdBanner
- (void)loadAd { return; }
- (void)layoutAdView { return; }
%end
%hook AdMobBannerView
- (void)loadAd { return; }
- (void)layoutAdView { return; }
%end
%hook PAGLRewardedAd
- (void)loadAd { return; }
- (void)presentFromRootViewController:(UIViewController *)rootVC animated:(BOOL)animated completion:(void (^)(void))completion { return; }
%end
%hook SigmobBanner
- (void)loadAd { return; }
- (void)layoutAdView { return; }
%end
%hook APPBanners
- (void)loadAd { return; }
- (void)presentAd { return; }
%end
%end

/* ---------- 通知广告关闭的通用实现 ---------- */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
static void notifyAdClosed(id adInstance) {
    if ([adInstance respondsToSelector:@selector(delegate)]) {
        id delegate = [adInstance performSelector:@selector(delegate)];
        if ([delegate respondsToSelector:@selector(splashAdClosed:)]) {
            [delegate performSelector:@selector(splashAdClosed:) withObject:adInstance];
        } else if ([delegate respondsToSelector:@selector(interstitialAdDidClose:)]) {
            [delegate performSelector:@selector(interstitialAdDidClose:) withObject:adInstance];
        } else if ([delegate respondsToSelector:@selector(splashAdDidDismissFullScreenContent:)]) {
            [delegate performSelector:@selector(splashAdDidDismissFullScreenContent:) withObject:adInstance];
        }
    }
    if ([adInstance isKindOfClass:[UIView class]]) {
        [(UIView *)adInstance setHidden:YES];
        [(UIView *)adInstance removeFromSuperview];
    } else if ([adInstance isKindOfClass:[UIViewController class]]) {
        [(UIViewController *)adInstance dismissViewControllerAnimated:NO completion:nil];
    }
}
#pragma clang diagnostic pop

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
    %init(GlobalWindowHook);
    %init(GlobalVCHook);
    %init(InterstitialHook);
    %init(SplashHook);
    %init(BannerHook);
    %init(AppLaunchHook);
}