**河马剧场广告移除 Tweak（.xm 文件）**

```objc
// Tweak.xm
// 名称：HippoAdBlock (河马剧场去广告)
// 作者：Grok 生成示例
// 描述：针对河马剧场（Hippo Theater）常见的穿山甲(Pangle)、优量汇(GDT)、百度广告进行 Hook 移除/绕过。
// 功能重点：Hook 初始化、加载、展示方法，返回成功/空视图，并强制奖励回调（观看激励视频直接给奖励）。

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ====================== 通用工具 ======================
static void Log(NSString *msg) {
    NSLog(@"[HippoAdBlock] %@", msg);
}

// ====================== Pangle / 穿山甲 (ByteDance) ======================
%hook PAGRewardedAd  // 激励视频
- (BOOL)loadAdWithSlotID:(NSString *)slotID request:(PAGRewardedRequest *)request {
    Log([NSString stringWithFormat:@"PAGRewardedAd loadAdWithSlotID: %@ (已阻断)", slotID]);
    return YES;  // 伪装加载成功
}

- (void)showFromRootViewController:(UIViewController *)rootViewController {
    Log(@"PAGRewardedAd show (直接跳过展示)");
    // 直接触发奖励回调
    if ([self respondsToSelector:@selector(rewardedAdUserDidEarnReward:)]) {
        [self rewardedAdUserDidEarnReward:self];
    }
    // %orig;  // 注释掉不实际展示
}

- (void)rewardedAdUserDidEarnReward:(PAGRewardedAd *)rewardedAd {
    Log(@"PAGRewardedAd 强制发放奖励");
    %orig;
}
%end

%hook PAGInterstitialAd  // 插屏
- (BOOL)loadAdWithSlotID:(NSString *)slotID request:(PAGInterstitialRequest *)request {
    Log(@"PAGInterstitialAd load (阻断)");
    return YES;
}

- (void)showFromRootViewController:(UIViewController *)rootViewController {
    Log(@"PAGInterstitialAd show (阻断)");
}
%end

%hook PAGNativeAd  // 原生广告
- (void)showInView:(UIView *)view {
    Log(@"PAGNativeAd showInView (隐藏)");
    [view removeFromSuperview];
}
%end

// ====================== GDT / 优量汇 (Tencent) ======================
%hook GDTUnifiedNativeAdView
- (instancetype)initWithFrame:(CGRect)frame {
    Log(@"GDTUnifiedNativeAdView init (返回空/隐藏)");
    self = %orig;
    if (self) [self setHidden:YES];
    return self;
}

- (void)layoutSubviews {
    %orig;
    [self setHidden:YES];
    [self removeFromSuperview];
}
%end

%hook GDTRewardedVideoAd  // 激励视频
- (void)loadAd {
    Log(@"GDTRewardedVideoAd loadAd (阻断)");
}

- (void)showAdFromRootViewController:(UIViewController *)rootViewController {
    Log(@"GDTRewardedVideoAd show (直接给奖励)");
    if ([self.delegate respondsToSelector:@selector(gdt_rewardedVideoAdDidReward:)]) {
        [self.delegate gdt_rewardedVideoAdDidReward:self];
    }
}
%end

%hook GDTNativeExpressAdView
- (void)render {
    Log(@"GDTNativeExpressAdView render (移除)");
    [self removeFromSuperview];
}
%end

// ====================== 百度广告 (Baidu MobAd) ======================
%hook BaiduMobAdRewardedVideo
- (void)load {
    Log(@"BaiduMobAdRewardedVideo load (阻断)");
}

- (void)showFromRootViewController:(UIViewController *)rootViewController {
    Log(@"BaiduMobAdRewardedVideo show (直接奖励)");
    if ([self.delegate respondsToSelector:@selector(rewardedVideoAdDidRewardSuccess:)]) {
        [self.delegate rewardedVideoAdDidRewardSuccess:self];
    }
}
%end

%hook BaiduMobAdNative
- (void)nativeAdDidLoad {
    Log(@"BaiduMobAdNative didLoad (阻断展示)");
}
%end

%hook BaiduMobAdInterstitial
- (void)showInView:(UIView *)view {
    Log(@"BaiduMobAdInterstitial show (移除)");
    [view removeFromSuperview];
}
%end

// ====================== 通用广告视图 Hook (兜底) ======================
%hook UIView
- (void)didMoveToSuperview {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || 
        [className containsString:@"PAG"] || 
        [className containsString:@"GDT"] || 
        [className containsString:@"Baidu"]) {
        Log([NSString stringWithFormat:@"检测到广告视图 %@，已移除", className]);
        [self setHidden:YES];
        [self removeFromSuperview];
    }
}
%end

// ====================== Constructor ======================
%ctor {
    Log(@"河马剧场去广告 Tweak 已加载 (HippoAdBlock)");
    %init;
}
```

### 编译设置（Makefile）说明

```makefile
# Makefile
TARGET := iphone:clang:latest:13.0
INSTALL_TARGET_PROCESSES = 河马剧场  # 或实际的 Bundle ID / 可执行文件名

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HippoAdBlock

HippoAdBlock_FILES = Tweak.xm
HippoAdBlock_CFLAGS = -fobjc-arc
HippoAdBlock_LDFLAGS = -framework UIKit -framework Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
```

**使用说明：**
1. 使用 Theos 创建 tweak 项目：`nic.pl` 选择 tweak 模板。
2. 替换 `Tweak.xm` 和 `Makefile`。
3. `make package` 打包 `.deb`，安装到越狱设备。
4. 实际使用时建议用 `class-dump` 或 `Cycript` / `Frida` 分析河马剧场具体使用的广告类名，进一步细化 Hook。
5. 部分方法签名可能因 SDK 版本略有差异，可根据日志调整。
6. 此代码为通用示例，仅供学习/研究，实际效果视 App 版本而定。

如需针对特定广告类的更精确 Hook 或添加 Preference 设置，告诉我更多细节（如具体类名）。