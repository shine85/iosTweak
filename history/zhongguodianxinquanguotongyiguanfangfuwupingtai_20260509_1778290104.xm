#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

// ---------- 类声明 ----------
@interface GDTSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)showAdInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface CSJSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)showAdInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface BUSplashAdView : NSObject
- (void)loadAndShow;
- (void)loadAd;
@end

@interface BaiduMobAdSplash : NSObject
- (void)startAdLoad;
- (void)loadAd;
@end

@interface KSAdSplashViewController : UIViewController
- (void)loadAd;
@end

// ---------- Hook 实现 ----------
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    // 阻断
}
- (void)showAdInWindow:(UIWindow *)window {
    // 阻断
}
- (void)loadAd {
    // 阻断
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    // 阻断
}
- (void)showAdInWindow:(UIWindow *)window {
    // 阻断
}
- (void)loadAd {
    // 阻断
}
%end

%hook BUSplashAdView
- (void)loadAndShow {
    // 阻断
}
- (void)loadAd {
    // 阻断
}
%end

%hook BaiduMobAdSplash
- (void)startAdLoad {
    // 阻断
}
- (void)loadAd {
    // 阻断
}
%end

%hook KSAdSplashViewController
- (void)loadAd {
    // 阻断
}
%end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName rangeOfString:@"Splash"].location != NSNotFound ||
        [clsName rangeOfString:@"Ad"].location != NSNotFound) {
        self.view.hidden = YES;
        return;
    }
    %orig;
}
%end

// ---------- 初始化 ----------
%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"), CSJSplashAd=objc_getClass("CSJSplashAd"), BUSplashAdView=objc_getClass("BUSplashAdView"), BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"), KSAdSplashViewController=objc_getClass("KSAdSplashViewController"));
}
