// Tweak.xm
// 目标：河马剧场去广告
// 说明：使用 MSHookMessageEx 进行低调 Hook，避免被常规检测发现

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>

// ----------- 前向声明(必要时补全) -----------
@interface BUAdSDKManager : NSObject
+ (instancetype)sharedInstance;
- (void)startWithAppID:(NSString *)appID;
@end

@interface GDTSDKConfig : NSObject
+ (instancetype)sharedInstance;
- (void)loadConfig;
@end

@interface BaiduMobAdSetting : NSObject
+ (instancetype)sharedInstance;
- (void)setupAd;
@end

@interface PAGInterstitialAd : NSObject
- (void)loadAd;
- (void)showFromRootViewController:(UIViewController *)vc;
@end

@interface PAGRewardedAd : NSObject
- (void)loadAd;
- (void)presentFromRootViewController:(UIViewController *)vc;
@end

// ----------- Hook 工具函数 -----------
static void hookClassMethod(Class cls, SEL sel, IMP newImp, IMP *oldImp) {
    Method m = class_getClassMethod(cls, sel);
    if (!m) return;
    *oldImp = method_getImplementation(m);
    method_setImplementation(m, newImp);
}

static void hookInstanceMethod(Class cls, SEL sel, IMP newImp, IMP *oldImp) {
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return;
    *oldImp = method_getImplementation(m);
    method_setImplementation(m, newImp);
}

// ----------- 广告 SDK 单例拦截 -----------
static id (*orig_BUAdSDKManager_sharedInstance)(id, SEL);
static id new_BUAdSDKManager_sharedInstance(id self, SEL _cmd) {
    // 直接返回 nil，阻止后续初始化
    return nil;
}

static id (*orig_GDTSDKConfig_sharedInstance)(id, SEL);
static id new_GDTSDKConfig_sharedInstance(id self, SEL _cmd) {
    return nil;
}

static id (*orig_BaiduMobAdSetting_sharedInstance)(id, SEL);
static id new_BaiduMobAdSetting_sharedInstance(id self, SEL _cmd) {
    return nil;
}

// ----------- UIView 广告视图隐藏 -----------
static void (*orig_UIView_layoutSubviews)(id, SEL);
static void new_UIView_layoutSubviews(id self, SEL _cmd) {
    // 调用原实现
    orig_UIView_layoutSubviews(self, _cmd);
    // 简单判断类名中是否包含 “Ad” 关键字
    NSString *clsName = NSStringFromClass([(id)self class]);
    if ([clsName containsString:@"Ad"] || [clsName containsString:@"ad"]) {
        [(UIView *)self setHidden:YES];
    }
}

static void (*orig_UIView_didMoveToWindow)(id, SEL);
static void new_UIView_didMoveToWindow(id self, SEL _cmd) {
    orig_UIView_didMoveToWindow(self, _cmd);
    NSString *clsName = NSStringFromClass([(id)self class]);
    if ([clsName containsString:@"Ad"] || [clsName containsString:@"ad"]) {
        [(UIView *)self removeFromSuperview];
    }
}

// ----------- NSURLSession 网络请求拦截 -----------
static id (*orig_NSURLSession_dataTaskWithRequest_completionHandler)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
static id new_NSURLSession_dataTaskWithRequest_completionHandler(id self, SEL _cmd, NSURLRequest *request, void (^handler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlStr = request.URL.absoluteString;
    // 检测常见广告域名关键字
    if ([urlStr containsString:@"ads.pangle.io"] ||
        [urlStr containsString:@"gdt.qq.com"] ||
        [urlStr containsString:@"ads.baidu.com"]) {
        // 直接返回一个空的 dataTask，阻止请求
        return nil;
    }
    // 其余请求走原实现
    return orig_NSURLSession_dataTaskWithRequest_completionHandler(self, _cmd, request, handler);
}

// ----------- 激励视频奖励强制成功 -----------
static void (*orig_PAGRewardedAd_rewardedVideoAdDidRewardUser)(id, SEL, id);
static void new_PAGRewardedAd_rewardedVideoAdDidRewardUser(id self, SEL _cmd, id info) {
    // 直接调用原实现(如果有)，确保奖励回调被触发
    if ([(id)self respondsToSelector:@selector(rewardUser)]) {
        [(id)self performSelector:@selector(rewardUser)];
    }
    // 如无实现，直接返回
}

// ----------- Constructor：在最早阶段安装 Hook -----------
static __attribute__((constructor)) void installHooks() {
    // ---- 广告 SDK 单例 ----
    Class buCls = objc_getClass("BUAdSDKManager");
    if (buCls) {
        hookClassMethod(buCls, @selector(sharedInstance), (IMP)new_BUAdSDKManager_sharedInstance, (IMP *)&orig_BUAdSDKManager_sharedInstance);
    }

    Class gdtCls = objc_getClass("GDTSDKConfig");
    if (gdtCls) {
        hookClassMethod(gdtCls, @selector(sharedInstance), (IMP)new_GDTSDKConfig_sharedInstance, (IMP *)&orig_GDTSDKConfig_sharedInstance);
    }

    Class baiduCls = objc_getClass("BaiduMobAdSetting");
    if (baiduCls) {
        hookClassMethod(baiduCls, @selector(sharedInstance), (IMP)new_BaiduMobAdSetting_sharedInstance, (IMP *)&orig_BaiduMobAdSetting_sharedInstance);
    }

    // ---- UIView 广告视图隐藏 ----
    hookInstanceMethod([UIView class], @selector(layoutSubviews), (IMP)new_UIView_layoutSubviews, (IMP *)&orig_UIView_layoutSubviews);
    hookInstanceMethod([UIView class], @selector(didMoveToWindow), (IMP)new_UIView_didMoveToWindow, (IMP *)&orig_UIView_didMoveToWindow);

    // ---- NSURLSession 网络请求拦截 ----
    Class sessionCls = objc_getClass("NSURLSession");
    if (sessionCls) {
        hookInstanceMethod(sessionCls, @selector(dataTaskWithRequest:completionHandler:), (IMP)new_NSURLSession_dataTaskWithRequest_completionHandler, (IMP *)&orig_NSURLSession_dataTaskWithRequest_completionHandler);
    }

    // ---- 激励视频奖励 Hook ----
    Class rewardCls = objc_getClass("PAGRewardedAd");
    if (rewardCls) {
        hookInstanceMethod(rewardCls, @selector(rewardedVideoAdDidRewardUser:), (IMP)new_PAGRewardedAd_rewardedVideoAdDidRewardUser, (IMP *)&orig_PAGRewardedAd_rewardedVideoAdDidRewardUser);
    }
}
