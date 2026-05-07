#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// @class 前向声明
@class BUAdSDKManager;
@class GDTSDKConfig;
@class BaiduMobAdSetting;
@class PAGInterstitialRequest;
@class PAGRewardedRequest;
@class RewardedVideoAd;
@class AFHTTPSessionManager;

// 原始函数指针
static id (*orig_sharedInstance_BUAdSDKManager)(Class, SEL);
static id (*orig_sharedInstance_GDTSDKConfig)(Class, SEL);
static id (*orig_sharedInstance_BaiduMobAdSetting)(Class, SEL);

static void (*orig_layoutSubviews)(UIView *self, SEL _cmd);
static void (*orig_didMoveToWindow)(UIView *self, SEL _cmd);

static NSURLSessionDataTask* (*orig_dataTaskWithRequest_completionHandler)(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *));
static NSURLSessionDataTask* (*orig_AFHTTPSessionManager_dataTaskWithRequest_completionHandler)(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *));

// 简单广告视图识别并隐藏
static void hideIfAdView(UIView *view) {
    // 关键字匹配：Ad、Banner、Splash
    NSString *clsName = NSStringFromClass([view class]);
    if ([clsName containsString:@"Ad"] ||
        [clsName containsString:@"Banner"] ||
        [clsName containsString:@"Splash"]) {
        view.hidden = YES;
        [view removeFromSuperview];
    }
}

// ---------- Constructor ----------
__attribute__((constructor)) static void init_tweak() {
    // Hook BUAdSDKManager.sharedInstance
    Class clsBU = objc_getClass("BUAdSDKManager");
    if (clsBU) {
        MSHookMessageEx(clsBU, @selector(sharedInstance), (IMP)&new_sharedInstance_BU, (IMP *)&orig_sharedInstance_BUAdSDKManager);
    }

    // Hook GDTSDKConfig.sharedInstance
    Class clsGDT = objc_getClass("GDTSDKConfig");
    if (clsGDT) {
        MSHookMessageEx(clsGDT, @selector(sharedInstance), (IMP)&new_sharedInstance_GDT, (IMP *)&orig_sharedInstance_GDTSDKConfig);
    }

    // Hook BaiduMobAdSetting.sharedInstance
    Class clsBaidu = objc_getClass("BaiduMobAdSetting");
    if (clsBaidu) {
        MSHookMessageEx(clsBaidu, @selector(sharedInstance), (IMP)&new_sharedInstance_Baidu, (IMP *)&orig_sharedInstance_BaiduMobAdSetting);
    }

    // Hook UIView 布局相关方法
    MSHookMessageEx(objc_getClass("UIView"), @selector(layoutSubviews), (IMP)&new_layoutSubviews, (IMP *)&orig_layoutSubviews);
    MSHookMessageEx(objc_getClass("UIView"), @selector(didMoveToWindow), (IMP)&new_didMoveToWindow, (IMP *)&orig_didMoveToWindow);

    // Hook NSURLSession 网络请求
    Class clsSession = objc_getClass("NSURLSession");
    if (clsSession) {
        MSHookMessageEx(clsSession, @selector(dataTaskWithRequest:completionHandler:), (IMP)&new_dataTaskWithRequest, (IMP *)&orig_dataTaskWithRequest_completionHandler);
    }

    // Hook AFHTTPSessionManager 网络请求(若使用 AFNetworking)
    Class clsAF = objc_getClass("AFHTTPSessionManager");
    if (clsAF) {
        MSHookMessageEx(clsAF, @selector(dataTaskWithRequest:completionHandler:), (IMP)&new_AFHTTPSessionManager_dataTask, (IMP *)&orig_AFHTTPSessionManager_dataTaskWithRequest_completionHandler);
    }
}

// ---------- Hook 实现 ----------
static id new_sharedInstance_BU(Class cls, SEL sel) {
    // 阻止 SDK 初始化，返回 nil
    return nil;
}
static id new_sharedInstance_GDT(Class cls, SEL sel) {
    return nil;
}
static id new_sharedInstance_Baidu(Class cls, SEL sel) {
    return nil;
}
static void new_layoutSubviews(UIView *self, SEL _cmd) {
    orig_layoutSubviews(self, _cmd);
    hideIfAdView(self);
    for (UIView *sub in self.subviews) {
        hideIfAdView(sub);
    }
}
static void new_didMoveToWindow(UIView *self, SEL _cmd) {
    orig_didMoveToWindow(self, _cmd);
    hideIfAdView(self);
}
static NSURLSessionDataTask* new_dataTaskWithRequest(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *url = request.URL.absoluteString;
    if ([url containsString:@"ads.pangle.io"] ||
        [url containsString:@"gdtad"] ||
        [url containsString:@"baidu"]) {
        // 构造空响应，直接回调
        NSURLResponse *resp = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"application/json" expectedContentLength:0 textEncodingName:nil];
        completionHandler([NSData data], resp, nil);
        return nil;
    }
    return orig_dataTaskWithRequest_completionHandler(self, _cmd, request, completionHandler);
}
static NSURLSessionDataTask* new_AFHTTPSessionManager_dataTask(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *url = request.URL.absoluteString;
    if ([url containsString:@"ads.pangle.io"] ||
        [url containsString:@"gdtad"] ||
        [url containsString:@"baidu"]) {
        NSURLResponse *resp = [[NSURLResponse alloc] initWithURL:request.URL MIMEType:@"application/json" expectedContentLength:0 textEncodingName:nil];
        completionHandler([NSData data], resp, nil);
        return nil;
    }
    return orig_AFHTTPSessionManager_dataTaskWithRequest_completionHandler(self, _cmd, request, completionHandler);
}

// ---------- 激励视频自动奖励 ----------
%hook RewardedVideoAd
- (void)rewardedVideoAdDidRewardUser:(id)info {
    // 强制调用奖励回调
    if ([(id)self respondsToSelector:@selector(rewardUser)]) {
        [(id)self performSelector:@selector(rewardUser)];
    }
    %orig;
}
%end
