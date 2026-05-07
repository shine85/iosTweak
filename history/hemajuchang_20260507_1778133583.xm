#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

%hook BUAdSDKManager
+ (instancetype)sharedInstance {
    NSLog(@"[HMAdBlock] BUAdSDKManager sharedInstance hooked, returning nil");
    return nil;
}

+ (void)setupSDKWithAppId:(NSString *)appId {
    NSLog(@"[HMAdBlock] Blocked BUAdSDKManager setupSDKWithAppId: %@", appId);
}

- (void)startWithAsyncCompletionHandler:(void (^)(BOOL))handler {
    NSLog(@"[HMAdBlock] Blocked BUAdSDKManager start");
    if (handler) handler(YES);
}
%end

%hook GDTSDKConfig
+ (BOOL)registerAppId:(NSString *)appId {
    NSLog(@"[HMAdBlock] Blocked GDTSDKConfig registerAppId: %@", appId);
    return YES;
}
%end

%hook BaiduMobAdSetting
+ (instancetype)sharedInstance {
    NSLog(@"[HMAdBlock] BaiduMobAdSetting sharedInstance hooked");
    return nil;
}
%end

%hook PAGConfig
+ (instancetype)shareConfig {
    NSLog(@"[HMAdBlock] PAGConfig (Pangle) hooked");
    return nil;
}
%end

// 拦截展示类广告
%hook PAGInterstitialAd
+ (void)loadAdWithSlotID:(NSString *)slotID request:(PAGInterstitialRequest *)request completionHandler:(void (^)(PAGInterstitialAd *, NSError *))completionHandler {
    NSLog(@"[HMAdBlock] Blocked PAGInterstitialAd load");
    if (completionHandler) completionHandler(nil, [NSError errorWithDomain:@"HMAdBlock" code:100 userInfo:nil]);
}
%end

%hook PAGRewardedAd
+ (void)loadAdWithSlotID:(NSString *)slotID request:(PAGRewardedRequest *)request completionHandler:(void (^)(PAGRewardedAd *, NSError *))completionHandler {
    NSLog(@"[HMAdBlock] Blocked PAGRewardedAd load");
    if (completionHandler) completionHandler(nil, [NSError errorWithDomain:@"HMAdBlock" code:100 userInfo:nil]);
}
%end

// 奖励视频自动成功
%hook PAGRewardedAd
- (void)showAdFromRootViewController:(UIViewController *)rootViewController {
    NSLog(@"[HMAdBlock] Auto reward success for PAGRewardedAd");
    // 模拟奖励回调
    if ([self respondsToSelector:@selector(rewardedAdDidRewardUserWithReward:)]) {
        // 调用奖励逻辑
    }
}
%end

// 通用视图广告隐藏
%hook UIView
- (void)didMoveToWindow {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || [className containsString:@"Banner"] || [className containsString:@"PAG"] || [className containsString:@"GDT"] || [className containsString:@"Baidu"]) {
        NSLog(@"[HMAdBlock] Hidden ad view: %@", className);
        self.hidden = YES;
        [self removeFromSuperview];
    }
}

- (void)layoutSubviews {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || [className containsString:@"Banner"] || [className containsString:@"Native"]) {
        self.hidden = YES;
    }
}
%end

// 网络拦截示例
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *url = request.URL.absoluteString;
    if ([url containsString:@"ads.pangle.io"] || [url containsString:@"gdt"] || [url containsString:@"baidu"] || [url containsString:@"ad"] ) {
        NSLog(@"[HMAdBlock] Blocked ad network request: %@", url);
        if (completionHandler) {
            completionHandler(nil, nil, [NSError errorWithDomain:@"HMAdBlock" code:403 userInfo:nil]);
        }
        return nil;
    }
    return %orig;
}
%end

// 防止部分检测 (示例)
%hook NSObject
- (BOOL)isKindOfClass:(Class)aClass {
    if ([NSStringFromClass(aClass) containsString:@"HookDetector"]) {
        return NO;
    }
    return %orig;
}
%end

__attribute__((constructor)) static void init(void) {
    NSLog(@"[HMAdBlock] River Horse Theater Ad Removal Tweak loaded early");
}
