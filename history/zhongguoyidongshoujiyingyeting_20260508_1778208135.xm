#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

// ---------- Splash ----------
@interface GDTSplashAd : NSObject
- (void)loadAd;
- (void)showAdInView:(UIView *)view;
@end

@interface PAGSplashRequest : NSObject
- (void)loadRequest;
- (void)presentInWindow:(UIWindow *)window;
@end

%hook GDTSplashAd
- (void)loadAd {
    // suppress loading
}
- (void)showAdInView:(UIView *)view {
    // do nothing
}
%end

%hook PAGSplashRequest
- (void)loadRequest {
    // suppress loading
}
- (void)presentInWindow:(UIWindow *)window {
    // do nothing
}
%end

// ---------- Rewarded Video ----------
@interface RewardedVideoAd : NSObject
- (BOOL)isReady;
- (void)showAdFromRootViewController:(UIViewController *)vc;
- (void)rewardUser;
@end

%hook RewardedVideoAd
- (BOOL)isReady {
    return YES;
}
- (void)showAdFromRootViewController:(UIViewController *)vc {
    [self rewardUser];
}
%end

// ---------- Interstitial ----------
@interface InterstitialAd : NSObject
- (void)showFromViewController:(UIViewController *)vc;
@end

%hook InterstitialAd
- (void)showFromViewController:(UIViewController *)vc {
    // skip interstitial
}
%end

// ---------- Generic "showAd" pattern ----------
%hook NSObject
- (void)showAd {
    // generic blocker
}
- (void)presentAd {
    // generic blocker
}
%end

// ---------- Prevent splash view from being added ----------
%hook UIView
- (void)addSubview:(UIView *)view {
    NSString *clsName = NSStringFromClass([view class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        return;
    }
    %orig;
}
%end

%hook UIWindow
- (void)addSubview:(UIView *)view {
    NSString *clsName = NSStringFromClass([view class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        return;
    }
    %orig;
}
%end

%ctor {
    NSLog(@"[AdBlock] Hooks installed for id583700738");
}
