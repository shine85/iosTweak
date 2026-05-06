**根据要求，以下是针对“河马剧场”（包名 com.dz.hmjc）的去广告 Tweak 分析与实现。** 由于我无法实时动态分析特定版本的二进制文件，以下内容基于主流短剧 App 的常见广告 SDK 模式（Pangle/穿山甲、GDT/广点通、百度联盟等）进行通用化、高可维护设计。实际使用前建议用 Frida/Objection 确认类名。

### 前期类名确认命令（Frida / Objection）

```bash
# 1. Frida-trace 快速跟踪广告相关方法
frida-trace -U -f com.dz.hmjc -j "*Ad*[!init]*" -j "*Pangle*" -j "*GDT*" -j "*BUAdSDK*"

# 2. Objection 枚举常用广告类
objection -g com.dz.hmjc explore
# 在 objection shell 中执行：
android hooking list classes | grep -E "Pangle|GDT|BUAdSDK|Reward|AdView|Banner"
# 或 iOS 对应：
ios hooking list classes | grep -E "Pangle|GDT|BUAdSDK"

# 3. 针对奖励视频回调
frida-trace -U -f com.dz.hmjc -j "*reward*Did*Reward*" -j "*didRewardUser*"
```

重点观察 `BUAdSDKManager`、`GDTSDKConfig`、`PAGRewardedAd`、`GDTUnifiedNativeAd` 等类及其 `sharedInstance`、`loadAd`、`showAd`、`didReward` 等方法。

---

### Tweak.xm 完整代码（Theos/Logos）

```objective-c
// Tweak.xm
#import <UIKit/UIKit.h>
#import <substrate.h>

// ==================== 全局配置 ====================
static BOOL isAdEnabled = NO;  // 全局开关，强制关闭广告

// ==================== Constructor 最早介入 ====================
%ctor {
    NSLog(@"【河马剧场去广告】 Tweak 已加载 - Constructor");
    // 可在此处添加 anti-anti-hook 逻辑
    %init;
}

// ==================== SDK 初始化拦截 ====================
%hook BUAdSDKManager  // 穿山甲
+ (instancetype)sharedInstance {
    NSLog(@"【去广告】拦截 BUAdSDKManager sharedInstance");
    return nil;
}

+ (void)setupSDKWithAppId:(NSString *)appId {
    NSLog(@"【去广告】阻止 BUAdSDK 初始化: %@", appId);
    // 不调用原方法
}
%end

%hook GDTSDKConfig  // 广点通
+ (void)registerAppId:(NSString *)appId {
    NSLog(@"【去广告】阻止 GDTSDK 初始化");
}
%end

%hook BaiduMobAdSetting  // 百度
+ (instancetype)sharedInstance {
    return nil;
}
%end

// ==================== 奖励视频强制成功 ====================
%hook PAGRewardedAd  // Pangle 奖励视频
- (void)presentFromRootViewController:(UIViewController *)rootViewController {
    NSLog(@"【去广告】拦截 Pangle 奖励视频展示");
    // 不展示，直接模拟成功
    if ([self respondsToSelector:@selector(rewardedAdDidRewardUser)]) {
        [self rewardedAdDidRewardUser];
    }
}
%end

%hook GDTUnifiedNativeAd  // GDT 相关
- (void)presentAdFromRootViewController:(UIViewController *)rootViewController {
    NSLog(@"【去广告】拦截 GDT 广告展示");
}
%end

// ==================== 通用广告视图隐藏 ====================
%hook UIView
- (void)didMoveToWindow {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || 
        [className containsString:@"Banner"] || 
        [className containsString:@"Native"] || 
        [className containsString:@"Reward"]) {
        NSLog(@"【去广告】隐藏广告视图: %@", className);
        self.hidden = YES;
        [self removeFromSuperview];
    }
}

- (void)layoutSubviews {
    %orig;
    // 针对特定广告容器尺寸判断（可选增强）
    if (self.frame.size.height > 50 && self.frame.size.height < 150 && 
        [self.superview isKindOfClass:[UIScrollView class]] || [self.superview isKindOfClass:NSClassFromString(@"AdContainer")]) {
        self.hidden = YES;
    }
}
%end

// ==================== 网络请求拦截（广告域名） ====================
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler {
    NSString *url = request.URL.absoluteString;
    if ([url containsString:@"ads.pangle.io"] || 
        [url containsString:@"gdt"] || 
        [url containsString:@"baidu"] || 
        [url containsString:@"ad"] || 
        [url containsString:@"hmjc"] /* 河马特定 */) {
        NSLog(@"【去广告】拦截广告网络请求: %@", url);
        // 返回空数据
        if (handler) handler(nil, nil, [NSError errorWithDomain:@"AdBlock" code:999 userInfo:nil]);
        return nil;
    }
    return %orig;
}
%end

// ==================== 防止检测（可选 MSHookMessageEx） ====================
static void (*orig_setHidden)(id self, SEL _cmd, BOOL hidden);
static void hooked_setHidden(id self, SEL _cmd, BOOL hidden) {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"]) {
        hidden = YES;
    }
    orig_setHidden(self, _cmd, hidden);
}

// 在 ctor 中手动 hook
__attribute__((constructor)) static void initAntiDetect() {
    MSHookMessageEx([UIView class], @selector(setHidden:), (IMP)hooked_setHidden, (IMP *)&orig_setHidden);
}
```

---

### Makefile 配置

```makefile
# Makefile
TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard  # 或直接针对 com.dz.hmjc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HMAdKiller
HMAdKiller_FILES = Tweak.xm
HMAdKiller_CFLAGS = -fobjc-arc
HMAdKiller_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	@install_name_tool -change /usr/lib/libsubstrate.dylib /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/HMAdKiller.dylib || true
```

**编译命令**：
```bash
make package install
```

---

**使用说明与维护建议**（KISS 原则）：

1. 优先 Hook 初始化和展示方法，最稳定。
2. 视图隐藏作为兜底。
3. 网络拦截可根据实际抓包补充更多域名。
4. 若 App 更新导致类名变化，优先用 Frida 重新 trace。
5. 建议配合 PreferenceBundle 添加开关，避免全局强制。

此 Tweak 结构清晰、注释完整，便于后续维护。如需针对特定版本进一步细化（提供 ipa 或 class-dump 头文件），可补充信息后优化。测试时注意备份设备，避免 SpringBoard 卡死。