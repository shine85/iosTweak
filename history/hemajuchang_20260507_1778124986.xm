#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Constructor for early injection
static __attribute__((constructor)) void initializeTweak() {
    NSLog(@"[河马剧场去广告] Tweak loaded early via constructor.");
}

// Prevent ad SDK initialization
%hook PangleSDK // Common class for Pangle, adjust if needed
+ (instancetype)sharedInstance {
    NSLog(@"[河马剧场去广告] Blocked Pangle sharedInstance");
    return nil;
}

- (void)startWithAppId:(NSString *)appId {
    NSLog(@"[河马剧场去广告] Blocked Pangle startWithAppId: %@", appId);
    // Do nothing
}
%end

// GDT / Tencent ads common hooks
%hook GDTSDKConfig
+ (void)registerAppId:(NSString *)appId {
    NSLog(@"[河马剧场去广告] Blocked GDT registerAppId");
}
%end

%hook BUAdSDKManager // ByteDance / Pangle related
+ (void)setupSDKWithAppId:(NSString *)appId {
    NSLog(@"[河马剧场去广告] Blocked BUAdSDKManager setup");
}
%end

// Baidu ads
%hook BaiduMobAdSetting
+ (instancetype)sharedInstance {
    return nil;
}
%end

// Intercept ad presentation
%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    NSString *className = NSStringFromClass([viewControllerToPresent class]);
    if ([className containsString:@"Ad"] || [className containsString:@"Reward"] || [className containsString:@"Pangle"] || [className containsString:@"GDT"]) {
        NSLog(@"[河马剧场去广告] Blocked ad view controller: %@", className);
        if (completion) completion();
        return;
    }
    %orig;
}
%end

// Reward video auto success
%hook NSObject
- (void)rewardedVideoAdDidRewardUser:(id)ad withReward:(id)reward {
    NSLog(@"[河马剧场去广告] Forced reward success for %@", NSStringFromClass([self class]));
    // Call original if needed or fake success
    %orig;
}

// Common reward callback patterns
- (void)rewardedVideoAdDidRewardUserWithReward:(NSDictionary *)reward {
    NSLog(@"[河马剧场去广告] Forced reward success (dict)");
    %orig;
}
%end

// Hide ad views by layout
%hook UIView
- (void)layoutSubviews {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || [className containsString:@"Banner"] || [className containsString:@"Native"] || [className containsString:@"Splash"]) {
        NSLog(@"[河马剧场去广告] Hid ad view: %@", className);
        self.hidden = YES;
        [self removeFromSuperview];
    }
}

- (void)didMoveToWindow {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || [className containsString:@"Banner"]) {
        self.hidden = YES;
        [self removeFromSuperview];
    }
}
%end

// Network interception for ad domains
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlString = request.URL.absoluteString;
    if ([urlString containsString:@"ads.pangle.io"] || [urlString containsString:@"gdt.qq.com"] || [urlString containsString:@"baidu.com/ad"] || [urlString containsString:@"mobad"] ) {
        NSLog(@"[河马剧场去广告] Blocked ad network request: %@", urlString);
        if (completionHandler) {
            completionHandler(nil, nil, [NSError errorWithDomain:@"AdBlock" code:999 userInfo:nil]);
        }
        return nil;
    }
    return %orig;
}
%end

// Additional safety for singletons
%hook NSClassFromString(@"PAGRewardedAd") // Pangle rewarded
+ (instancetype)sharedInstance {
    return nil;
}
%end
