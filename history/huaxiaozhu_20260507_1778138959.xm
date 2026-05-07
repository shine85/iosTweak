// Tweak.xm
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/NSURLSession.h>

// ---------- 广告 SDK 类声明 ----------
@interface BUAdSDKManager : NSObject
+ (instancetype)sharedInstance;
@end

@interface GDTSDKConfig : NSObject
+ (instancetype)sharedInstance;
@end

@interface BaiduMobAdSetting : NSObject
+ (instancetype)sharedInstance;
@end

// ---------- 代理回调协议(占位) ----------
@protocol BUSplashAdDelegate
- (void)adDidClose;
@end

@protocol GDTRewardedVideoAdDelegate
- (void)rewardedVideoAdDidRewardUser;
@end

@protocol BaiduMobAdRewardVideoDelegate
- (void)playFinish;
@end

// ---------- 原始方法指针 ----------
static id (*orig_BUAdSDKManager_sharedInstance)(Class, SEL);
static id (*orig_GDTSDKConfig_sharedInstance)(Class, SEL);
static id (*orig_BaiduMobAdSetting_sharedInstance)(Class, SEL);
static NSURLSessionDataTask *(*orig_dataTaskWithRequest_completionHandler)(NSURLSession *, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *));
static void (*orig_layoutSubviews)(UIView *, SEL);
static void (*orig_didMoveToWindow)(UIView *, SEL);

// ---------- Hook 实现 ----------
static id hook_BUAdSDKManager_sharedInstance(Class cls, SEL sel) {
    // 直接返回 nil，阻止 SDK 初始化
    return nil;
}

static id hook_GDTSDKConfig_sharedInstance(Class cls, SEL sel) {
    return nil;
}

static id hook_BaiduMobAdSetting_sharedInstance(Class cls, SEL sel) {
    return nil;
}

static NSURLSessionDataTask *hook_dataTaskWithRequest_completionHandler(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^handler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlStr = request.URL.absoluteString;
    // 关键字匹配广告请求
    if ([urlStr containsString:@"ads.pangle.io"] ||
        [urlStr containsString:@"gdt.qq.com"] ||
        [urlStr containsString:@"baidu.com"] ) {
        // 返回一个已完成的空任务，阻断广告数据
        NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            // 直接回调空数据
            if (handler) handler(nil, nil, nil);
        }];
        [task resume];
        return task;
    }
    // 非广告请求走原始实现
    return orig_dataTaskWithRequest_completionHandler(self, _cmd, request, handler);
}

static void hook_layoutSubviews(UIView *self, SEL _cmd) {
    // 先执行原始布局
    orig_layoutSubviews(self, _cmd);
    // 隐藏常见广告视图
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Ad"] || [clsName containsString:@"Banner"] || [clsName containsString:@"Splash"]) {
        self.hidden = YES;
        [self removeFromSuperview];
    }
}

static void hook_didMoveToWindow(UIView *self, SEL _cmd) {
    orig_didMoveToWindow(self, _cmd);
    // 再次检查并隐藏
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Ad"] || [clsName containsString:@"Banner"] || [clsName containsString:@"Splash"]) {
        self.hidden = YES;
        [self removeFromSuperview];
    }
}

