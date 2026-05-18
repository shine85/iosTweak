/* ======== Tweak.xm ======== */
#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

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
    if ([NSStringFromClass([self class]) containsString:@"Splash"]
        || [NSStringFromClass([self class]) containsString:@"Ad"]) {
        if (!self.hidden) {
            [self setHidden:YES];
            [self resignKeyWindow];
            // 恢复主窗口显示
            UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
            if (keyWindow && keyWindow.hidden) [keyWindow setHidden:NO];
        }
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    if ([NSStringFromClass([self class]) containsString:@"Splash"]
        || [NSStringFromClass([self class]) containsString:@"Ad"]) {
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
    if ([NSStringFromClass([self class]) containsString:@"Splash"]
        || [NSStringFromClass([self class]) containsString:@"Ad"]) {
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
    if ([NSStringFromClass([self class]) containsString:@"Interstitial"]
        || [NSStringFromClass([self class]) containsString:@"Reward"]
        || [NSStringFromClass([self class]) containsString:@"Popup"]) {
        if ([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
            [(UIViewController *)self dismissViewControllerAnimated:NO completion:nil];
        }
    }
    %orig(animated);
}
%end
%end

/* ---------- 开屏广告拦截 ---------- */
%group SplashAdHook
%hook GDTSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end

%hook CSJSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end

%hook BUMNativeSplash
- (void)loadAd {}
- (void)showInWindow:(UIWindow *)window {}
%end

%hook BUSplashAdView
- (void)loadAd {}
- (void)showInWindow:(UIWindow *)window {}
%end

%hook BUSplashZoomOutView
- (void)loadAd {}
- (void)showInWindow:(UIWindow *)window {}
%end

%hook BaiduMobAdSplash
- (void)loadAd {}
- (void)showInWindow:(UIWindow *)offsetWindow {}
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
- (void)showInWindow:(UIWindow *)window {}
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
- (void)showInWindow:(UIWindow *)window {}
%end

%hook BUNativeExpressInterstitialAd
- (void)loadAd {}
- (void)showInWindow:(UIWindow *)window {}
%end

%hook CSJInterstitialAd
- (void)loadAd {}
- (void)showInWindow:(UIWindow *)window {}
%end

%hook KSInterstitialAd
- (void)loadAd {}
- (void)showInWindow:(UIWindow *)window {}
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

%ctor {
    %init(GlobalWindowHook);
    %init(GlobalVCHook);
    %init(SplashAdHook);
    %init(InterstitialHook);
    %init(BannerHook);
    %init(AppLaunchHook);
}
#pragma clang diagnostic pop