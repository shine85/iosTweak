#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/message.h>

@class GDTSplashAd;
@class CSJSplashAd;
@class BUSplashAdView;
@class BaiduMobAdSplash;
@class KSAdSplashViewController;
@class CMSplashManager;
@class CMAdManager;
@class PAGSplashViewController;
@class BUAdSplashView;
@class CSJSplashAdViewController;

// GDTSplashAd
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    // suppress splash
}
- (void)showAdInWindow:(UIWindow *)window {
    // suppress splash
}
%end

// CSJSplashAd
%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    // suppress splash
}
%end

// BUSplashAdView
%hook BUSplashAdView
- (void)loadAd {
    // suppress splash
}
%end

// BaiduMobAdSplash
%hook BaiduMobAdSplash
- (void)loadAndShowInWindow:(UIWindow *)window {
    // suppress splash
}
%end

// KSAdSplashViewController
%hook KSAdSplashViewController
- (void)loadAndShowInWindow:(UIWindow *)window {
    // suppress splash
}
%end

// PAGSplashViewController (by ByteDance)
%hook PAGSplashViewController
- (void)loadAd {
    // suppress splash
}
- (void)showAdInWindow:(UIWindow *)window {
    // suppress splash
}
%end

// BUAdSplashView (by Bytedance)
%hook BUAdSplashView
- (void)loadAdData {
    // suppress splash
}
%end

// CSJSplashAdViewController (alternative naming)
%hook CSJSplashAdViewController
- (void)loadAndShowInWindow:(UIWindow *)window {
    // suppress splash
}
%end

// App‑specific splash managers
%hook CMSplashManager
- (void)requestSplashAd {
    // suppress request
}
%end

%hook CMAdManager
- (void)fetchAndDisplaySplash {
    // suppress request
}
%end

// Generic UIViewController handling
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
        self.view.hidden = YES;
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }
        return;
    }
    %orig;
}
%end

// Generic UIView handling (in case ad uses custom view)
%hook UIView
- (void)didMoveToWindow {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// Countdown timer neutralizer (common pattern)
%hook NSObject
- (void)startCountdown {
    if ([self respondsToSelector:NSSelectorFromString(@"setRemainingTime:")]) {
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(self, NSSelectorFromString(@"setRemainingTime:"), 0);
    }
    %orig;
}
%end

%ctor {
    %init(GDTSplashAd, CSJSplashAd, BUSplashAdView,
          BaiduMobAdSplash, KSAdSplashViewController,
          PAGSplashViewController, BUAdSplashView, CSJSplashAdViewController,
          CMSplashManager, CMAdManager,
          UIViewController, UIView, NSObject);
}
