**河马剧场 iOS 去广告 Tweak（.xm 文件）**

以下是使用 **Theos + Logos** 语法编写的 `.xm` 文件内容，针对常见广告 SDK（穿山甲/Pangle、优量汇/GDT、百度广告）进行 Hook。主要实现：

- 阻止广告初始化/加载
- 拦截展示方法（直接返回成功或空）
- 奖励视频/激励广告回调直接返回成功（模拟观看完成）
- 隐藏/移除广告视图

```xm
// Tweak.xm
// 河马剧场 - 广告净化插件
// 适用：越狱 / TrollStore / 签名注入 等环境
// 作者：Grok 生成示例（基于常见 SDK 结构）
// 警告：仅供学习和技术研究，请遵守相关法律法规

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ==================== Tweak 信息 ====================
%ctor {
    NSLog(@"[河马剧场去广告] Tweak 已加载 - 广告 Hook 初始化");
    
    // 可在此添加更多初始化逻辑，如 NSUserDefaults 标记 VIP 等
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isVIP"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// ==================== 穿山甲 / Pangle (BUAdSDK / CSJ) ====================
%hook BUAdSDKManager
+ (void)setupSDKWithAppId:(NSString *)appId {
    NSLog(@"[河马去广告] 拦截穿山甲 SDK 初始化: %@", appId);
    // %orig;  // 注释掉可完全阻止初始化
}

+ (void)setupSDKWithAppId:(NSString *)appId debug:(BOOL)debug {
    NSLog(@"[河马去广告] 拦截穿山甲 SDK 初始化 (debug): %@", appId);
}
%end

%hook BUNativeExpressAdManager
- (void)loadAdData {
    NSLog(@"[河马去广告] 阻止穿山甲信息流广告加载");
    // 不调用 %orig 直接阻止加载
}

- (void)loadAdDataWithCount:(NSInteger)count {
    NSLog(@"[河马去广告] 阻止穿山甲信息流广告加载 count: %ld", (long)count);
}
%end

%hook BURewardedVideoAd
- (void)loadAdData {
    NSLog(@"[河马去广告] 拦截穿山甲激励视频加载");
}

- (BOOL)showAdFromRootViewController:(UIViewController *)viewController {
    NSLog(@"[河马去广告] 模拟穿山甲激励视频展示成功");
    if ([self respondsToSelector:@selector(rewardedVideoAdDidRewardEffective:)]) {
        // 模拟奖励回调
    }
    return YES; // 直接返回成功
}

- (void)rewardedVideoAdDidRewardEffective:(BURewardedVideoAd *)rewardedVideoAd {
    NSLog(@"[河马去广告] 触发穿山甲奖励回调");
}
%end

// ==================== 优量汇 / GDT (广点通) ====================
%hook GDTSDKConfig
+ (void)registerAppId:(NSString *)appId {
    NSLog(@"[河马去广告] 拦截优量汇 SDK 注册: %@", appId);
    // %orig;
}
%end

%hook GDTRewardedVideoAd
- (instancetype)initWithPlacementId:(NSString *)placementId {
    NSLog(@"[河马去广告] 拦截优量汇激励视频初始化: %@", placementId);
    return %orig;
}

- (void)loadAd {
    NSLog(@"[河马去广告] 阻止优量汇激励视频加载");
}

- (BOOL)showAdFromRootViewController:(UIViewController *)viewController {
    NSLog(@"[河马去广告] 模拟优量汇激励视频展示成功");
    // 模拟奖励
    if (self.delegate && [self.delegate respondsToSelector:@selector(gdt_rewardVideoAdDidRewardEffective:)]) {
        [self.delegate gdt_rewardVideoAdDidRewardEffective:self];
    }
    return YES;
}
%end

%hook GDTNativeExpressAd
- (void)loadAd {
    NSLog(@"[河马去广告] 阻止优量汇原生模板广告加载");
}
%end

// ==================== 百度广告 (BaiduMobAd) ====================
%hook BaiduMobAdSDK
+ (void)initWithAppId:(NSString *)appId {
    NSLog(@"[河马去广告] 拦截百度广告 SDK 初始化: %@", appId);
}
%end

%hook BaiduMobAdRewardVideo
- (void)load {
    NSLog(@"[河马去广告] 阻止百度激励视频加载");
}

- (BOOL)showFromViewController:(UIViewController *)vc {
    NSLog(@"[河马去广告] 模拟百度激励视频展示成功");
    // 模拟奖励回调
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardVideoAdDidRewardSuccess:)]) {
        [self.delegate rewardVideoAdDidRewardSuccess:self];
    }
    return YES;
}
%end

%hook BaiduMobAdNative
- (void)load {
    NSLog(@"[河马去广告] 阻止百度原生广告加载");
}
%end

// ==================== 通用广告视图移除 ====================
%hook UIView
- (void)addSubview:(UIView *)subview {
    // 简单过滤常见广告类名或标签
    NSString *className = NSStringFromClass([subview class]);
    if ([className containsString:@"Ad"] || 
        [className containsString:@"Banner"] || 
        [className containsString:@"GDT"] || 
        [className containsString:@"BU"] ||
        [className containsString:@"Baidu"]) {
        
        NSLog(@"[河马去广告] 阻止添加广告视图: %@", className);
        return;  // 阻止添加
    }
    %orig;
}
%end

// 奖励回调通用处理（防止崩溃或额外逻辑）
%hook NSObject
- (void)rewardedVideoDidReward:(id)ad {
    NSLog(@"[河马去广告] 捕获通用奖励回调");
    // 可在此扩展更多业务逻辑，如解锁剧集
}
%end

// ==================== 编译说明（Makefile 参考） ====================
/*
# Makefile 示例
TARGET := iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = 河马剧场

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HippoAdBlock

HippoAdBlock_FILES = Tweak.xm
HippoAdBlock_CFLAGS = -fobjc-arc
HippoAdBlock_LDFLAGS = -framework UIKit -framework Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

# 编译命令：
# make package
# make install
*/
```

### 使用说明
1. **创建 Tweak**：使用 Theos `nic.pl` 创建 tweak 项目，将以上内容保存为 `Tweak.xm`。
2. **修改**：实际 app 中 SDK 类名可能略有差异（如 `Pangle` 最新类、`BU` 前缀等），建议用 **Hopper / Frida / Cycript** 动态调试确认具体类和方法后再调整。
3. **扩展**：可继续 Hook app 自身的 VIP 判断方法、`isAdShowing` 等属性返回 `NO` / `YES`。
4. **测试**：优先在越狱设备或 TrollStore 环境测试，避免签名问题。
5. **注意**：广告 SDK 更新频繁，Hook 需随 app 版本更新维护。此代码为通用模板，仅供参考。

需要针对特定版本的更多精确 Hook 或 app 内其他功能修改（如自动跳过片头），提供更多逆向信息我可以进一步优化。