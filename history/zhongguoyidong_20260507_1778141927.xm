// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
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

// ---------- 奖励视频回调 ----------
@interface RewardedVideoAdDelegate : NSObject
- (void)rewardedVideoAdDidRewardUser:(id)ad;
@end

// ---------- 原函数指针 ----------
static id (*orig_BUAdSDKManager_sharedInstance)(Class cls);
static id (*orig_GDTSDKConfig_sharedInstance)(Class cls);
static id (*orig_BaiduMobAdSetting_sharedInstance)(Class cls);
static void (*orig_rewardedVideoAdDidRewardUser)(id self, SEL _cmd, id ad);

// ---------- Hook SDK 单例 ----------
static id hook_BUAdSDKManager_sharedInstance(Class cls) {
    // 阻止实例化，返回 nil
    return nil;
}

static id hook_GDTSDKConfig_sharedInstance(Class cls) {
    return nil;
}

static id hook_BaiduMobAdSetting_sharedInstance(Class cls) {
    return nil;
}

// ---------- Hook 奖励视频回调 ----------
static void hook_rewardedVideoAdDidRewardUser(id self, SEL _cmd, id ad) {
    // 调用原实现(若需要保持业务流程)
    if (orig_rewardedVideoAdDidRewardUser) {
        orig_rewardedVideoAdDidRewardUser(self, _cmd, ad);
    }
    // 强制触发奖励回调
    if ([self respondsToSelector:@selector(userDidEarnReward)]) {
        ((void(*)(id, SEL))objc_msgSend)(self, @selector(userDidEarnReward));
    }
}

// ---------- 隐藏常规广告视图 ----------
%hook UIView
- (void)layoutSubviews {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    if (self.tag == 9999 ||
        (self.accessibilityIdentifier && [self.accessibilityIdentifier containsString:@"ad"])) {
        self.hidden = YES;
    }
    if ([clsName containsString:@"Ad"] || [clsName containsString:@"Banner"] ||
        [clsName containsString:@"Interstitial"]) {
        self.hidden = YES;
        if (self.window) {
            [self removeFromSuperview];
        }
    }
}
%end

// ---------- 拦截 UIWindow 中的开屏广告 ----------
%hook UIWindow
- (void)addSubview:(UIView *)view {
    NSString *clsName = NSStringFromClass([view class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Launch"] || view.tag == 8888) {
        view.hidden = YES;
        return; // 直接拦截，不加入视图层级
    }
    %orig;
}
%end

// ---------- 拦截 UIViewController 中的开屏广告 ----------
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Launch"]) {
        self.view.hidden = YES;
    }
}
%end

// ---------- 拦截 NSURLSession 广告请求 ----------
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                           completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *urlStr = request.URL.absoluteString.lowercaseString;
    if ([urlStr containsString:@"ads.pangle.io"] ||
        [urlStr containsString:@"gdt.qq.com"] ||
        [urlStr containsString:@"baidu.com/ads"] ||
        [urlStr containsString:@"splash"]) {
        // 返回空响应，阻止广告下载
        NSData *empty = [NSData data];
        NSURLResponse *resp = [[NSURLResponse alloc] initWithURL:request.URL
                                                        MIMEType:@"application/json"
                                           expectedContentLength:0
                                                textEncodingName:nil];
        if (completionHandler) {
            completionHandler(empty, resp, nil);
        }
        return nil;
    }
    return %orig;
}
%end

// ---------- 构造函数：安装所有 Hook ----------
static __attribute__((constructor)) void installHooks() {
    Class cls;

    // BUAdSDKManager.sharedInstance
    cls = objc_getClass("BUAdSDKManager");
    if (cls) {
        MSHookMessageEx(cls, @selector(sharedInstance),
                        (IMP)hook_BUAdSDKManager_sharedInstance,
                        (IMP *)&orig_BUAdSDKManager_sharedInstance);
    }

    // GDTSDKConfig.sharedInstance
    cls = objc_getClass("GDTSDKConfig");
    if (cls) {
        MSHookMessageEx(cls, @selector(sharedInstance),
                        (IMP)hook_GDTSDKConfig_sharedInstance,
                        (IMP *)&orig_GDTSDKConfig_sharedInstance);
    }

    // BaiduMobAdSetting.sharedInstance
    cls = objc_getClass("BaiduMobAdSetting");
    if (cls) {
        MSHookMessageEx(cls, @selector(sharedInstance),
                        (IMP)hook_BaiduMobAdSetting_sharedInstance,
                        (IMP *)&orig_BaiduMobAdSetting_sharedInstance);
    }

    // RewardedVideoAdDelegate 回调
    cls = objc_getClass("RewardedVideoAdDelegate");
    if (cls) {
        MSHookMessageEx(cls, @selector(rewardedVideoAdDidRewardUser:),
                        (IMP)hook_rewardedVideoAdDidRewardUser,
                        (IMP *)&orig_rewardedVideoAdDidRewardUser);
    }
}
