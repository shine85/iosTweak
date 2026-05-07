// Tweak.xm for 河马剧场 ad removal
// Target: Bypass Pangle, GDT, Baidu ad SDKs

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// Pangle related classes
%hook BUAdSDKManager
+ (instancetype)sharedInstance {
    NSLog(@"[HMJ Tweak] BUAdSDKManager sharedInstance blocked");
    return nil;
}

- (void)startWithAsyncCompletionHandler:(id)arg1 {
    NSLog(@"[HMJ Tweak] Blocked Pangle SDK initialization");
    // %orig; // Do not call original to prevent init
}

%end

// GDT (Tencent)
%hook GDTSDKConfig
+ (instancetype)sharedInstance {
    NSLog(@"[HMJ Tweak] GDTSDKConfig blocked");
    return nil;
}

%end

// Baidu
%hook BaiduMobAdSetting
+ (instancetype)sharedInstance {
    NSLog(@"[HMJ Tweak] BaiduMobAdSetting blocked");
    return nil;
}

%end

// Common ad view hiding
%hook UIView

- (void)didMoveToWindow {
    %orig;
    
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"BU"] || 
        [className containsString:@"GDT"] || 
        [className containsString:@"Baidu"] || 
        [className containsString:@"AdView"] || 
        [className containsString:@"Banner"] ||
        [className containsString:@"Interstitial"]) {
        
        NSLog(@"[HMJ Tweak] Hidden ad view: %@", className);
        self.hidden = YES;
        [self removeFromSuperview];
    }
}

- (void)layoutSubviews {
    %orig;
    
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Ad"] || [className containsString:@"Banner"]) {
        self.hidden = YES;
    }
}

%end

// Reward video auto success
%hook BURewardedVideoAd

- (void)rewardedVideoAdDidRewardUser:(id)arg1 reward:(id)arg2 {
    NSLog(@"[HMJ Tweak] Forced reward success for Pangle");
    // Call success callback if needed
    %orig;
}

- (BOOL)isReady {
    NSLog(@"[HMJ Tweak] Forced rewarded video ready");
    return YES;
}

%end

%hook GDTRewardedVideoAd

- (void)rewardedVideoAdDidRewardUser:(id)arg1 {
    NSLog(@"[HMJ Tweak] Forced GDT reward success");
    %orig;
}

%end

// Network request blocking for ad domains
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    NSString *urlString = request.URL.absoluteString;
    
    if ([urlString containsString:@"pangle.io"] || 
        [urlString containsString:@"ads"] || 
        [urlString containsString:@"gdt"] || 
        [urlString containsString:@"baidu"] ||
        [urlString containsString:@"ad"] ) {
        
        NSLog(@"[HMJ Tweak] Blocked ad network request: %@", urlString);
        
        if (completionHandler) {
            completionHandler(nil, nil, [NSError errorWithDomain:@"AdBlock" code:999 userInfo:nil]);
        }
        return nil;
    }
    
    return %orig;
}

%end

// Constructor - early injection
%ctor {
    NSLog(@"[HMJ Tweak] Constructor loaded for 河马剧场 ad removal");
    %init;
}
