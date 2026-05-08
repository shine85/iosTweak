#import <UIKit/UIKit.h>
#import <substrate.h>

// GDT Splash
@interface GDTSplashAd : NSObject
- (void)loadAndShowInWindow:(UIWindow *)window;
@end

// GDT Rewarded Video
@interface GDTRewardVideoAd : NSObject
- (BOOL)isAdValid;
- (void)showAdFromRootViewController:(UIViewController *)rootVC;
@property (nonatomic, copy) void (^rewardedVideoAdDidRewardUser)(GDTRewardVideoAd *, NSInteger);
@end

// Pangle Splash
@interface PAGSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
@end

// BU (Pangle) Splash View
@interface BUAdSplashView : NSObject
- (void)showInWindow:(UIWindow *)window;
@end

%hook GDTSplashAd
- (void)loadAndShowInWindow:(UIWindow *)window {
    // suppress splash ad
}
%end

%hook PAGSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    // suppress splash ad
}
%end

%hook BUAdSplashView
- (void)showInWindow:(UIWindow *)window {
    // suppress splash ad
}
%end

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

@interface BURewardVideoAd : NSObject
- (BOOL)hasAdReady;
- (void)showAdFromRootViewController:(UIViewController *)rootVC;
@property (nonatomic, copy) void (^rewardedVideoAdDidReward)(BURewardVideoAd *, NSDictionary *);
@end

%hook BURewardVideoAd
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

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
        return;
    }
    %orig;
}
%end

%ctor {
    // Hooks are registered automatically by Logos.
}
