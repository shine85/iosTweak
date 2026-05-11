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
            [className containsString:@"BaiduMobAd"] ||
            [className containsString:@"CMAd"] ||
            [className containsString:@"CMSplash"] ||
            [className containsString:@"Launch"] ||
            [className containsString:@"Advertising"]) {
            NSLog(@"[CMAdBlock] Aggressively removed splash view: %@", className);
            sub.hidden = YES;
            [sub removeFromSuperview];
        }
    }
    
    // 额外恢复主界面
    forceRestoreSubViews(keyWin);
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

// 中国移动特有类声明
@interface CMSplashManager : NSObject
@end

@interface CMAdManager : NSObject
@end

@interface CMLaunchAdView : UIView
@end

// 增强版视图控制器拦截
%hook UIViewController

- (void)viewDidLoad {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"] || [className containsString:@"Advertising"]) {
        NSLog(@"[CMAdBlock] Blocked splash-like VC in viewDidLoad: %@", className);
        [self dismissViewControllerAnimated:NO completion:nil];
        ((UIViewController *)self).view.hidden = YES;
        [((UIViewController *)self).view removeFromSuperview];
        return;
    }
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"] || [className containsString:@"Advertising"]) {
        NSLog(@"[CMAdBlock] Blocked splash-like VC in viewWillAppear: %@", className);
        [self dismissViewControllerAnimated:NO completion:nil];
        ((UIViewController *)self).view.hidden = YES;
        [((UIViewController *)self).view removeFromSuperview];
        return;
    }
    %orig;
}

- (void)viewDidAppear:(BOOL)animated {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"] || [className containsString:@"Advertising"]) {
        NSLog(@"[CMAdBlock] Blocked splash-like VC in viewDidAppear: %@", className);
        [self dismissViewControllerAnimated:NO completion:nil];
        ((UIViewController *)self).view.hidden = YES;
        [((UIViewController *)self).view removeFromSuperview];
        return;
    }
    %orig;
}

%end

// 广点通加强
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

// 穿山甲 / BUAdSDK
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
    [self dismissViewControllerAnimated:NO completion:nil];
    ((UIViewController *)self).view.hidden = YES;
    [((UIViewController *)self).view removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"[CMAdBlock] Blocked KSAdSplashViewController viewWillAppear");
    [self dismissViewControllerAnimated:NO completion:nil];
    ((UIViewController *)self).view.hidden = YES;
    [((UIViewController *)self).view removeFromSuperview];
}

%end

// Pangle
%hook PAGSplashRequest

- (instancetype)init {
    NSLog(@"[CMAdBlock] Blocked PAGSplashRequest init");
    return nil;
}

%end

// 中国移动特有加强
%hook CMSplashManager

- (void)showSplashAd {
    NSLog(@"[CMAdBlock] Blocked CMSplashManager showSplashAd");
}

- (void)loadSplashAd {
    NSLog(@"[CMAdBlock] Blocked CMSplashManager loadSplashAd");
}

%end

%hook CMAdManager

- (void)showLaunchAd {
    NSLog(@"[CMAdBlock] Blocked CMAdManager showLaunchAd");
}

%end

%hook CMLaunchAdView

- (void)show {
    NSLog(@"[CMAdBlock] Blocked CMLaunchAdView show");
    self.hidden = YES;
    [self removeFromSuperview];
}

%end

// 关键窗口拦截
%hook UIWindow

- (void)addSubview:(UIView *)view {
    NSString *className = NSStringFromClass([view class]);
    if ([className containsString:@"Splash"] || [className containsString:@"AdView"] || 
        [className containsString:@"GDTSplash"] || [className containsString:@"BUSplash"] ||
        [className containsString:@"CSJSplash"] || [className containsString:@"KSAd"] ||
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"] || [className containsString:@"CMLaunch"]) {
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
          PAGSplashRequest=objc_getClass("PAGSplashRequest"),
          CMSplashManager=objc_getClass("CMSplashManager"),
          CMAdManager=objc_getClass("CMAdManager"),
          CMLaunchAdView=objc_getClass("CMLaunchAdView"));
    
    // 多重延迟强杀 + 立即执行
    aggressivelyKillSplashViews();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
    });
    
    NSLog(@"[CMAdBlock] 中国移动营业厅去广告 Tweak 已加载 - 开屏强化修复版 (cn.10086.app)");
}