#import <UIKit/UIKit.h>
#import <substrate.h>

@interface GDTSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)showAdInWindow:(UIWindow *)window;
@end

@interface CSJSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)showAdInWindow:(UIWindow *)window;
@end

@interface BUSplashAdView : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)showAdInWindow:(UIWindow *)window;
@end

@interface BaiduMobAdSplash : NSObject
- (void)loadAndShowInWindow:(UIWindow *)window;
- (void)showInWindow:(UIWindow *)window;
@end

@interface KSAdSplashViewController : UIViewController
- (void)loadAd;
- (void)showAdInWindow:(UIWindow *)window;
@end

@interface CMSplashManager : NSObject
- (void)loadSplashAd;
- (void)showSplashAdInWindow:(UIWindow *)window;
@end

@interface CMAdManager : NSObject
- (void)requestAd;
- (BOOL)isAdReady;
@end

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)showAdInWindow:(UIWindow *)window { }
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)showAdInWindow:(UIWindow *)window { }
%end

%hook BUSplashAdView
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)showAdInWindow:(UIWindow *)window { }
%end

%hook BaiduMobAdSplash
- (void)loadAndShowInWindow:(UIWindow *)window { }
- (void)showInWindow:(UIWindow *)window { }
%end

%hook KSAdSplashViewController
- (void)loadAd { }
- (void)showAdInWindow:(UIWindow *)window { }
%end

%hook CMSplashManager
- (void)loadSplashAd { }
- (void)showSplashAdInWindow:(UIWindow *)window { }
%end

%hook CMAdManager
- (void)requestAd { }
- (BOOL)isAdReady { return YES; }
%end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        // suppress splash or ad view controller
        if (self.view) {
            self.view.hidden = YES;
        }
        return;
    }
    %orig;
}
%end

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          CMSplashManager=objc_getClass("CMSplashManager"),
          CMAdManager=objc_getClass("CMAdManager"));
}
