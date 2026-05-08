#import <UIKit/UIKit.h>
#import <substrate.h>

// ---------- GDT SDK ----------
@interface GDTSplashAd : NSObject
- (void)loadAndShowInWindow:(UIWindow *)window;
@end
@interface GDTRewardVideoAd : NSObject
- (BOOL)isAdValid;
- (void)showAdFromRootViewController:(UIViewController *)rootVC;
@property (nonatomic, copy) void (^rewardedVideoAdDidRewardUser)(GDTRewardVideoAd *, NSInteger);
@end

// ---------- Pangle SDK ----------
@interface BURewardedVideoAd : NSObject
- (BOOL)hasAdReady;
- (void)showAdFromRootViewController:(UIViewController *)rootVC;
@property (nonatomic, copy) void (^rewardedVideoAdDidReward)(BURewardedVideoAd *, NSDictionary *);
@end
@interface PAGSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
@end
@interface BUAdSplashView : NSObject
- (void)showInWindow:(UIWindow *)window;
@end

// ---------- Splash Hook ----------
%hook GDTSplashAd
- (void)loadAndShowInWindow:(UIWindow *)window {
    // Prevent GDT splash ad
}
%end

%hook PAGSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    // Prevent Pangle splash ad
}
%end

%hook BUAdSplashView
- (void)showInWindow:(UIWindow *)window {
    // Prevent BU splash ad
}
%end

// ---------- Rewarded Video Hook ----------
%hook GDTRewardVideoAd
- (BOOL)isAdValid {
    return YES;
}
- (void)showAdFromRootViewController:(UIViewController *)rootVC {
    if (self.rewardedVideoAdDidRewardUser) {
        self.rewardedVideoAdDidRewardUser(self, 100);
    }
}
%end

%hook BURewardedVideoAd
- (BOOL)hasAdReady {
    return YES;
}
- (void)showAdFromRootViewController:(UIViewController *)rootVC {
    if (self.rewardedVideoAdDidReward) {
        NSDictionary *info = @{@"rewardAmount": @100, @"rewardName": @"coins"};
        self.rewardedVideoAdDidReward(self, info);
    }
}
%end

// ---------- Early Execution ----------
%ctor {
    // Ensure all hooks are applied as early as possible
}
