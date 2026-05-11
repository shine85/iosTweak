#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

static UIWindow* get_keyWindow() {
    UIWindow *foundWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) {
            if (windowScene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        foundWindow = window;
                        break;
                    }
                }
            }
            if (foundWindow) break;
        }
    }
    if (!foundWindow) {
        foundWindow = [UIApplication sharedApplication].keyWindow;
    }
    return foundWindow;
}

static void aggressivelyKillSplashViews() {
    UIWindow *keyWin = get_keyWindow();
    if (!keyWin) return;
    
    for (UIView *sub in keyWin.subviews) {
        NSString *className = NSStringFromClass([sub class]);
        if ([className containsString:@"Splash"] || 
            [className containsString:@"AdView"] || 
            [className containsString:@"GDTSplash"] || 
            [className containsString:@"BUSplash"] || 
            [className containsString:@"CSJSplash"] || 
            [className containsString:@"KSAd"] ||
            [className containsString:@"PAG"] ||
            [className containsString:@"BaiduMobAd"]) {
            NSLog(@"[CMAdBlock] Aggressively removed splash view: %@", className);
            sub.hidden = YES;
            [sub removeFromSuperview];
        }
    }
}

@interface GDTSplashAd : NSObject
@end

@interface BUSplashAdView : UIView
@end

@interface CSJSplashAd : NSObject
@end

@interface BaiduMobAdSplash : NSObject
@end

@interface KSAdSplashViewController : UIViewController
@end

@interface PAGSplashRequest : NSObject
@end

// 增强版视图控制器拦截
%hook UIViewController

- (void)viewDidLoad {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"]) {
        NSLog(@"[CMAdBlock] Blocked splash-like VC in viewDidLoad: %@", className);
        self.view.hidden = YES;
        [self.view removeFromSuperview];
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"]) {
        NSLog(@"[CMAdBlock] Blocked splash-like VC in viewWillAppear: %@", className);
        self.view.hidden = YES;
        [self.view removeFromSuperview];
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    %orig;
}

- (void)viewDidAppear:(BOOL)animated {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"]) {
        NSLog(@"[CMAdBlock] Blocked splash-like VC in viewDidAppear: %@", className);
        self.view.hidden = YES;
        [self.view removeFromSuperview];
        [self dismissViewControllerAnimated:NO completion:nil];
        return;
    }
    %orig;
}

%end

// 广点通 Splash 加强拦截
%hook GDTSplashAd

- (void)loadAdAndShowInWindow:(UIWindow *)window withBottomView:(UIView *)bottomView skipView:(UIView *)skipView {
    NSLog(@"[CMAdBlock] Blocked GDTSplashAd loadAdAndShowInWindow (full)");
}

- (void)loadAdAndShowInWindow:(UIWindow *)window {
    NSLog(@"[CMAdBlock] Blocked GDTSplashAd loadAdAndShowInWindow");
}

- (void)showAdInWindow:(UIWindow *)window {
    NSLog(@"[CMAdBlock] Blocked GDTSplashAd showAdInWindow");
}

%end

// 穿山甲 / BUAdSDK 加强
%hook BUSplashAdView

- (instancetype)initWithSlotID:(NSString *)slotID rootViewController:(UIViewController *)rootViewController {
    NSLog(@"[CMAdBlock] Blocked BUSplashAdView init");
    return nil;
}

- (void)loadAdData {
    NSLog(@"[CMAdBlock] Blocked BUSplashAdView loadAdData");
}

- (void)showInWindow:(UIWindow *)window {
    NSLog(@"[CMAdBlock] Blocked BUSplashAdView showInWindow");
}

%end

%hook CSJSplashAd

- (void)loadAdData {
    NSLog(@"[CMAdBlock] Blocked CSJSplashAd loadAdData");
}

- (void)showAdInView:(UIView *)view {
    NSLog(@"[CMAdBlock] Blocked CSJSplashAd showAdInView");
}

%end

// 百度
%hook BaiduMobAdSplash

- (void)load {
    NSLog(@"[CMAdBlock] Blocked BaiduMobAdSplash load");
}

- (void)showInContainerView:(UIView *)view {
    NSLog(@"[CMAdBlock] Blocked BaiduMobAdSplash showInContainerView");
}

%end

// 快手
%hook KSAdSplashViewController

- (void)viewDidLoad {
    NSLog(@"[CMAdBlock] Blocked KSAdSplashViewController viewDidLoad");
    self.view.hidden = YES;
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"[CMAdBlock] Blocked KSAdSplashViewController viewWillAppear");
    self.view.hidden = YES;
    [self dismissViewControllerAnimated:NO completion:nil];
}

%end

// Pangle / 穿山甲新版
%hook PAGSplashRequest

- (instancetype)init {
    NSLog(@"[CMAdBlock] Blocked PAGSplashRequest init");
    return nil;
}

%end

// 应用自定义广告管理器加强拦截(针对中国移动)
%hook NSObject

+ (instancetype)alloc {
    NSString *className = NSStringFromClass(self);
    if ([className containsString:@"Splash"] || [className containsString:@"AdManager"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAdManager"] || [className containsString:@"MobAd"]) {
        NSLog(@"[CMAdBlock] Blocked custom splash/ad manager alloc: %@", className);
        return nil;
    }
    return %orig;
}

%end

// 关键窗口广告视图强杀
%hook UIWindow

- (void)addSubview:(UIView *)view {
    NSString *className = NSStringFromClass([view class]);
    if ([className containsString:@"Splash"] || [className containsString:@"AdView"] || 
        [className containsString:@"GDTSplash"] || [className containsString:@"BUSplash"] ||
        [className containsString:@"CSJSplash"] || [className containsString:@"KSAd"]) {
        NSLog(@"[CMAdBlock] Blocked addSubview of splash view: %@", className);
        return;
    }
    %orig;
}

%end

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          PAGSplashRequest=objc_getClass("PAGSplashRequest"));
    
    // 延迟多次执行强杀逻辑，确保开屏被彻底移除
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
    });
    
    NSLog(@"[CMAdBlock] 中国移动营业厅去广告 Tweak 已加载 - 加强开屏拦截版 (cn.10086.app)");
}