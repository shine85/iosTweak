// Tweak.xm
// 目标：拦截并禁用中国移动 App 中的广告
// 说明：使用 Logos 语法，结合 MSHookMessageEx 实现防检测 Hook

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <Foundation/NSURLSession.h>

// ---------- 需要声明的外部类和方法 ----------
@interface BUAdSDKManager : NSObject
+ (instancetype)sharedInstance;
- (void)startWithAppID:(NSString *)appID;
@end

@interface GDTSDKConfig : NSObject
+ (instancetype)sharedInstance;
- (void)setAppId:(NSString *)appId;
@end

@interface BaiduMobAdSetting : NSObject
+ (instancetype)sharedInstance;
- (void)setAppId:(NSString *)appId;
@end

@interface PAGSplashRequest : NSObject
- (void)load;
@end

@interface PAGRewardedAd : NSObject
- (void)rewardedVideoAdDidRewardUser:(id)ad;
@end

// ---------- 防检测 Hook：拦截 BUAdSDKManager sharedInstance ----------
static id (*orig_BU_sharedInstance)(Class, SEL);
static id new_BU_sharedInstance(Class cls, SEL sel) {
    // 直接返回 nil，阻止 SDK 初始化
    return nil;
}

// ---------- Constructor：在进程启动最早期执行 ----------
%ctor {
    // Hook BUAdSDKManager.sharedInstance
    Class buClass = objc_getClass("BUAdSDKManager");
    if (buClass) {
        MSHookMessageEx(buClass,
                       @selector(sharedInstance),
                       (IMP)new_BU_sharedInstance,
                       (IMP *)&orig_BU_sharedInstance);
    }

    // 可在此处添加其他提前生效的标记位或日志
}

// ---------- Hook GDTSDKConfig sharedInstance ----------
%hook GDTSDKConfig
+ (instancetype)sharedInstance {
    // 返回 nil，阻断优量汇 SDK 初始化
    return nil;
}
%end

// ---------- Hook BaiduMobAdSetting sharedInstance ----------
%hook BaiduMobAdSetting
+ (instancetype)sharedInstance {
    // 返回 nil，阻断百度广告 SDK 初始化
    return nil;
}
%end

// ---------- Hook 开屏广告加载 ----------
%hook PAGSplashRequest
- (void)load {
    // 直接忽略加载请求，避免 UI 卡顿
    // 若需模拟失败回调，请自行触发对应 delegate
}
%end

// ---------- Hook 奖励视频广告回调 ----------
%hook PAGRewardedAd
- (void)rewardedVideoAdDidRewardUser:(id)ad {
    // 强制触发奖励回调，确保用户获得奖励
    %orig;
}
%end

// ---------- Hook NSURLSession 广告请求 ----------
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data,
                                                        NSURLResponse *response,
                                                        NSError *error))completionHandler {
    NSString *url = request.URL.absoluteString;
    if ([url containsString:@"ads.pangle.io"] ||
        [url containsString:@"gdt.qq.com"] ||
        [url containsString:@"baidu.com"]) {
        // 拦截广告请求，返回错误模拟加载失败
        if (completionHandler) {
            NSError *err = [NSError errorWithDomain:NSURLErrorDomain
                                               code:-1009
                                           userInfo:nil];
            completionHandler(nil, nil, err);
        }
        return nil;
    }
    return %orig;
}
%end

// ---------- Hook UIView 及子类，隐藏可能的广告视图 ----------
%hook UIView
- (void)layoutSubviews {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Ad"] ||
        [clsName containsString:@"Banner"] ||
        [clsName containsString:@"Splash"]) {
        self.hidden = YES;
        self.frame = CGRectZero;
    }
}
%end
