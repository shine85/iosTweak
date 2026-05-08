#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

// ---------- Splash ----------
static void hookGDTSplashAd(void) {
    Class cls = NSClassFromString(@"GDTSplashAd");
    if (!cls) return;
    %hook GDTSplashAd
    - (void)loadAd {
        // suppress loading
    }
    - (void)showAdInView:(UIView *)view {
        // suppress showing
    }
    %end
}

static void hookPAGSplashRequest(void) {
    Class cls = NSClassFromString(@"PAGSplashRequest");
    if (!cls) return;
    %hook PAGSplashRequest
    - (void)loadRequest {
        // suppress loading
    }
    - (void)presentInWindow:(UIWindow *)window {
        // suppress presenting
    }
    %end
}

// ---------- Rewarded Video ----------
static void hookRewardedVideoAd(void) {
    Class cls = NSClassFromString(@"RewardedVideoAd");
    if (!cls) return;
    %hook RewardedVideoAd
    - (BOOL)isReady {
        return YES;
    }
    - (void)showAdFromRootViewController:(UIViewController *)vc {
        [self rewardUser];
    }
    %end
}

// ---------- Interstitial ----------
static void hookInterstitialAd(void) {
    Class cls = NSClassFromString(@"InterstitialAd");
    if (!cls) return;
    %hook InterstitialAd
    - (void)showFromViewController:(UIViewController *)vc {
        // skip interstitial
    }
    %end
}

// ---------- Prevent splash view from being added ----------
%hook UIView
- (void)addSubview:(UIView *)view {
    if (view) {
        NSString *clsName = NSStringFromClass([view class]);
        if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
            return;
        }
    }
    %orig;
}
%end

%hook UIWindow
- (void)addSubview:(UIView *)view {
    if (view) {
        NSString *clsName = NSStringFromClass([view class]);
        if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
            return;
        }
    }
    %orig;
}
%end

%ctor {
    hookGDTSplashAd();
    hookPAGSplashRequest();
    hookRewardedVideoAd();
    hookInterstitialAd();

    NSLog(@"[AdBlock] Hooks installed for bundle id id583700738");
}
