// Tweak.xm
// 中国移动去广告插件 - 基于Logos语法
// 拦截Pangle/GDT/Baidu广告SDK及网络请求

#include <substrate.h>
#include <dlfcn.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ========================= Constructor: 最早注入 =========================
static __attribute__((constructor)) void _early_init() {
    // 在dyld加载后立即执行，早于+load
    NSLog(@"[AntiAd] Tweak loaded at constructor stage.");
}

// ========================= 1. 广告SDK单例拦截 =========================
// 穿山甲 Pangle
%hook BUAdSDKManager
+ (instancetype)sharedInstance {
    return nil; // 阻止单例创建，使后续配置失效
}
+ (void)startWithAsyncCompletionHandler:(void(^)(BOOL success, NSError *error))handler {
    // 模拟成功但实际不加载任何广告
    if(handler) {
        handler(YES, nil);
    }
}
%end

// 腾讯优量汇 GDT
%hook GDTSDKConfig
+ (instancetype)sharedInstance {
    return nil;
}
+ (void)registerAppId:(NSString *)appId {
    // 空实现，阻止注册
}
%end

// 百度联盟 Baidu
%hook BaiduMobAdSetting
+ (instancetype)sharedSetting {
    return nil;
}
%end

// ========================= 2. 广告视图隐藏 =========================
// 通用广告容器视图 - 通过layoutSubviews监测
%hook UIView
- (void)layoutSubviews {
    %orig;
    // 根据类名或特定特征隐藏广告视图
    NSString *className = NSStringFromClass([self class]);
    NSArray *adKeywords = @[@"Ad", @"Banner", @"Interstitial", @"RewardVideo", @"GDT", @"BUAD", @"BaiduMob"];
    for (NSString *kw in adKeywords) {
        if ([className containsString:kw]) {
            [self setHidden:YES];
            [self removeFromSuperview];
            break;
        }
    }
    // 额外根据accessibilityIdentifier判断
    if ([self.accessibilityIdentifier containsString:@"ad"] ||
        [self.accessibilityIdentifier containsString:@"广告"]) {
        [self setHidden:YES];
        [self removeFromSuperview];
    }
}
%end

// 拦截原生广告渲染视图
%hook GDTNativeAdView
- (void)didMoveToWindow {
    %orig;
    if(self.window) {
        [self setHidden:YES];
        [self removeFromSuperview];
    }
}
%end

%hook BUAdView
- (void)didMoveToWindow {
    %orig;
    if(self.window) {
        [self setHidden:YES];
        [self removeFromSuperview];
    }
}
%end

// ========================= 3. 激励视频强制达成 =========================
%hook GDTUnifiedInterstitialAd
- (void)showAdFromRootViewController:(UIViewController *)rootViewController {
    // 不展示真实广告，直接触发假的激励回调
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(unifiedInterstitialAdWillClose:)]) {
            [self.delegate unifiedInterstitialAdWillClose:self];
        }
        if ([self.delegate respondsToSelector:@selector(unifiedInterstitialAdDidClose:)]) {
            [self.delegate unifiedInterstitialAdDidClose:self];
        }
    });
}
%end

// 穿山甲激励视频
%hook BUNativeExpressRewardedVideoAd
- (void)showAdFromRootViewController:(UIViewController *)rootController {
    // 模拟奖励发放
    if ([self.delegate respondsToSelector:@selector(rewardedVideoAdDidRewardUser:)]) {
        [self.delegate rewardedVideoAdDidRewardUser:self];
    }
}
%end

// 百度激励视频
%hook BaiduMobAdRewardVideo
- (void)show {
    if ([self.delegate respondsToSelector:@selector(rewardedVideoAdDidRewardSuccess:)]) {
        [self.delegate rewardedVideoAdDidRewardSuccess:self];
    }
}
%end

// ========================= 4. 网络请求拦截（广告API） =========================
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURL *newUrl = url;
    NSArray *adHosts = @[@"ads.pangle.io", @"sgmobads", @"e.qq.com", @"gdt.qq.com", @"cpro.baidu.com", @"hm.baidu.com", @"ad.miguvideo.com"];
    for (NSString *host in adHosts) {
        if([[url absoluteString] containsString:host]) {
            // 返回空数据模拟成功但无广告
            NSData *emptyData = [NSData data];
            if(completionHandler) {
                completionHandler(emptyData, nil, nil);
            }
            return nil;
        }
    }
    return %orig;
}
%end

// 拦截AFNetworking（如果应用使用）
%hook AFHTTPSessionManager
- (NSURLSessionDataTask *)GET:(NSString *)URLString parameters:(id)parameters headers:(NSDictionary *)headers progress:(void (^)(NSProgress *))downloadProgress success:(void (^)(NSURLSessionDataTask *, id))success failure:(void (^)(NSURLSessionDataTask *, NSError *))failure {
    NSArray *adPaths = @[@"/ad/", @"/sdkad", @"/reward_video", @"/banner"];
    for (NSString *path in adPaths) {
        if([URLString containsString:path]) {
            if(success) {
                success(nil, @{});
            }
            return nil;
        }
    }
    return %orig;
}
%end

// ========================= 5. 防止检测Hook (示例使用MSHookMessageEx) =========================
// 为了对抗部分SDK的越狱检测，将常用的_os_log或NSLog替换空操作（可选）
#include <objc/runtime.h>
static void (*orig_NSLog)(NSString *format, ...);
static void override_NSLog(NSString *format, ...) {
    // 过滤包含"hook"、"tweak"、"substrate"的日志
    if([format containsString:@"hook"] || [format containsString:@"substrate"]) {
        return;
    }
    va_list args;
    va_start(args, format);
    orig_NSLog(format, args);
    va_end(args);
}

%ctor {
    // 替换NSLog
    MSHookFunction((void *)&NSLog, (void *)&override_NSLog, (void **)&orig_NSLog);
    // 更隐蔽的类方法hook示例（若需要hook私有类）
    // Class someClass = objc_getClass("可疑检测类");
    // MSHookMessageEx(someClass, @selector(checkJailbreak), (IMP)&fake_check, (IMP *)&orig_check);
}
