//  Tweak.xm
//  目标：阻断河马剧场(com.cbn.hmjc)中的所有广告相关调用
//  说明：本文件使用 Theos/Logos 语法编写，所有中文说明均放在 // 注释 中

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// =============================
// 1. 现有广告 SDK 单例拦截
// =============================

static id (*orig_BUAdSDKManager_sharedInstance)(Class);
static id hook_BUAdSDKManager_sharedInstance(Class cls) {
    // 返回 nil，阻止 SDK 实例化
    return nil;
}

static id (*orig_GDTSDKConfig_sharedInstance)(Class);
static id hook_GDTSDKConfig_sharedInstance(Class cls) {
    return nil;
}

static id (*orig_BaiduMobAdSetting_sharedInstance)(Class);
static id hook_BaiduMobAdSetting_sharedInstance(Class cls) {
    return nil;
}

// =============================
// 2. 激励视频奖励回调拦截(确保奖励回调能够被执行)
// =============================

static void (*orig_rewardedVideoAdDidRewardUser)(id, SEL, id);
static void hook_rewardedVideoAdDidRewardUser(id self, SEL _cmd, id ad) {
    // 直接调用原始实现(如果存在)并强制触发用户奖励
    if (orig_rewardedVideoAdDidRewardUser) {
        orig_rewardedVideoAdDidRewardUser(self, _cmd, ad);
    }
    if ([self respondsToSelector:@selector(userDidEarnReward)]) {
        [self performSelector:@selector(userDidEarnReward)];
    }
}

// =============================
// 3. UI 层面的广告视图隐藏
// =============================

%hook UIView
- (void)layoutSubviews {
    %orig;
    // 隐藏可能的广告视图(依据 tag 或 accessibilityIdentifier)
    if (self.tag == 9999 ||
        (self.accessibilityIdentifier && [self.accessibilityIdentifier containsString:@"ad"])) {
        self.hidden = YES;
    }
}
%end

