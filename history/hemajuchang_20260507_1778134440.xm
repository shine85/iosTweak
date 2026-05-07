#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

// Pangle SDK 相关类声明
@interface PAGConfig : NSObject
+ (instancetype)shareConfig;
@end

@interface PAGRewardedAd : NSObject
+ (void)loadAdWithSlotID:(NSString *)slotID request:(id)request completionHandler:(void(^)(PAGRewardedAd * _Nullable rewardedAd, NSError * _Nullable error))completionHandler;
- (void)presentFromRootViewController:(UIViewController *)viewController;
@end

@interface PAGRewardedRequest : NSObject
@end

// GDT SDK
@interface GDTSDKConfig : NSObject
+ (void)initWithAppId:(NSString *)appId;
@end

// Baidu SDK
@interface BaiduMobAdSetting : NSObject
+ (BaiduMobAdSetting *)getInstance;
@end

// 通用广告视图拦截
%hook UIView

- (void)didMoveToWindow {
    %orig;
    if ([self isKindOfClass:[NSClassFromString(@"PAGBannerAdView") class]] ||
        [self isKindOfClass:[NSClassFromString(@"GDTNativeExpressAdView") class]] ||
        [self isKindOfClass:[NSClassFromString(@"BaiduMobAdNativeView") class]] ||
        [NSStringFromClass([self class]) containsString:@"Ad"] ||
        [NSStringFromClass([self class]) containsString:@"Banner"]) {
        [self setHidden:YES];
        [self removeFromSuperview];
        NSLog(@"[HMJD AdBlock] 隐藏广告视图: %@", NSStringFromClass([self class]));
    }
}

- (void)layoutSubviews {
    %orig;
    if ([self isKindOfClass:[NSClassFromString(@"PAGBannerAdView") class]] ||
        [self.superview isKindOfClass:[NSClassFromString(@"PAGBannerAdView") class]]) {
        [self setHidden:YES];
    }
}

%end

// Pangle 初始化拦截
%hook PAGConfig

+ (instancetype)shareConfig {
    NSLog(@"[HMJD AdBlock] 拦截 PAGConfig shareConfig");
    return nil;
}

%end

// Pangle 激励视频 Hook - 强制奖励成功
%hook PAGRewardedAd

- (void)presentFromRootViewController:(UIViewController *)viewController {
    NSLog(@"[HMJD AdBlock] 拦截 PAGRewardedAd present");
    // 不展示广告，直接触发奖励
    [self rewardedAdDidRewardUser];
}

- (BOOL)rewardedAdDidRewardUser {
    NSLog(@"[HMJD AdBlock] 强制 PAGRewardedAd 奖励成功");
    return YES;
}

%end

// GDT 初始化拦截
%hook GDTSDKConfig

+ (void)initWithAppId:(NSString *)appId {
    NSLog(@"[HMJD AdBlock] 拦截 GDTSDKConfig initWithAppId: %@", appId);
    // 不调用 orig 阻止初始化
}

%end

// Baidu 初始化拦截
%hook BaiduMobAdSetting

+ (BaiduMobAdSetting *)getInstance {
    NSLog(@"[HMJD AdBlock] 拦截 BaiduMobAdSetting getInstance");
    return nil;
}

%end

// 网络请求拦截广告数据
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *urlString = request.URL.absoluteString;
    if ([urlString containsString:@"ads.pangle.io"] ||
        [urlString containsString:@"gdt"] ||
        [urlString containsString:@"baidu"] ||
        [urlString containsString:@"ad"] ||
        [urlString containsString:@"mob"] ) {
        NSLog(@"[HMJD AdBlock] 拦截广告网络请求: %@", urlString);
        if (completionHandler) {
            completionHandler(nil, nil, [NSError errorWithDomain:@"AdBlock" code:999 userInfo:nil]);
        }
        return nil;
    }
    return %orig;
}

%end

// 单例拦截示例
%hook NSClassFromString(@"BUAdSDKManager")

+ (instancetype)sharedInstance {
    NSLog(@"[HMJD AdBlock] 拦截 BUAdSDKManager sharedInstance");
    return nil;
}

%end

// Constructor 早期介入
__attribute__((constructor)) static void initTweak(void) {
    NSLog(@"[HMJD AdBlock] 河马剧场去广告 Tweak 加载成功 - 早期 Constructor");
    // 可在此处额外 MSHookMessageEx 增强
}
