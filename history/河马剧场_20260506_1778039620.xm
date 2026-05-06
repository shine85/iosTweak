**河马剧场 iOS 去广告 Tweak（Theos/Logos）**

以下是完整的 `.xm` 文件内容（推荐命名为 `Tweak.xm`）。此 tweak 针对常见广告 SDK（穿山甲/Pangle、优量汇/GDT、百度）进行 Hook，主要实现：

- 阻止广告初始化/加载
- 拦截展示方法（直接返回成功或不显示）
- 强制奖励回调（无需观看广告即获得奖励）

**注意**：实际类名/方法可能因 SDK 版本和 App 封装而异。建议使用 `class-dump` 或 `Hopper` 对目标 App 的二进制进行逆向，确认具体类名后再微调。Hook 仅供学习/研究参考，请遵守相关法律法规。

```xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// =============================================
// Tweak 信息与说明
// =============================================
// 名称: 河马剧场去广告 (HippoAdKiller)
// 版本: 1.0
// 作者: Grok 生成示例
// 描述: Hook 穿山甲(Pangle)、优量汇(GDT)、百度广告 SDK，实现去广告 + 自动奖励
// 适用: 河马剧场 及类似短剧 App
// 编译环境: Theos + iOS SDK
// 
// 编译设置 (control 文件示例):
// Package: com.yourname.hippoadkiller
// Name: 河马剧场去广告
// Version: 1.0
// Architecture: iphoneos-arm64
// Description: 去除河马剧场广告并自动获得奖励
// Maintainer: Your Name <your@email.com>
// Depends: mobilesubstrate
// Conflicts: 
// 
// Makefile 关键设置:
// THEOS_DEVICE_IP = your-device-ip (可选)
// TARGET = iphone:clang:latest:14.0
// ARCHS = arm64
// INSTALL_TARGET_PROCESSES = HippoApp (替换为实际 App 可执行文件名)

%ctor {
    NSLog(@"[河马剧场去广告] Tweak 已加载 - 广告拦截已启用");
}

// =============================================
// 1. 穿山甲 / Pangle SDK (PAGxxx 类)
// =============================================
%hook PAGRewardedAd

// 阻止加载广告
+ (void)loadAdWithSlotID:(NSString *)slotID request:(PAGRewardedRequest *)request completionHandler:(void (^)(PAGRewardedAd * _Nullable, NSError * _Nullable))handler {
    NSLog(@"[Pangle] 拦截 RewardedAd 加载");
    if (handler) {
        // 直接返回成功，但不加载真实广告
        handler(nil, nil);  // 或构造假对象
    }
}

// 拦截展示
- (void)showAdFromRootViewController:(UIViewController *)rootViewController {
    NSLog(@"[Pangle] 拦截广告展示");
    // 不调用 %orig，直接跳过
}

// 奖励回调强制触发（部分版本）
- (BOOL)showAdFromRootViewController:(UIViewController *)rootViewController delegate:(id)delegate {
    NSLog(@"[Pangle] 强制触发奖励");
    if ([delegate respondsToSelector:@selector(rewardedAdUserDidEarnReward:)]) {
        [delegate rewardedAdUserDidEarnReward:self];
    }
    return YES;  // 模拟成功展示
}

%end

%hook PAGConfig
// 阻止 SDK 初始化
+ (void)startWithConfig:(PAGConfig *)config {
    NSLog(@"[Pangle] 拦截 SDK 初始化");
    // %orig;  // 可注释掉完全阻止
}
%end

// =============================================
// 2. 优量汇 / GDT SDK
// =============================================
%hook GDTRewardVideoAd

- (instancetype)initWithPlacementId:(NSString *)placementId {
    NSLog(@"[GDT] 拦截 RewardVideoAd 初始化");
    return %orig;
}

// 加载广告
- (void)loadAd {
    NSLog(@"[GDT] 拦截 loadAd");
    // 不加载真实广告
}

// 展示广告
- (BOOL)showAdFromRootViewController:(UIViewController *)rootViewController {
    NSLog(@"[GDT] 拦截 showAd");
    // 强制奖励
    if (self.delegate && [self.delegate respondsToSelector:@selector(gdt_rewardVideoAdDidRewardEffective:)]) {
        [self.delegate gdt_rewardVideoAdDidRewardEffective:self];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(gdt_rewardVideoAdDidRewardEffective:info:)]) {
        [self.delegate gdt_rewardVideoAdDidRewardEffective:self info:nil];
    }
    return YES;
}

%end

%hook GDTSDKConfig
+ (BOOL)registerAppId:(NSString *)appId {
    NSLog(@"[GDT] 拦截 registerAppId");
    return YES;  // 模拟成功
}
%end

// =============================================
// 3. 百度广告 SDK
// =============================================
%hook BaiduMobAdRewardVideo

- (void)load {
    NSLog(@"[Baidu] 拦截 load");
}

- (BOOL)showFromRootViewController:(UIViewController *)rootViewController {
    NSLog(@"[Baidu] 拦截 show，强制奖励");
    if (self.delegate && [self.delegate respondsToSelector:@selector(rewardVideoAdDidRewardSuccess:)]) {
        [self.delegate rewardVideoAdDidRewardSuccess:self];
    }
    return YES;
}

%end

// =============================================
// 通用广告拦截（可选，Hook 常见展示/初始化）
// =============================================
%hook UIViewController

// 尝试拦截可能用于展示广告的通用方法
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    NSString *className = NSStringFromClass([viewControllerToPresent class]);
    if ([className containsString:@"Ad"] || [className containsString:@"Reward"] || [className containsString:@"PAG"] || [className containsString:@"GDT"]) {
        NSLog(@"[通用] 拦截广告 ViewController 呈现: %@", className);
        if (completion) completion();
        return;
    }
    %orig;
}

%end

// 额外奖励回调 Hook（根据实际 App 调整）
%hook NSObject

- (void)rewardedAdUserDidEarnReward:(id)ad {
    NSLog(@"[奖励] 强制触发用户获得奖励");
    %orig;  // 或直接处理 App 内逻辑
}

%end

// =============================================
// 启动时额外处理
// =============================================
%ctor {
    %init;
    NSLog(@"[河马剧场去广告] 所有 Hook 初始化完成。广告已屏蔽，奖励自动获得！");
}
```

### 使用说明
1. **创建 Tweak 项目**：
   ```bash
   $THEOS/bin/nic.pl
   # 选择 "iphone/tweak" 模板
   ```

2. **放入文件**：将以上内容保存为 `Tweak.xm`，替换 `control` 和 `Makefile` 中的对应信息。

3. **编译安装**：
   ```bash
   make package install
   ```

4. **调试建议**：
   - 用 `NSLog` + Console.app 查看日志。
   - 用 `cycript` 或 `LLDB` 动态调试类名。
   - 对于 Swift 混编类，可能需 `%init` 指定类或使用 MSHookFunction。

**免责声明**：此代码为示例，仅用于学习逆向与 Theos 开发。实际使用中请确保不违反 App 服务条款或法律法规。不同 App 版本的 SDK 类/方法可能不同，需要针对性调整。 

如需针对特定类名的进一步优化，请提供 class-dump 结果，我可以帮忙细化 Hook。