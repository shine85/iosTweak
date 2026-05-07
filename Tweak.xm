#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook BUAdSDKManager
+ (instancetype)sharedInstance {
    return nil;
}

- (void)startWithAsyncCompletionHandler:(void (^)(BOOL))handler {
    if (handler) handler(YES);
}
%end

%hook GDTSDKConfig
+ (instancetype)sharedInstance {
    return nil;
}

+ (void)registerAppId:(NSString *)appId {
    // 阻止注册
}
%end

%hook BaiduMobAdSetting
+ (instancetype)sharedInstance {
    return nil;
}
%end

%hook PAGSDKManager
+ (instancetype)sharedInstance {
    return nil;
}

- (void)startWithAppId:(NSString *)appId completionHandler:(void (^)(BOOL))handler {
    if (handler) handler(YES);
}
%end

%hook PAGInterstitialAd
+ (void)loadAdWithRequest:(id)request completionHandler:(void (^)(id, NSError *))handler {
    if (handler) handler(nil, [NSError errorWithDomain:@"com.ads.block" code:404 userInfo:nil]);
}
%end

%hook PAGRewardedAd
+ (void)loadAdWithRequest:(id)request completionHandler:(void (^)(id, NSError *))handler {
    if (handler) handler(nil, [NSError errorWithDomain:@"com.ads.block" code:404 userInfo:nil]);
}
%end

%hook PAGRewardedAd
- (BOOL)showAdFromRootViewController:(UIViewController *)viewController {
    return NO;
}
%end

// 奖励视频自动达成
%hook PAGRewardedAd
- (void)rewardedAdDidRewardUser:(id)rewardedAd {
    if ([(id)self respondsToSelector:@selector(rewardedAdUserDidGainReward:)]) {
        [(id)self rewardedAdUserDidGainReward:rewardedAd];
    }
}
%end

// 针对开屏广告的更精确拦截(全屏/启动页特征)
%hook UIView
- (void)didMoveToWindow {
    %orig;
    
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || 
        [className containsString:@"Banner"] || 
        [className containsString:@"Interstitial"] || 
        [className containsString:@"PAG"] ||
        [className containsString:@"GDT"] ||
        [className containsString:@"Baidu"] ||
        [className containsString:@"Splash"] ||
        [className containsString:@"LaunchAd"]) {
        
        // 避免误伤打车主模块：仅隐藏明显广告尺寸或全屏启动广告
        CGRect frame = self.frame;
        BOOL isFullScreenAd = (frame.size.width >= [UIScreen mainScreen].bounds.size.width * 0.9 && 
                              frame.size.height >= [UIScreen mainScreen].bounds.size.height * 0.8);
        BOOL isBannerAd = (frame.size.height <= 120 && frame.size.width > frame.size.height * 2.5);
        
        if (isFullScreenAd || isBannerAd) {
            [self setHidden:YES];
            [self removeFromSuperview];
        }
    }
}

- (void)layoutSubviews {
    %orig;
    
    NSString *className = NSStringFromClass([self class]);
    CGRect frame = self.frame;
    
    // 严格尺寸判断 + 类名过滤，避免误挡打车模块内容视图
    BOOL isSmallBanner = (frame.size.height <= 100 && frame.size.width > frame.size.height * 3);
    BOOL isAdClass = ([className containsString:@"Ad"] || 
                     [className containsString:@"Banner"] || 
                     [className containsString:@"PAG"] ||
                     [className containsString:@"GDT"] ||
                     [className containsString:@"Baidu"] ||
                     [className containsString:@"Splash"]);
    
    if (isAdClass && isSmallBanner) {
        [self setHidden:YES];
        [self removeFromSuperview];
    }
}
%end

// 网络拦截 - 收窄范围，减少潜在副作用
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))handler {
    NSString *urlStr = request.URL.absoluteString.lowercaseString;
    if ([urlStr containsString:@"ads.pangle.io"] || 
        [urlStr containsString:@"gdt.qq.com"] || 
        [urlStr containsString:@"baidu.com/mobads"] || 
        [urlStr containsString:@"mobad"] ||
        [urlStr containsString:@"splash"] || 
        [urlStr containsString:@"launchad"]) {
        if (handler) {
            handler(nil, nil, [NSError errorWithDomain:@"com.ads.block" code:403 userInfo:nil]);
        }
        return nil;
    }
    return %orig;
}
%end

static __attribute__((constructor)) void init(void) {
    NSLog(@"[花小猪去广告] Tweak loaded successfully. Refined splash & main module protection.");
}