// ---------- 构造函数，最早注入 ----------
static __attribute__((constructor)) void initialize() {
    // ------ BUAdSDKManager ------
    Class buCls = NSClassFromString(@"BUAdSDKManager");
    if (buCls) {
        SEL sel = @selector(sharedInstance);
        Method m = class_getClassMethod(buCls, sel);
        if (m) {
            orig_BUAdSDKManager_sharedInstance = (id (*)(Class, SEL))method_getImplementation(m);
            MSHookMessageEx(buCls, sel, (IMP)hook_BUAdSDKManager_sharedInstance, (IMP *)&orig_BUAdSDKManager_sharedInstance);
        }
    }

    // ------ GDTSDKConfig ------
    Class gdtCls = NSClassFromString(@"GDTSDKConfig");
    if (gdtCls) {
        SEL sel = @selector(sharedInstance);
        Method m = class_getClassMethod(gdtCls, sel);
        if (m) {
            orig_GDTSDKConfig_sharedInstance = (id (*)(Class, SEL))method_getImplementation(m);
            MSHookMessageEx(gdtCls, sel, (IMP)hook_GDTSDKConfig_sharedInstance, (IMP *)&orig_GDTSDKConfig_sharedInstance);
        }
    }

    // ------ BaiduMobAdSetting ------
    Class bdCls = NSClassFromString(@"BaiduMobAdSetting");
    if (bdCls) {
        SEL sel = @selector(sharedInstance);
        Method m = class_getClassMethod(bdCls, sel);
        if (m) {
            orig_BaiduMobAdSetting_sharedInstance = (id (*)(Class, SEL))method_getImplementation(m);
            MSHookMessageEx(bdCls, sel, (IMP)hook_BaiduMobAdSetting_sharedInstance, (IMP *)&orig_BaiduMobAdSetting_sharedInstance);
        }
    }

    // ------ NSURLSession 数据拦截 ------
    Class sessionCls = [NSURLSession class];
    SEL sel_dataTask = @selector(dataTaskWithRequest:completionHandler:);
    Method mDataTask = class_getInstanceMethod(sessionCls, sel_dataTask);
    if (mDataTask) {
        orig_dataTaskWithRequest_completionHandler = (NSURLSessionDataTask *(*)(NSURLSession *, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))method_getImplementation(mDataTask);
        MSHookMessageEx(sessionCls, sel_dataTask, (IMP)hook_dataTaskWithRequest_completionHandler, (IMP *)&orig_dataTaskWithRequest_completionHandler);
    }

    // ------ UIView 广告视图隐藏 ------
    Class viewCls = [UIView class];
    SEL sel_layout = @selector(layoutSubviews);
    Method mLayout = class_getInstanceMethod(viewCls, sel_layout);
    if (mLayout) {
        orig_layoutSubviews = (void (*)(UIView *, SEL))method_getImplementation(mLayout);
        MSHookMessageEx(viewCls, sel_layout, (IMP)hook_layoutSubviews, (IMP *)&orig_layoutSubviews);
    }

    SEL sel_move = @selector(didMoveToWindow);
    Method mMove = class_getInstanceMethod(viewCls, sel_move);
    if (mMove) {
        orig_didMoveToWindow = (void (*)(UIView *, SEL))method_getImplementation(mMove);
        MSHookMessageEx(viewCls, sel_move, (IMP)hook_didMoveToWindow, (IMP *)&orig_didMoveToWindow);
    }

    // ------ 奖励视频自动达成(示例) ------
    // 这里演示对 GDTRewardedVideoAdDelegate 回调的“硬核”劫持
    Class gdtRewardCls = NSClassFromString(@"GDTRewardedVideoAd");
    if (gdtRewardCls) {
        SEL selReward = @selector(rewardedVideoAdDidRewardUser);
        Method mReward = class_getInstanceMethod(gdtRewardCls, selReward);
        if (mReward) {
            // 替换为直接调用原始实现后，再自行触发奖励回调
            void (^original)(id, SEL) = (void (^)(id, SEL))method_getImplementation(mReward);
            IMP newImp = imp_implementationWithBlock(^void(id _self) {
                // 调用原实现(如果有)
                if (original) original(_self, selReward);
                // 强制触发奖励逻辑
                if ([_self respondsToSelector:@selector(delegate)]) {
                    id delegate = [_self performSelector:@selector(delegate)];
                    if (delegate && [delegate respondsToSelector:@selector(rewardedVideoAdDidRewardUser)]) {
                        [(id)delegate rewardedVideoAdDidRewardUser];
                    }
                }
            });
            method_setImplementation(mReward, newImp);
        }
    }
}
