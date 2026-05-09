#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

/* ---------- Forward Declarations ---------- */
@class GDTSplashAd;
@class BUSplashAdView;
@class CSJSplashAd;
@class BaiduMobAdSplash;
@class KSAdSplashViewController;
@class CMSplashManager;
@class CMAdManager;

/* ---------- Hook Definitions ---------- */
%hook GDTSplashAd
-(void)loadAdAndShowInWindow:(UIWindow *)window { }
-(void)showAdInWindow:(UIWindow *)window { }
-(BOOL)isAdReady { return YES; }
%end

%hook BUSplashAdView
-(void)loadAd { }
-(void)showAdInWindow:(UIWindow *)window { }
-(BOOL)isAdValid { return YES; }
%end

%hook CSJSplashAd
-(void)loadAdAndShowInWindow:(UIWindow *)window { }
-(void)showAdInWindow:(UIWindow *)window { }
-(BOOL)hasAdAvailable { return YES; }
%end

%hook BaiduMobAdSplash
-(void)loadAndShowInWindow:(UIWindow *)window { }
-(BOOL)isReady { return YES; }
%end

%hook KSAdSplashViewController
-(void)loadSplashAd { }
-(void)showSplashAdInWindow:(UIWindow *)window { }
-(BOOL)isAdReady { return YES; }
%end

%hook CMSplashManager
-(void)requestSplashAd { }
-(void)showSplashAd { }
%end

%hook CMAdManager
-(void)fetchAndDisplayAd { }
%end

%hook UIViewController
-(void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"]) {
        self.view.hidden = YES;
    }
}
%end

/* ---------- Constructor ---------- */
%ctor {
    %init(GDTSplashAd = objc_getClass("GDTSplashAd"), BUSplashAdView = objc_getClass("BUSplashAdView"), CSJSplashAd = objc_getClass("CSJSplashAd"), BaiduMobAdSplash = objc_getClass("BaiduMobAdSplash"), KSAdSplashViewController = objc_getClass("KSAdSplashViewController"), CMSplashManager = objc_getClass("CMSplashManager"), CMAdManager = objc_getClass("CMAdManager"));
}
