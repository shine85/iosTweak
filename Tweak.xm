#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// ==== Interface Declarations ====
// Add interface for any ad related classes you have identified.
// If the exact class name is unknown, replace <#ClassName#> with the real one.

@interface <#AdManagerClass#> : NSObject
- (BOOL)isReady;
- (void)loadAd;
- (void)showAd;
@end

@interface <#RewardedVideoClass#> : NSObject
- (BOOL)isReady;
- (void)loadAd;
- (void)showAd;
@property (nonatomic, copy) void (^rewardCallback)(void);
@end

@interface <#SplashAdClass#> : NSObject
- (void)loadAd;
- (void)showAd;
@end

// ==== Hook Implementations ====

// Force reward video to be ready and automatically grant reward
%hook <#RewardedVideoClass#>

- (BOOL)isReady {
    return YES;
}

- (void)showAd {
    // Call original to trigger any internal logic
    %orig;
    
    // Immediately invoke reward callback if it exists
    if (self.rewardCallback) {
        self.rewardCallback();
    }
}

%end

// Intercept generic ad show calls and suppress them
%hook <#AdManagerClass#>

- (void)showAd {
    // Suppress the ad display
    // Optionally you can log here for debugging
    // NSLog(@"[AdBlock] Suppressed showAd in %@", NSStringFromClass([self class]));
}

%end

// Suppress splash ads
%hook <#SplashAdClass#>

- (void)showAd {
    // Do nothing to prevent splash ad from appearing
}

%end

// Early initialization
%ctor {
    // This block runs as soon as the tweak is loaded
    // You can add additional runtime checks here if needed
}
