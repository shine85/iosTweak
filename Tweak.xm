#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 防止简单 Hook 检测，使用 MSHookMessageEx
extern "C" void MSHookMessageEx(Class _class, SEL selector, IMP replacement, IMP *original);

// Pangle / GDT / Baidu 常见初始化类
%hook BUAdSDKManager
+ (instancetype)sharedInstance {
    return nil;
}
%end

%hook GDTSDKConfig
+ (instancetype)config {
    return nil;
}
%end

%hook BaiduMobAdSetting
+ (instancetype)sharedInstance {
    return nil;
}
%end

// 阻止广告展示
%hook BUNativeExpressAdView
- (void)didMoveToWindow {
    %orig;
    [self setHidden:YES];
    [self removeFromSuperview];
}
%end

%hook GDTNativeExpressAdView
- (void)didMoveToWindow {
    %orig;
    [self setHidden:YES];
    [self removeFromSuperview];
}
%end

// 奖励视频自动成功
%hook BURewardedVideoAd
- (void)rewardedVideoAdDidRewardUser:(BURewardedVideoAd *)rewardedVideoAd withReward:(BUReward *)reward {
    // 强制返回成功
    if ([self respondsToSelector:@selector(rewardedVideoAdDidRewardUser:withReward:)]) {
        // 调用原方法或直接模拟成功
    }
    NSLog(@"[HippoTweak] RewardedVideo 强制奖励成功");
}
%end

%hook GDTRewardedVideoAd
- (void)rewardedVideoAdDidRewardUser:(GDTRewardedVideoAd *)rewardedVideoAd {
    NSLog(@"[HippoTweak] GDT RewardedVideo 强制奖励成功");
}
%end

// 通用视图隐藏逻辑
%hook UIView
- (void)layoutSubviews {
    %orig;
    
    // 识别常见广告容器关键字
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || 
        [className containsString:@"Banner"] || 
        [className containsString:@"Native"] ||
        [className containsString:@"Pangle"] ||
        [className containsString:@"GDT"]) {
        [self setHidden:YES];
        [self removeFromSuperview];
    }
}
%end

// 网络层拦截广告请求
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlString = request.URL.absoluteString;
    if ([urlString containsString:@"ads.pangle.io"] ||
        [urlString containsString:@"gdt.qq.com"] ||
        [urlString containsString:@"mobads.baidu.com"] ||
        [urlString containsString:@"ad"] ) {
        NSLog(@"[HippoTweak] 拦截广告网络请求: %@", urlString);
        return nil;
    }
    return %orig;
}
%end

// 早期 Constructor 确保最先加载
static __attribute__((constructor)) void initialize() {
    NSLog(@"[HippoTweak] 河马剧场去广告 Tweak 已加载 - 启动早期拦截生效");
}
