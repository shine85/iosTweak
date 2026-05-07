// Tweak.xm
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// 广告 SDK
#import <BUAdSDK/BUAdSDKManager.h>
#import <PAGSDK/PAGRewardedAd.h>
#import <PAGSDK/PAGInterstitialAd.h>
#import <PAGSDK/PAGSDKManager.h>
#import <GDTSDK/GDTSDKConfig.h>
#import <BaiduMobAd/BaiduMobAdSetting.h>

// 如果有其他系统类
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIView.h>
#import <Foundation/NSURLSession.h>

%hook SomeViewController // 替换为你的目标类

// 假设你要监听 rewarded ad 的回调
- (void)someMethodToHandleAd {
    // 示例 rewardedAd 对象
    PAGRewardedAd *rewardedAd = ...; // 这里换成实际获取 rewardedAd 的方式
    
    // 安全调用回调方法
    if ([self respondsToSelector:@selector(rewardedAdUserDidGainReward:)]) {
        [self performSelector:@selector(rewardedAdUserDidGainReward:) withObject:rewardedAd];
    }
}

%end