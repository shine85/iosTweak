#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// Forward declarations to silence compiler warnings
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUSplashAdView : NSObject @end
@interface BaiduMobAdSplash : NSObject @end
@interface KSAdSplashViewController : UIViewController @end
@interface CMSplashManager : NSObject @end
@interface BUNativeExpressRewardedVideoAd : NSObject @end
@interface GDTSplashAdDelegate : NSObject @end
@interface CSJAdManager : NSObject @end

%ctor {
    %init(GDTSplashAd = objc_getClass("GDTSplashAd"));
    %init(CSJSplashAd = objc_getClass("CSJSplashAd"));
    %init(BUSplashAdView = objc_getClass("BUSplashAdView"));
    %init(BaiduMobAdSplash = objc_getClass("BaiduMobAdSplash"));
    %init(KSAdSplashViewController = objc_getClass("KSAdSplashViewController"));
    %init(CMSplashManager = objc_getClass("CMSplashManager"));
    %init(BUNativeExpressRewardedVideoAd = objc_getClass("BUNativeExpressRewardedVideoAd"));
    %init(GDTSplashAdDelegate = objc_getClass("GDTSplashAdDelegate"));
    %init(CSJAdManager = objc_getClass("CSJAdManager"));
}

// --------- Block all splash loading / showing methods ----------
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)loadAndShow { }
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)showAdInWindow:(UIWindow *)window { }
%end

%hook BUSplashAdView
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)showInWindow:(UIWindow *)window { }
%end

%hook BaiduMobAdSplash
- (void)loadAndDisplay { }
- (void)showAd { }
%end

%hook KSAdSplashViewController
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)showAd { }
%end

%hook CMSplashManager
- (void)fetchAndShowSplash { }
- (void)loadSplash { }
%end

// --------- Rewarded video tweaks (force skip countdown) ----------
%hook BUNativeExpressRewardedVideoAd
- (NSInteger)countdownTime { return 0; }
- (BOOL)isAdValid { return YES; }
%end

// --------- Prevent splash view controllers from appearing ----------
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls rangeOfString:@"Splash"].location != NSNotFound ||
        [cls rangeOfString:@"Ad"].location != NSNotFound) {
        // Do not call %orig to keep the ad/splash view hidden
        return;
    }
    %orig;
}
%end
