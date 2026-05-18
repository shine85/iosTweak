#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

/* ---------  Known SDK Class Declarations  --------- */
@interface GDTSplashAd : NSObject @end
@interface GDTUnifiedInterstitialAd : NSObject @end
@interface GDTRewardedVideoAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface CSJInterstitialAd : NSObject @end
@interface BUSplashAdView : NSObject @end
@interface BUInterstitialAd : NSObject @end
@interface BUNativeExpressInterstitialAd : NSObject @end
@interface BUNativeSplashAd : NSObject @end
@interface KSAdSplashViewController : NSObject @end
@interface KSInterstitialAd : NSObject @end
@interface BaiduMobAdSplash : NSObject @end
@interface BaiduMobAdInterstitial : NSObject @end

/* Additional common ad SDKs */
@interface GADBannerView : UIView @end
@interface GADInterstitialAd : NSObject @end
@interface GADUnifiedInterstitialAd : NSObject @end
@interface GADFullscreenAd : NSObject @end
@interface SSDKBanner : UIView @end
@interface SSDKInterstitial : NSObject @end
@interface PAGView : UIView @end
@interface PAGInterstitialAd : NSObject @end

%group AdHooks

/* GDTSplashAd */
%hook GDTSplashAd
- (void)loadAd { /* skip */ }
- (void)showAdInWindow:(UIWindow *)window { [(UIWindow *)window setHidden:YES]; }
%end

/* GDTUnifiedInterstitialAd */
%hook GDTUnifiedInterstitialAd
- (void)loadAd { /* skip */ }
- (void)requestAd { /* skip */ }
- (void)present { /* skip */ }
- (void)presentFromViewController:(UIViewController *)controller { /* skip */ }
%end

/* GDTRewardedVideoAd */
%hook GDTRewardedVideoAd
- (void)loadAd { /* skip */ }
- (void)present { /* skip */ }
- (void)presentFromViewController:(UIViewController *)controller { /* skip */ }
%end

/* CSJSplashAd */
%hook CSJSplashAd
- (void)loadAd { /* skip */ }
- (void)showAdInWindow:(UIWindow *)window { [(UIWindow *)window setHidden:YES]; }
%end

/* CSJInterstitialAd */
%hook CSJInterstitialAd
- (void)loadAd { /* skip */ }
- (void)present { /* skip */ }
- (void)presentFromViewController:(UIViewController *)controller { /* skip */ }
%end

/* BUSplashAdView */
%hook BUSplashAdView
- (void)loadAd { /* skip */ }
- (void)showAdInWindow:(UIWindow *)window { [(UIWindow *)window setHidden:YES]; }
%end

/* BUInterstitialAd */
%hook BUInterstitialAd
- (void)loadAd { /* skip */ }
- (void)present { /* skip */ }
- (void)presentFromViewController:(UIViewController *)controller { /* skip */ }
%end

/* BUNativeExpressInterstitialAd */
%hook BUNativeExpressInterstitialAd
- (void)loadAd { /* skip */ }
- (void)present { /* skip */ }
- (void)presentFromViewController:(UIViewController *)controller { /* skip */ }
%end

/* BUNativeSplashAd */
%hook BUNativeSplashAd
- (void)loadAd { /* skip */ }
- (void)showAdInWindow:(UIWindow *)window { [(UIWindow *)window setHidden:YES]; }
%end

/* KSAdSplashViewController */
%hook KSAdSplashViewController
- (void)loadAd { /* skip */ }
- (void)showAdInWindow:(UIWindow *)window { [(UIWindow *)window setHidden:YES]; }
%end

/* KSInterstitialAd */
%hook KSInterstitialAd
- (void)loadAd { /* skip */ }
- (void)present { /* skip */ }
- (void)presentFromViewController:(UIViewController *)controller { /* skip */ }
%end

/* BaiduMobAdSplash */
%hook BaiduMobAdSplash
- (void)loadAd { /* skip */ }
- (void)showAdInWindow:(UIWindow *)window { [(UIWindow *)window setHidden:YES]; }
%end

/* BaiduMobAdInterstitial */
%hook BaiduMobAdInterstitial
- (void)loadAd { /* skip */ }
- (void)present { /* skip */ }
- (void)presentFromViewController:(UIViewController *)controller { /* skip */ }
%end

/* GADInterstitialAd */
%hook GADInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)rootViewController { /* skip */ }
%end

/* GADUnifiedInterstitialAd */
%hook GADUnifiedInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)rootViewController { /* skip */ }
%end

/* SSDKBanner */
%hook SSDKBanner
- (void)loadAd { /* skip */ }
%end

/* SSDKInterstitial */
%hook SSDKInterstitial
- (void)loadAd { /* skip */ }
- (void)presentFromViewController:(UIViewController *)rootViewController { /* skip */ }
%end

/* PAGInterstitialAd */
%hook PAGInterstitialAd
- (void)presentFromViewController:(UIViewController *)rootViewController { /* skip */ }
%end

%end

%group GlobalHooks

/* UIWindow hide all ad windows */
%hook UIWindow
- (void)makeKeyAndVisible {
    const char *clsName = object_getClassName(self);
    if (strstr(clsName, "Splash") || strstr(clsName, "Ad") ||
        strstr(clsName, "Banner") || strstr(clsName, "Interstitial")) {
        [(UIWindow *)self setHidden:YES];
        [self resignKeyWindow];
    } else {
        %orig;
    }
}
- (void)becomeKeyWindow {
    const char *clsName = object_getClassName(self);
    if (strstr(clsName, "Splash") || strstr(clsName, "Ad") ||
        strstr(clsName, "Banner") || strstr(clsName, "Interstitial")) {
        [(UIWindow *)self setHidden:YES];
        [self resignKeyWindow];
    } else {
        %orig;
    }
}
- (void)setHidden:(BOOL)hidden {
    const char *clsName = object_getClassName(self);
    if (strstr(clsName, "Splash") || strstr(clsName, "Ad") ||
        strstr(clsName, "Banner") || strstr(clsName, "Interstitial")) {
        %orig(YES);
        [self resignKeyWindow];
    } else {
        %orig(hidden);
    }
}
%end

/* UIViewController dismiss ads on appearance */
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    const char *clsName = object_getClassName(self);
    if (strstr(clsName, "Ad") || strstr(clsName, "Splash") ||
        strstr(clsName, "Interstitial") || strstr(clsName, "Popup") ||
        strstr(clsName, "Reward") || strstr(clsName, "Banner")) {
        [((UIViewController *)self) dismissViewControllerAnimated:NO completion:nil];
    }
}
%end

/* UIApplication launch */
%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL res = %orig(application, launchOptions);
    NSLog(@"[!!!] NoAds tweak injected");
    return res;
}
%end

%end