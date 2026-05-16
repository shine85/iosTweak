// Tweak.xm
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

@interface UIWindow : UIView @end
@interface UIApplication : UIResponder @end
@interface UIViewController : UIResponder @end
@interface NSObject : UIResponder @end

@interface ZXHTData : NSObject @end
static ZXHTData *adData = nil;

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

@interface UIWebView : UIView @end
@interface WKWebView : UIView @end

%ctor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adData = [[ZXHTData alloc] init];
    });
    TWEAK_STARTUP_LOG(@"[!!!] Tweak 注入成功");
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

%group CommonAdHacks
%hook UIWindow
- (void)makeKeyAndVisible {
    if ([self isKindOfClass:NSClassFromString(@"AdWindow")] ||
        [self isKindOfClass:NSClassFromString(@"SplashWindow")] ||
        [self isKindOfClass:NSClassFromString(@"PAGWindow")]) {
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    if ([self isKindOfClass:NSClassFromString(@"AdWindow")] ||
        [self isKindOfClass:NSClassFromString(@"SplashWindow")] ||
        [self isKindOfClass:NSClassFromString(@"PAGWindow")]) {
        return;
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden {
    if ([NSStringFromClass([self class]) containsString:@"AdWindow"] ||
        [NSStringFromClass([self class]) containsString:@"SplashWindow"] ||
        [NSStringFromClass([self class]) containsString:@"PAGWindow"]) {
        %orig(YES);
        return;
    }
    %orig;
}
%end
#pragma clang diagnostic pop

%group FlowControl
%hook UIApplication
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig;
    NSLog(@"[!!!] Tweak 注入成功");
}
%end

%group SplashAds
%hook GDTSplashAd
- (BOOL)loadAd { return NO; }
- (void)showAdInWindow:(UIWindow *)window {}
%end

%hook CSJSplashAd
- (BOOL)loadAd { return NO; }
- (void)showAdInWindow:(UIWindow *)window {}
%end

%hook BUMNativeSplash
- (BOOL)loadAd { return NO; }
- (void)showAdInWindow:(UIWindow *)window {}
%end

%hook BUSplashAdView
- (void)loadAd {}
%end

%hook BUSplashZoomOutView
- (void)loadAd {}
%end

%hook BaiduMobAdSplash
- (void)requestAdWithView:(UIView *)view {}
%end

%hook KSAdSplashViewController
- (instancetype)initWithFrame:(CGRect)frame { return Nil; }
%end

%hook PAGLAppOpenAd
- (void)loadAd {}
- (void)presentWithRootViewController:(UIViewController *)rootViewController {}
%end

%hook ABUSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%end

%group InterstitialAds
%hook GDTUnifiedInterstitialAd
- (BOOL)loadAd { return NO; }
- (void)presentFromViewController:(UIViewController *)viewController {}
%end

%hook BUInterstitialAd
- (BOOL)loadAd { return NO; }
- (void)presentFromViewController:(UIViewController *)viewController {}
%end

%hook BUNativeExpressInterstitialAd
- (BOOL)loadAd { return NO; }
- (void)presentFromViewController:(UIViewController *)viewController {}
%end

%hook CSJInterstitialAd
- (BOOL)loadAd { return NO; }
- (void)presentFromViewController:(UIViewController *)viewController {}
%end

%hook KSInterstitialAd
- (BOOL)loadAd { return NO; }
- (void)presentFromViewController:(UIViewController *)viewController {}
%end

%hook KSAdInterstitialViewController
- (instancetype)initWithFrame:(CGRect)frame { return Nil; }
%end

%hook BaiduMobAdInterstitial
- (void)showInterstitialAdWithRootViewController:(UIViewController *)viewController {}
%end
%end

%group PopupAndReward
%hook RewardVideoAd
- (BOOL)loadAd { return NO; }
- (void)presentFromRootViewController:(UIViewController *)rootViewController {}
%end

%hook xPopupAd
- (void)show {}
%end

%hook MarketingDialog
- (void)show {}
%end
%end

%group ViewHijack
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    if ([self isKindOfClass:NSClassFromString(@"AdvertisingViewController")] ||
        [NSStringFromClass([self class]) containsString:@"Interstitial"] ||
        [NSStringFromClass([self class]) containsString:@"AdView"] ||
        [NSStringFromClass([self class]) containsString:@"Popup"]) {
        [(UIViewController *)self dismissViewControllerAnimated:NO completion:nil];
    }
}
%end

%hook UIView
- (void)didMoveToWindow {
    %orig;
    if ([NSStringFromClass([self class]) containsString:@"AdView"]) {
        self.hidden = YES;
        [self removeFromSuperview];
    }
}
%end
%end

%group WebAds
%hook UIWebView
- (void)loadRequest:(NSURLRequest *)request {}
%end

%hook WKWebView
- (void)loadRequest:(NSURLRequest *)request {}
%end
%end