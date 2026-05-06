**河马剧场去广告 Tweak 分析与实现（Theos/Logos）**

### 深度分析策略总结
河马剧场作为典型短剧 App，重度集成主流广告 SDK（Pangle/穿山甲、GDT/广点通、百度广告等）。常见广告初始化入口包括：

- `Pangle` / `BUAdSDKManager`（穿山甲）
- `GDTSDKConfig` / `GDTUnifiedNativeAd` 等
- `BaiduMobAd` 系列
- 通用展示方法：`showAdInViewController:`、`presentAdFromRootViewController:`、`loadAd` / `show` 系列
- 奖励视频回调：`rewardedVideoAdDidRewardUser:`、`didRewardUserWithReward:` 等

去广告核心思路（KISS）：
1. 阻止 SDK 初始化或返回空单例。
2. 拦截展示方法，直接 return 或隐藏视图。
3. Hook 奖励视频回调，强制返回成功（跳过“看广告解锁”等待）。
4. 通用兜底：隐藏含广告关键词的 UIView 子视图。
5. 网络层拦截广告域名请求（可选增强）。

**前期确认类名推荐命令（Frida / Objection）**：
```bash
# Frida-trace 快速 trace 广告相关类
frida-trace -U -f com.xxx.hmjc -j "*[BUAdSDKManager *]" -j "*[GDTSDKConfig *]" -j "*[*Ad* show*]" -j "*[*Ad* present*]"

# Objection
objection -g com.xxx.hmjc explore
# 然后用：
android hooking list class_methods 'BUAdSDKManager'  # iOS 用类似命令或 frida
# 或直接 dump 内存：memory list modules | grep Ad
```

（实际替换 bundle ID 为河马剧场的真实 ID，通常为 `com.dz.hmjc` 或类似，可通过 `frida-ps -Uai` 查看）。

---

### 1. 完整的 Tweak.xm 代码

