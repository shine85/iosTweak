#import <UIKit/UIKit.h>
#import <substrate.h>

// ---------- 需要声明的广告相关类 ----------
@interface PAGSplashRequest : NSObject
- (void)load;
@end

@interface GDTSplashAd : NSObject
- (void)loadAd;
@end

@interface RewardVideoAd : NSObject
- (BOOL)isReady;
- (void)show;
@property (nonatomic, copy) void (^rewardCallback)(void);
@end

// ---------- 跳过开屏 ----------
%hook PAGSplashRequest
- (void)load {
    // 直接返回，阻止开屏加载
}
%end

%hook GDTSplashAd
- (void)loadAd {
    // 直接返回，阻止开屏加载
}
%end

// ---------- 强制奖励视频可用并自动回调 ----------
%hook RewardVideoAd
- (BOOL)isReady {
    // 把可用状态硬编码为 YES
    return YES;
}
- (void)show {
    // 直接触发奖励回调，模拟正常观看结束
    if (self.rewardCallback) {
        self.rewardCallback();
    }
    // 这里不调用原始实现，避免弹出真实视频
}
%end

// ---------- 在模块加载时尽早注入 ----------
%ctor {
    @autoreleasepool {
        // 可以在这里打印日志确认加载成功
        NSLog(@"[AdBypass] Tweak loaded");
    }
}
