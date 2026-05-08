#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// ---------- Common SDK Interfaces ----------
@interface PAGSplashAd : NSObject
- (void)loadAd;
- (BOOL)isReady;
- (void)presentFromRootViewController:(UIViewController *)vc;
@end

@interface GDTSplashAd : NSObject
- (void)loadAd;
- (BOOL)isAdValid;
- (void)showAdInWindow:(UIWindow *)window;
@end

@interface RewardedVideoAd : NSObject
- (void)loadAd;
- (BOOL)isReady;
- (void)showAdFromViewController:(UIViewController *)vc;
@property (nonatomic, copy) void (^rewardCallback)(NSInteger reward);
@end

// ---------- App‑specific placeholders ----------
@interface <#AppSpecificClassName#> : NSObject
- (void)showAd;
- (void)presentAd;
- (BOOL)isReady;
@end

// ---------- Hook implementations ----------
%hook PAGSplashAd
- (void)loadAd {
    // Skip loading, directly notify success if needed
    %orig; // optional: call original to keep internal state
}
- (BOOL)isReady {
    // Force ready state
    return YES;
}
- (void)presentFromRootViewController:(UIViewController *)vc {
    // Do nothing – suppress splash ad
}
%end

%hook GDTSplashAd
- (void)loadAd {
    %orig;
}
- (BOOL)isAdValid {
    return YES; // force valid
}
- (void)showAdInWindow:(UIWindow *)window {
    // Suppress display
}
%end

%hook RewardedVideoAd
- (void)loadAd {
    %orig;
    // Immediately invoke reward callback if set
    if (self.rewardCallback) {
        self.rewardCallback(1); // assume reward of 1 unit
    }
}
- (BOOL)isReady {
    return YES;
}
- (void)showAdFromViewController:(UIViewController *)vc {
    // Skip actual video, still call reward if not already triggered
    if (self.rewardCallback) {
        self.rewardCallback(1);
    }
}
%end

// ---------- Generic ad‑display blocker ----------
%hook <#AppSpecificClassName#>
- (void)showAd {
    // Prevent UI from showing any ad
}
- (void)presentAd {
    // Prevent UI from presenting any ad
}
- (BOOL)isReady {
    // Make callers think ad is ready (optional)
    return YES;
}
%end

// ---------- Early injection ----------
%ctor {
    @autoreleasepool {
        // Ensure hooks are installed as early as possible
        dlopen("/System/Library/Frameworks/UIKit.framework/UIKit", RTLD_NOW);
        NSLog(@"[AdBlocker] Hooks installed for cn.10086.app");
    }
}
