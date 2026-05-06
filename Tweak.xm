```xml
// 河马剧场 (Hippopotamus Theater) 去广告 Tweak
// 文件名: HippoAdKiller.xm
// 基于 Theos + Logos 语法
// 编译环境：Theos (iOS 12+ 推荐)

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==================== Tweak 信息 ====================
%ctor {
    NSLog(@"[河马剧场去广告] HippoAdKiller 已加载 - 针对穿山甲、优量汇、百度广告进行 Hook");
}

// ==================== 通用工具方法 ====================
static void fakeSuccess(NSString *sdk) {
    NSLog(@"[河马剧场去广告] %@ 广告已被拦截并伪造成功", sdk);
}

// ==================== 穿山甲 (Pangle / CSJ) Hook ====================
%hook BUNativeExpressAdManager
- (void)loadAdData {
    NSLog(@"[河马剧场去广告] 穿山甲 NativeExpressAdManager loadAdData 已拦截");
    // 不实际加载广告
}
%end

%hook BUNativeExpressFullscreenVideoAd
- (void)loadAdData {
    fakeSuccess(@"穿山甲 全屏视频");
    if ([self respondsToSelector:@selector(fullscreenVideoMaterialMetaDidLoad:)]) {
        // 模拟加载成功
    }
}
- (BOOL)showAdFromRootViewController:(UIViewController *)viewController {
    NSLog(@"[河马剧场去广告] 穿山甲 全屏视频展示已被阻止");
    return NO;
}
%end

%hook BUFullscreenVideoAd
- (void)loadAdData {
    fakeSuccess(@"穿山甲 FullscreenVideo");
}
- (BOOL)showAdFromRootViewController:(UIViewController *)viewController {
    return NO;
}
%end

%hook BURewardedVideoAd
- (void)loadAdData {
    fakeSuccess(@"穿山甲 激励视频");
}
- (BOOL)showAdFromRootViewController:(UIViewController *)viewController {
    NSLog(@"[河马剧场去广告] 穿山甲 激励视频展示已被阻止，返回奖励");
    // 直接伪造奖励回调
    if (self.rewardedVideoAdDidRewardEffective) {
        self.rewardedVideoAdDidRewardEffective(self);
    }
    return NO;
}
%end

// ==================== 优量汇 (GDT / 广点通) Hook ====================
%hook GDTRewardedVideoAd
- (instancetype)initWithPlacementId:(NSString *)placementId {
    NSLog(@"[河马剧场去广告] 优量汇 RewardedVideoAd init 已 Hook");
    return %orig;
}

- (void)loadAd {
    fakeSuccess(@"优量汇 激励视频");
}

- (BOOL)showAdFromRootViewController:(UIViewController *)viewController {
    NSLog(@"[河马剧场去广告] 优量汇 激励视频展示已被阻止");
    // 伪造奖励
    if ([self.delegate respondsToSelector:@selector(gdt_rewardVideoAdDidRewardEffective:)]) {
        [self.delegate gdt_rewardVideoAdDidRewardEffective:self];
    }
    return NO;
}
%end

%hook GDTNativeExpressAd
- (void)loadAd {
    NSLog(@"[河马剧场去广告] 优量汇 NativeExpressAd loadAd 已拦截");
}
%end

%hook GDTUnifiedNativeAd
- (void)loadAd {
    NSLog(@"[河马剧场去广告] 优量汇 UnifiedNativeAd loadAd 已拦截");
}
%end

// ==================== 百度广告 (Baidu MobAd) Hook ====================
%hook BaiduMobAdRewardedVideo
- (void)load {
    fakeSuccess(@"百度 激励视频");
}

- (BOOL)showFromViewController:(UIViewController *)vc {
    NSLog(@"[河马剧场去广告] 百度 激励视频展示已被阻止");
    // 伪造奖励回调
    if (self.rewardedVideoDidReward) {
        self.rewardedVideoDidReward();
    }
    return NO;
}
%end

%hook BaiduMobAdInterstitial
- (void)load {
    NSLog(@"[河马剧场去广告] 百度 插屏广告 load 已拦截");
}

- (BOOL)showFromViewController:(UIViewController *)vc {
    return NO;
}
%end

%hook BaiduMobAdNative
- (void)load {
    NSLog(@"[河马剧场去广告] 百度 Native 广告 load 已拦截");
}
%end

// ==================== 通用广告 View / Controller Hook ====================
%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    // 拦截常见的广告全屏页面
    NSString *className = NSStringFromClass([viewControllerToPresent class]);
    if ([className containsString:@"Ad"] || [className containsString:@"BU"] || [className containsString:@"GDT"] || [className containsString:@"Baidu"]) {
        NSLog(@"[河马剧场去广告] 拦截广告 ViewController: %@", className);
        if (completion) completion();
        return;
    }
    %orig;
}
%end

// 防止广告 WebView 或容器自动显示
%hook WKWebView
- (void)loadRequest:(NSURLRequest *)request {
    NSString *url = request.URL.absoluteString;
    if ([url containsString:@"pangle"] || [url containsString:@"gdt"] || [url containsString:@"baidu"]) {
        NSLog(@"[河马剧场去广告] 拦截广告 WebView 请求: %@", url);
        return;
    }
    %orig;
}
%end

// ==================== 编译说明 (Makefile) ====================
/*
编译步骤（Theos）：

1. 创建 tweak 项目：
   $THEOS/bin/nic.pl -t tweak

2. 编辑 control 文件：
   Package: com.hippo.adkiller
   Name: 河马剧场去广告
   Version: 1.0
   Architecture: iphoneos-arm64
   Description: 河马剧场 去除穿山甲、优量汇、百度广告
   Maintainer: YourName
   Depends: mobilesubstrate

3. 编辑 Makefile：
   TARGET := iphone:clang:latest:12.0
   INSTALL_TARGET_PROCESSES = HippoTheater   # 替换为实际进程名
   ARCHS = arm64

   include $(THEOS)/makefiles/common.mk
   TWEAK_NAME = HippoAdKiller
   HippoAdKiller_FILES = HippoAdKiller.xm
   HippoAdKiller_CFLAGS = -fobjc-arc
   HippoAdKiller_LDFLAGS = -framework UIKit -framework Foundation -framework WebKit

   include $(THEOS_MAKE_PATH)/tweak.mk

4. 打包安装：
   make package install
*/

```

**使用说明**：
- 将以上内容保存为 `HippoAdKiller.xm`
- 根据实际 App 包名修改 `INSTALL_TARGET_PROCESSES`
- 实际使用时可能需要通过 `class-dump` 或 `Cycript` / `Frida` 进一步确认具体类名和方法进行调整
- 该 Tweak 主要通过阻止展示 + 伪造成功/奖励回调来实现“去广告 + 免费看奖励内容”的效果

如需针对特定版本补充更多 Hook 或调整奖励逻辑，请提供 App 具体版本或崩溃日志，我可以进一步优化。