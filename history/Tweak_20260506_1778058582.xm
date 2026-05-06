**河马剧场 去广告 Tweak（.xm 文件）**

```xm
// =============================================
// Tweak Name: 河马剧场去广告 (HippoAdKiller)
// Version: 1.0
// Author: Grok Generated
// Platform: iOS (Theos + Logos)
// Target: 河马剧场 (短剧App)
// Description: Hook 常见广告SDK，屏蔽初始化、展示、奖励回调等，实现去广告效果。
// 注意：仅供学习/研究/个人使用，实际效果取决于App内置SDK版本。
// =============================================

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==================== 穿山甲 (Pangle / CSJ) ====================
%hook BUAdSDKManager
+ (void)setupSDKWithAppId:(NSString *)appId {
    NSLog(@"【河马去广告】Hook 穿山甲 SDK 初始化");
    // 直接返回，不初始化真实广告SDK
    %orig(@"fake_app_id_for_bypass");
}
%end

%hook BUNativeExpressAdManager
- (instancetype)initWithSlot:(BUAdSlot *)slot adSize:(CGSize)adSize {
    NSLog(@"【河马去广告】阻止 BUNativeExpressAdManager 初始化");
    return nil; // 或返回一个假对象
}

- (void)loadAdDataWithCount:(NSInteger)count {
    NSLog(@"【河马去广告】阻止穿山甲信息流广告加载");
    // 不调用 %orig
}
%end

%hook BUNativeExpressAdView
- (void)render {
    NSLog(@"【河马去广告】阻止穿山甲广告渲染");
}

- (void)showAdFromRootViewController:(UIViewController *)viewController {
    NSLog(@"【河马去广告】阻止穿山甲广告展示");
}
%end

// 激励视频相关
%hook BURewardedVideoAd
- (void)loadAdData {
    NSLog(@"【河马去广告】阻止穿山甲激励视频加载");
}

- (BOOL)showAdFromRootViewController:(UIViewController *)viewController {
    NSLog(@"【河马去广告】Hook 穿山甲激励视频展示 -> 直接给奖励");
    [self rewardedVideoAdDidReward]; // 模拟奖励回调
    return YES;
}
%end

// ==================== 优量汇 / 广点通 (GDT / Tencent) ====================
%hook GDTSDKConfig
+ (BOOL)registerAppId:(NSString *)appId {
    NSLog(@"【河马去广告】Hook 优量汇 SDK 注册");
    return YES;
}
%end

%hook GDTNativeExpressAdView
- (instancetype)initWithFrame:(CGRect)frame adSize:(GDTNativeExpressAdSize)size {
    NSLog(@"【河马去广告】阻止优量汇信息流广告View创建");
    return nil;
}

- (void)render {
    NSLog(@"【河马去广告】阻止优量汇广告渲染");
}
%end

%hook GDTRewardedVideoAd
- (void)loadAd {
    NSLog(@"【河马去广告】阻止优量汇激励视频加载");
}

- (BOOL)showAdFromRootViewController:(UIViewController *)viewController {
    NSLog(@"【河马去广告】Hook 优量汇激励视频 -> 直接奖励");
    if ([self respondsToSelector:@selector(rewardedVideoAdDidReward)]) {
        [self rewardedVideoAdDidReward];
    }
    return YES;
}
%end

// ==================== 百度广告 (Baidu) ====================
%hook BaiduMobAdSDK
+ (void)initWithAppId:(NSString *)appId {
    NSLog(@"【河马去广告】Hook 百度广告 SDK 初始化");
}
%end

%hook BaiduMobAdNative
- (void)request {
    NSLog(@"【河马去广告】阻止百度原生广告请求");
}
%end

%hook BaiduMobAdRewardVideo
- (void)load {
    NSLog(@"【河马去广告】阻止百度激励视频加载");
}

- (void)showFromViewController:(UIViewController *)vc {
    NSLog(@"【河马去广告】Hook 百度激励视频展示 -> 直接给奖励");
    // 模拟奖励成功
    if ([self.delegate respondsToSelector:@selector(rewardVideoAdRewardDidSuccess:)]) {
        [self.delegate rewardVideoAdRewardDidSuccess:self];
    }
}
%end

// ==================== 通用广告 View / Controller Hook ====================
// 尝试隐藏所有广告容器（通用兜底）
%hook UIView
- (void)didMoveToSuperview {
    %orig;
    
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || 
        [className containsString:@"Banner"] || 
        [className containsString:@"NativeExpress"] ||
        [className containsString:@"Reward"]) {
        
        NSLog(@"【河马去广告】检测到广告View: %@，尝试隐藏", className);
        self.hidden = YES;
        self.alpha = 0.0;
        [self removeFromSuperview];
    }
}
%end

// 奖励回调强制成功（部分SDK直接调用代理）
%hook NSObject
- (void)rewardedVideoAdDidReward {
    NSLog(@"【河马去广告】强制奖励回调成功");
    %orig;
}

- (void)rewardVideoAdRewardDidSuccess:(id)ad {
    NSLog(@"【河马去广告】强制百度/其他奖励成功");
    %orig;
}
%end

// ==================== Tweak 入口 ====================
%ctor {
    NSLog(@"========== 河马剧场去广告 Tweak 已加载 ==========");
    NSLog(@"支持 SDK: 穿山甲(Pangle)、优量汇(GDT)、百度广告");
    NSLog(@"重点 Hook: 初始化、加载、展示、奖励回调");
}
```

### 编译设置（Makefile / control 文件说明）

**Tweak.xm**：使用上面内容。

**Makefile** 示例：
```makefile
TARGET := iphone:clang:latest:12.0
INSTALL_TARGET_PROCESSES = 河马剧场  # 或实际Bundle ID对应的进程名

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HippoAdKiller
HippoAdKiller_FILES = Tweak.xm
HippoAdKiller_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
```

**control** 文件：
```
Package: com.yourname.hippoadkiller
Name: 河马剧场去广告
Version: 1.0
Architecture: iphoneos-arm64
Description: 去除河马剧场广告，支持主流广告SDK Hook
Maintainer: Your Name
Author: Grok
Section: Tweaks
Depends: mobilesubstrate
```

**使用建议**：
- 用 Theos 编译生成 `.dylib`（或 `.deb`）。
- 可根据实际逆向结果补充具体类名/方法（用 `class-dump` 或 `Cycript` / `Frida` 分析App）。
- 部分App可能使用聚合SDK（如 GroMore），可额外Hook聚合层。
- 测试时注意日志输出，逐步完善Hook。

需要针对特定版本的额外Hook或其他功能，随时提供App版本或更多细节我可以继续优化。