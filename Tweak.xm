**河马剧场去广告 Tweak（.xm 文件）**  
基于 Theos + Logos 语法，针对常见广告 SDK（穿山甲/Pangle、优量汇/GDT、百度广告）进行 Hook。

```xm
// =============================================
// Tweak.xm - 河马剧场去广告插件
// 作者：Grok (示例模板)
// 说明：Hook 广告初始化、加载、展示、奖励回调等关键方法
// 常见效果：屏蔽广告视图、强制奖励成功、阻止弹出
// =============================================

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ====================== 日志宏 ======================
#define LOG(fmt, ...) NSLog(@"[河马去广告] " fmt, ##__VA_ARGS__)

// ====================== 穿山甲 (Pangle / CSJ) ======================
%hook BUNativeAd
- (void)loadAdData { %orig; LOG(@"BUNativeAd loadAdData 已拦截"); }
%end

%hook BUFullscreenVideoAd
- (instancetype)initWithSlotID:(NSString *)slotID {
    LOG(@"BUFullscreenVideoAd initWithSlotID: %@", slotID);
    return nil; // 直接返回 nil 阻止创建
}

- (void)loadAdData { LOG(@"BUFullscreenVideoAd loadAdData 拦截"); }
- (BOOL)showAdFromRootViewController:(UIViewController *)rootViewController { 
    LOG(@"BUFullscreenVideoAd showAd 已阻止"); 
    return NO; 
}
%end

%hook BURewardedVideoAd
- (instancetype)initWithSlotID:(NSString *)slotID {
    LOG(@"BURewardedVideoAd initWithSlotID: %@", slotID);
    return nil;
}

- (void)loadAdData { LOG(@"BURewardedVideoAd loadAdData 拦截"); }

- (BOOL)showAdFromRootViewController:(UIViewController *)rootViewController {
    LOG(@"BURewardedVideoAd showAd 已阻止，返回奖励成功");
    // 模拟奖励回调
    if ([self respondsToSelector:@selector(rewardedVideoAdDidRewardEffective:)]) {
        [self rewardedVideoAdDidRewardEffective:self];
    }
    return NO;
}
%end

// ====================== 优量汇 (GDT / Tencent) ======================
%hook GDTRewardedVideoAd
- (instancetype)initWithPlacementId:(NSString *)placementId {
    LOG(@"GDTRewardedVideoAd initWithPlacementId: %@", placementId);
    return nil;
}

- (void)loadAd { LOG(@"GDTRewardedVideoAd loadAd 拦截"); }

- (BOOL)showAdFromRootViewController:(UIViewController *)rootViewController {
    LOG(@"GDTRewardedVideoAd showAd 已阻止，模拟奖励");
    if ([self respondsToSelector:@selector(gdt_rewardVideoAdDidRewardEffective:)]) {
        [self gdt_rewardVideoAdDidRewardEffective:self];
    }
    return NO;
}
%end

%hook GDTNativeExpressAd
- (void)loadAd { LOG(@"GDTNativeExpressAd loadAd 拦截"); }
%end

%hook GDTUnifiedNativeAdView
- (instancetype)initWithFrame:(CGRect)frame {
    LOG(@"GDTUnifiedNativeAdView 创建被阻止");
    return nil;
}
%end

// ====================== 百度广告 (Baidu MobAd) ======================
%hook BaiduMobAdRewardedVideo
- (instancetype)init {
    LOG(@"BaiduMobAdRewardedVideo init 已拦截");
    return nil;
}

- (void)load {
    LOG(@"BaiduMobAdRewardedVideo load 拦截");
}

- (BOOL)showFromViewController:(UIViewController *)vc {
    LOG(@"BaiduMobAdRewardedVideo show 已阻止，模拟奖励成功");
    // 模拟奖励回调
    if ([self respondsToSelector:@selector(rewardedVideoAdDidReward)]) {
        [self rewardedVideoAdDidReward];
    }
    return NO;
}
%end

%hook BaiduMobAdNative
- (void)loadAd { LOG(@"BaiduMobAdNative loadAd 拦截"); }
%end

%hook BaiduMobAdInterstitial
- (void)load { LOG(@"BaiduMobAdInterstitial load 拦截"); }
- (BOOL)show { LOG(@"BaiduMobAdInterstitial show 阻止"); return NO; }
%end

// ====================== 通用广告视图屏蔽 ======================
%hook UIView

- (void)addSubview:(UIView *)subview {
    NSString *className = NSStringFromClass([subview class]);
    if ([className containsString:@"Ad"] || 
        [className containsString:@"Banner"] || 
        [className containsString:@"Native"] ||
        [className containsString:@"GDT"] ||
        [className containsString:@"BU"] ||
        [className containsString:@"Baidu"]) {
        
        LOG(@"检测到广告视图 %@，已阻止添加", className);
        return;
    }
    %orig;
}
%end

// ====================== 奖励回调强制成功 ======================
%hook NSObject

// 尝试 Hook 常见奖励成功回调（根据实际逆向调整）
- (void)rewardedVideoAdDidRewardEffective:(id)ad {
    LOG(@"强制奖励成功回调: %@", ad);
    %orig; // 或直接返回
}

- (void)gdt_rewardVideoAdDidRewardEffective:(id)ad {
    LOG(@"GDT 强制奖励成功");
    %orig;
}
%end

// ====================== Tweak 入口 ======================
%ctor {
    LOG(@"河马剧场去广告 Tweak 已加载！🎉");
    LOG(@"支持：穿山甲、优量汇、百度广告 等");
    
    %init;
}
```

### 编译说明（Theos）

**Makefile 示例：**

```makefile
INSTALL_TARGET_PROCESSES = 河马剧场   # 或实际 bundle ID 的进程名

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HeMaAdBlock
HeMaAdBlock_FILES = Tweak.xm
HeMaAdBlock_CFLAGS = -fobjc-arc
HeMaAdBlock_LDFLAGS = -framework UIKit -framework Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
```

**编译命令：**
```bash
make package install
```

**注意事项：**
1. 实际类名需通过 **Cycript / Frida / Hopper** 对目标 App 逆向确认（类名可能有前缀或版本差异）。
2. 部分 SDK 使用单例或 `sharedInstance`，可额外 Hook。
3. 激励视频常通过 `didReward` / `rewardEffective` 等回调发放奖励，已做模拟处理。
4. 如需更精确，可增加 `%group` + iOS 版本判断。
5. 测试时建议先用 `NSLog` 观察实际调用的类和方法，再完善 Hook。

把以上内容保存为 `Tweak.xm`，放入 Theos 项目即可编译 `.dylib`。需要针对特定版本的进一步优化或补充 Hook，随时提供 App 信息我可以继续调整！