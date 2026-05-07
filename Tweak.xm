// Tweak.xm
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// ---------- 广告 SDK 单例声明 ----------
@interface BUAdSDKManager : NSObject
+ (instancetype)sharedInstance;
@end

@interface GDTSDKConfig : NSObject
+ (instancetype)sharedInstance;
@end

@interface BaiduMobAdSetting : NSObject
+ (instancetype)sharedInstance;
@end

// ---------- 可能出现的请求类 ----------
@interface PAGInterstitialRequest : NSObject
- (void)loadRequest;
@end

@interface PAGRewardedRequest : NSObject
- (void)loadRequest;
@end

// ---------- 激励视频回调 ----------
@interface RewardedVideoAdDelegate : NSObject
- (void)rewardedVideoAdDidRewardUser:(id)ad;
@end

// ---------- Hook BUAdSDKManager.sharedInstance ----------
static id (*orig_BUAdSDKManager_sharedInstance)(Class cls);
static id hook_BUAdSDKManager_sharedInstance(Class cls) {
    // 阻止实例化，返回 nil
    return nil;
}

// ---------- Hook GDTSDKConfig.sharedInstance ----------
static id (*orig_GDTSDKConfig_sharedInstance)(Class cls);
static id hook_GDTSDKConfig_sharedInstance(Class cls) {
    return nil;
}

// ---------- Hook BaiduMobAdSetting.sharedInstance ----------
static id (*orig_BaiduMobAdSetting_sharedInstance)(Class cls);
static id hook_BaiduMobAdSetting_sharedInstance(Class cls) {
    return nil;
}

// ---------- Hook 激励视频奖励回调 ----------
static void (*orig_rewardedVideoAdDidRewardUser)(id self, SEL _cmd, id ad);
static void hook_rewardedVideoAdDidRewardUser(id self, SEL _cmd, id ad) {
    // 强制调用奖励方法，确保用户领取奖励
    if ([(id)self respondsToSelector:@selector(userDidEarnReward)]) {
        [(id)self performSelector:@selector(userDidEarnReward)];
    }
}

// ---------- 隐藏可能的广告视图 ----------
%hook UIView
- (void)layoutSubviews {
    %orig;
    // 根据 tag 或 accessibilityIdentifier 判断是否为广告视图
    if (self.tag == 9999 ||
        (self.accessibilityIdentifier && [self.accessibilityIdentifier containsString:@"ad"])) {
        self.hidden = YES;
    }
}
%end

// ---------- 拦截 UIWindow 中可能的开屏广告 ----------
%hook UIWindow
- (void)addSubview:(UIView *)view {
    NSString *className = NSStringFromClass([view class]);
    // 检测类名关键字或特定 tag，判断为开屏广告
    if ([className containsString:@"Splash"] ||
        [className containsString:@"Launch"] ||
        view.tag == 8888) {
        view.hidden = YES;
        return;
    }
    %orig;
}
%end

// ---------- 拦截 UIViewController 中可能的开屏广告 ----------
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] ||
        [className containsString:@"Launch"]) {
        self.view.hidden = YES;
    }
}
%end

// ---------- 拦截 NSURLSession 广告请求 ----------
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                           completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlStr = request.URL.absoluteString.lowercaseString;
    if ([urlStr containsString:@"ads.pangle.io"] ||
        [urlStr containsString:@"gdt.qq.com"] ||
        [urlStr containsString:@"baidu.com/ads"] ||
        [urlStr containsString:@"splash"] ) {
        // 返回空响应，阻止广告数据下载
        NSData *empty = [NSData data];
        NSURLResponse *resp = [[NSURLResponse alloc] initWithURL:request.URL
                                                       MIMEType:@"application/json"
                                          expectedContentLength:0
                                               textEncodingName:nil];
        completionHandler(empty, resp, nil);
        return nil;
    }
    return %orig;
}
%end

// ---------- 使用 MSHookMessageEx 防止检测 ----------
static void __attribute__((constructor)) installHooks() {
    Class cls;

    // BUAdSDKManager.sharedInstance
    cls = objc_getClass("BUAdSDKManager");
    if (cls) {
        MSHookMessageEx(cls,
                        @selector(sharedInstance),
                        (IMP)hook_BUAdSDKManager_sharedInstance,
                        (IMP *)&orig_BUAdSDKManager_sharedInstance);
    }

    // GDTSDKConfig.sharedInstance
    cls = objc_getClass("GDTSDKConfig");
    if (cls) {
        MSHookMessageEx(cls,
                        @selector(sharedInstance),
                        (IMP)hook_GDTSDKConfig_sharedInstance,
                        (IMP *)&orig_GDTSDKConfig_sharedInstance);
    }

    // BaiduMobAdSetting.sharedInstance
    cls = objc_getClass("BaiduMobAdSetting");
    if (cls) {
        MSHookMessageEx(cls,
                        @selector(sharedInstance),
                        (IMP)hook_BaiduMobAdSetting_sharedInstance,
                        (IMP *)&orig_BaiduMobAdSetting_sharedInstance);
    }

    // RewardedVideoAdDelegate 回调
    cls = objc_getClass("RewardedVideoAdDelegate");
    if (cls) {
        MSHookMessageEx(cls,
                        @selector(rewardedVideoAdDidRewardUser:),
                        (IMP)hook_rewardedVideoAdDidRewardUser,
                        (IMP *)&orig_rewardedVideoAdDidRewardUser);
    }
}
