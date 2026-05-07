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

// 系统类
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIView.h>
#import <Foundation/NSURLSession.h>

%hook SomeViewController  // 替换为你想 hook 的类

// Hook 示例方法
- (void)viewDidAppear:(BOOL)animated {
    %orig;  // 保留原有实现

    // 示例：获取 rewardedAd 对象
    PAGRewardedAd *rewardedAd = [[PAGRewardedAd alloc] init];
    
    // 安全调用回调方法
    if ([self respondsToSelector:@selector(rewardedAdUserDidGainReward:)]) {
        [self performSelector:@selector(rewardedAdUserDidGainReward:) withObject:rewardedAd];
    }
}

%end