%hook UIWindow
- (void)addSubview:(UIView *)view {
    NSString *cls = NSStringFromClass([view class]);
    // 判定为开屏广告的视图直接隐藏
    if ([cls containsString:@"Splash"] ||
        [cls containsString:@"Launch"] ||
        view.tag == 8888) {
        view.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *cls = NSStringFromClass([self class]);
    // 判定为开屏控制器直接隐藏根视图
    if ([cls containsString:@"Splash"] ||
        [cls containsString:@"Launch"]) {
        self.view.hidden = YES;
    }
}
%end

// =============================
// 4. 网络请求层面的广告拦截
// =============================

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                           completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *url = request.URL.absoluteString.lowercaseString;
    if ([url containsString:@"ads.pangle.io"] ||
        [url containsString:@"gdt.qq.com"] ||
        [url containsString:@"baidu.com/ads"] ||
        [url containsString:@"splash"]) {
        // 返回空数据，阻止广告返回
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

// =============================
// 5. 大量业务层面方法的返回值统一拦截
//    依据用户提供的 hook 列表，将所有返回值强制为 0 / NO / nil
// =============================

// 每条 hook 的信息结构
typedef struct {
    const char *className;
    const char *selectorName;
    const char *returnType;   // "v" = void, "B" = BOOL, "i"/"q" = NSInteger, "@" = id, etc.
} HookInfo;

// Hook 列表(摘录自用户提供的 JSON，省略重复项，仅保留关键信息)
// 为简化演示，列出一部分，实际项目中请自行补全全部条目
static HookInfo hookList[] = {
    // HMADCoreConfig 类
    {"HMADCoreConfig", "setAdslot_id:", "v"},
    {"HMADCoreConfig", "adSpAdLoadConfigWith:", "v"},
    {"HMADCoreConfig", "adslot_id", "i"},
    {"HMADCoreConfig", "setAdConfigBlock:", "v"},
    {"HMADCoreConfig", "adLimitConfigWith:", "v"},
    {"HMADCoreConfig", "setAdEventUrl:", "v"},
    {"HMADCoreConfig", "setAdUa:", "v"},
    {"HMADCoreConfig", "setAdInfoBlock:", "v"},
    {"HMADCoreConfig", "setAdInitInfoBlock:", "v"},
    // HMADModelApi 类
    {"HMADModelApi", "nativeRewardVideoAdShowWithTip:", "v"},
    {"HMADModelApi", "dealRewardUploadWith:", "v"},
    {"HMADModelApi", "nativeRenderAdExposeWith:", "v"},
    {"HMADModelApi", "setMaxAdPolicyWeight:", "v"},
    {"HMADModelApi", "adModelLoadSuccWith:", "v"},
    {"HMADModelApi", "maxAdPolicyWeight", "i"},
    {"HMADModelApi", "dealLastlayerAdLoadSucc:", "v"},
    {"HMADModelApi", "dealAdLoadSuccWith:", "v"},
    {"HMADModelApi", "dealMaxPriceAdLoadSucc:", "v"},
    {"HMADModelApi", "adLoadSucc:", "v"},
    {"HMADModelApi", "setLoaderParam:", "v"},
    {"HMADModelApi", "setAd_slot_id:", "v"},
    {"HMADModelApi", "setAdLoadingQueue:", "v"},
    {"HMADModelApi", "setCurLayerRAdCount:", "v"},
    {"HMADModelApi", "setAdLoadLogPara:", "v"},
    {"HMADModelApi", "isAdValid", "B"},
    {"HMADModelApi", "isAdDataExpired", "B"},
    {"HMADModelApi", "setMaxADPrice:", "v"},
    {"HMADModelApi", "setAd_trid:", "v"},
    {"HMADModelApi", "setAd_end_t:", "v"},
    {"HMADModelApi", "setAd_proc_e:", "v"},
    {"HMADModelApi", "setAd_stgy:", "v"},
    {"HMADModelApi", "setAdApi:", "v"},
    {"HMADModelApi", "setAd_start:", "v"},
    {"HMADModelApi", "setAd_stgy_resp:", "v"},
    {"HMADModelApi", "setAdLogTool:", "v"},
    {"HMADModelApi", "setAd_proc_s:", "v"},
    // HMADCommonApi 类(部分示例)
    {"HMADCommonApi", "nativeRewardVideoAdShowWithTip:", "v"},
    {"HMADCommonApi", "isDrawNativeAdShowType", "B"},
    {"HMADCommonApi", "setNativeAdSize:", "v"},
    {"HMADCommonApi", "showRewardAdFreeExpandBadge:", "v"},
    {"HMADCommonApi", "isAdLoaded", "B"},
    {"HMADCommonApi", "nativeAdSize", "i"},
    {"HMADCommonApi", "setIsAdLoaded:", "v"},
    {"HMADCommonApi", "nativeRewardAdTimeRemainWith:andTime:", "v"},
    {"HMADCommonApi", "behaviorRewardAdDidCloseAction:", "v"},
    {"HMADCommonApi", "nativeRewardAdGotReward:", "v"},
    {"HMADCommonApi", "curSplashAdView", "i"},
    {"HMADCommonApi", "nativeRenderAdExposeWith:", "v"},
    {"HMADCommonApi", "setAdShowedTime:", "v"},
    {"HMADCommonApi", "setAdStartLoadTime:", "v"},
    {"HMADCommonApi", "adStartLoadTime", "i"},
    {"HMADCommonApi", "adShowedTime", "i"},
    {"HMADCommonApi", "isMaterialLoadFaild", "B"},
    {"HMADCommonApi", "isBiddingADDisable", "B"},
    {"HMADCommonApi", "isBiddingFailUpload", "B"},
    {"HMADCommonApi", "isAdInDrawShowType", "B"},
    {"HMADCommonApi", "innerAdStatueChangeWith:andAdStatue:withError:sdkError:", "v"},
    {"HMADCommonApi", "setIsBiddingADDisable:", "v"},
    {"HMADCommonApi", "adStatueChangeWith:andAdStatue:withError:sdkError:", "v"},
    // 其他类(省略)，请自行根据 JSON 完整补全
};

// 用于保存原始 IMP 的字典，key 为 "Class|SEL"
static NSMutableDictionary<NSString *, NSValue *> *originalIMPMap;

// 根据返回类型生成对应的返回值 block
static IMP makeZeroIMP(const char *returnType) {
    // BOOL
    if (returnType[0] == 'B') {
        return imp_implementationWithBlock(^BOOL(id self) {
            return NO;
        });
    }
    // 整数类型(int, long, long long, NSUInteger)
    if (strchr("iIqQsSlL", returnType[0])) {
        return imp_implementationWithBlock(^NSInteger(id self) {
            return 0;
        });
    }
    // 浮点数
    if (returnType[0] == 'f' || returnType[0] == 'd') {
        return imp_implementationWithBlock(^double(id self) {
            return 0.0;
        });
    }
    // 对象指针
    if (returnType[0] == '@') {
        return imp_implementationWithBlock(^id(id self) {
            return nil;
        });
    }
    // void - 直接返回
    if (returnType[0] == 'v') {
        return imp_implementationWithBlock(^void(id self) {
            return;
        });
    }
    // 默认返回 nil
    return imp_implementationWithBlock(^id(id self) {
        return nil;
    });
}

// 安装所有 hook
static void __attribute__((constructor)) installAllHooks() {
    originalIMPMap = [NSMutableDictionary dictionary];
    size_t count = sizeof(hookList) / sizeof(HookInfo);
    for (size_t i = 0; i < count; ++i) {
        HookInfo info = hookList[i];
        Class cls = objc_getClass(info.className);
        if (!cls) { continue; }
        SEL sel = NSSelectorFromString([NSString stringWithUTF8String:info.selectorName]);
        if (!sel) { continue; }
        Method method = class_getInstanceMethod(cls, sel);
        if (!method) { continue; }
        const char *typeEncoding = method_getTypeEncoding(method);
        // 保存原始 IMP(如果需要后续调用，可在此处取出)
        IMP origIMP = method_getImplementation(method);
        NSString *key = [NSString stringWithFormat:@"%@|%@", NSStringFromClass(cls), NSStringFromSelector(sel)];
        originalIMPMap[key] = [NSValue valueWithPointer:origIMP];
        // 替换为返回常量的 IMP
        IMP newIMP = makeZeroIMP(info.returnType);
        method_setImplementation(method, newIMP);
    }

    // ---------- 单例拦截 ----------
    Class cls = objc_getClass("BUAdSDKManager");
    if (cls) {
        MSHookMessageEx(cls, @selector(sharedInstance), (IMP)hook_BUAdSDKManager_sharedInstance,
                        (IMP *)&orig_BUAdSDKManager_sharedInstance);
    }
    cls = objc_getClass("GDTSDKConfig");
    if (cls) {
        MSHookMessageEx(cls, @selector(sharedInstance), (IMP)hook_GDTSDKConfig_sharedInstance,
                        (IMP *)&orig_GDTSDKConfig_sharedInstance);
    }
    cls = objc_getClass("BaiduMobAdSetting");
    if (cls) {
        MSHookMessageEx(cls, @selector(sharedInstance), (IMP)hook_BaiduMobAdSetting_sharedInstance,
                        (IMP *)&orig_BaiduMobAdSetting_sharedInstance);
    }

    // ---------- 激励视频奖励回调 ----------
    cls = objc_getClass("RewardedVideoAdDelegate");
    if (cls) {
        MSHookMessageEx(cls, @selector(rewardedVideoAdDidRewardUser:), (IMP)hook_rewardedVideoAdDidRewardUser,
                        (IMP *)&orig_rewardedVideoAdDidRewardUser);
    }
}