```objectivec
// Tweak.xm - 河马剧场去广告
// 作者：顶尖 iOS 逆向专家 | 遵循 KISS + 高可维护性

#import <UIKit/UIKit.h>
#import <substrate.h>  // 用于 MSHookMessageEx

// ==================== 宏定义 ====================
#define SAFE_HOOK(cls, sel, imp) \
    if (cls) MSHookMessageEx(cls, sel, (IMP)imp, NULL)

// 广告域名关键字（网络拦截兜底）
static NSArray *adDomains = @[@"pangle.io", @"gdt.qq.com", @"baidu.com/ad", @"mobad", @"ads."];

// ==================== Constructor 最早介入 ====================
%ctor {
    NSLog(@"[河马去广告] Tweak 加载成功 - Constructor 阶段");
    
    // 可在此处提前 Hook 关键单例
    Class pangle = NSClassFromString(@"BUAdSDKManager");
    if (pangle) {
        SAFE_HOOK(pangle, @selector(sharedInstance), (IMP)hook_BUAdSDKManager_sharedInstance);
    }
}

// ==================== 单例拦截 ====================
id hook_BUAdSDKManager_sharedInstance(id self, SEL _cmd) {
    NSLog(@"[河马去广告] 拦截 BUAdSDKManager sharedInstance");
    return nil;  // 返回 nil 阻止初始化
}

%hook BUAdSDKManager
+ (instancetype)sharedInstance {
    NSLog(@"[河马去广告] Hook BUAdSDKManager sharedInstance");
    return nil;
}
%end

%hook GDTSDKConfig
+ (void)registerAppId:(NSString *)appId {
    NSLog(@"[河马去广告] 阻止 GDT registerAppId: %@", appId);
    // 不调用 super，直接返回
}
%end

// ==================== 展示类广告拦截 ====================
%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    NSString *clsName = NSStringFromClass([viewControllerToPresent class]);
    if ([clsName containsString:@"Ad"] || [clsName containsString:@"Reward"] || [clsName containsString:@"Splash"]) {
        NSLog(@"[河马去广告] 阻止广告 VC present: %@", clsName);
        if (completion) completion();
        return;
    }
    %orig;
}
%end

// 通用展示方法
%hook NSObject
- (void)showAdInViewController:(id)vc {
    NSLog(@"[河马去广告] 拦截 showAdInViewController");
    // 什么都不做
}

- (void)presentAdFromRootViewController:(id)vc {
    NSLog(@"[河马去广告] 拦截 presentAdFromRootViewController");
}
%end

// ==================== 奖励视频自动达成 ====================
%hook NSObject
- (void)rewardedVideoAdDidRewardUser:(id)reward {
    NSLog(@"[河马去广告] 强制奖励视频成功回调");
    // 强制成功逻辑，根据实际 SDK 调整
    if ([self respondsToSelector:@selector(didRewardUserWithReward:)]) {
        [self didRewardUserWithReward:reward];
    }
}

- (BOOL)rewardedVideoAdDidRewardUserWithAmount:(NSInteger)amount {
    NSLog(@"[河马去广告] 强制返回奖励成功");
    return YES;
}
%end

// ==================== 视图隐藏（通用兜底） ====================
%hook UIView

- (void)didMoveToWindow {
    %orig;
    
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Ad"] || 
        [clsName containsString:@"Banner"] || 
        [clsName containsString:@"Native"] ||
        [self.subviews count] > 0) {  // 可进一步检查 frame 或 tag
        
        for (NSString *kw in adDomains) {
            if ([[self description] containsString:kw]) {
                NSLog(@"[河马去广告] 隐藏广告视图: %@", clsName);
                [self setHidden:YES];
                [self removeFromSuperview];
                return;
            }
        }
    }
}

- (void)layoutSubviews {
    %orig;
    // 可在此处额外检查尺寸（常见广告宽屏底部/全屏）
    if (self.frame.size.height > 50 && self.frame.size.width > self.superview.frame.size.width * 0.8) {
        NSString *cls = NSStringFromClass([self class]);
        if ([cls containsString:@"Ad"]) {
            [self setHidden:YES];
        }
    }
}
%end

// ==================== 网络请求拦截（增强） ====================
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler {
    NSString *urlStr = request.URL.absoluteString;
    for (NSString *kw in adDomains) {
        if ([urlStr containsString:kw]) {
            NSLog(@"[河马去广告] 拦截广告网络请求: %@", urlStr);
            if (handler) {
                handler(nil, nil, [NSError errorWithDomain:@"AdBlock" code:999 userInfo:nil]);
            }
            return nil;
        }
    }
    return %orig;
}
%end

// ==================== 防止检测（可选 MSHook） ====================
static void __attribute__((constructor)) initHooks() {
    // 使用 MSHookMessageEx 更隐蔽
    Class adCls = NSClassFromString(@"PAGRewardedAd"); // 示例
    if (adCls) {
        MSHookMessageEx(adCls, @selector(loadAdWithSlotID:request:completionHandler:), 
                       (IMP)hook_loadAd, NULL);
    }
}

id hook_loadAd(id self, SEL sel, id slot, id req, id completion) {
    NSLog(@"[河马去广告] 拦截 PAGRewardedAd loadAd");
    // 直接回调成功或返回
    if (completion) {
        void (^block)(id, NSError *) = completion;
        block(nil, nil);  // 模拟成功
    }
    return nil;
}
```

---

### 2. Makefile 配置

```makefile
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HMAdBlock
HMAdBlock_FILES = Tweak.xm
HMAdBlock_CFLAGS = -fobjc-arc
HMAdBlock_LDFLAGS += -framework UIKit -framework Foundation

# 目标进程（替换为实际 bundle ID）
INSTALL_TARGET_PROCESS = SpringBoard  # 或直接注入 App：com.dz.hmjc（推荐用 App 进程名）

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 '河马剧场' || true"  # 重启目标 App
```

**安装建议**：
- `make package install`
- 使用 `Theos` 标准环境，针对越狱设备。
- 若注入特定 App，可修改 `INSTALL_TARGET_PROCESS` 为 App 可执行文件名。

---

### 注意事项与维护性
- **高可维护**：所有关键逻辑使用日志 + 关键词数组，便于后续更新。
- **对抗检测**：优先使用 `%hook` + `MSHookMessageEx` + Constructor。
- **测试流程**：先用 Frida 确认具体类名（如 `PAGRewardedAd`、`GDTNativeExpressAdView` 等），再针对性加强 Hook。
- **法律声明**：本代码仅供学习与个人研究使用，请遵守相关法律法规与 App 服务条款。

需要针对特定版本进一步细化某个类名或添加更多 Hook，请提供 Frida dump 结果，我可以快速迭代代码。