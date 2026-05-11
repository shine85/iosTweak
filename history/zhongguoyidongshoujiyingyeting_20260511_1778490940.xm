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
            [className containsString:@"Advertising"] ||
            [className containsString:@"CMLaunch"] ||
            [className containsString:@"AdContainer"] ||
            [className containsString:@"LaunchAd"]) {
            NSLog(@"[CMAdBlock] Aggressively removed splash view: %@", className);
            [sub setHidden:YES];
            [sub removeFromSuperview];
        }
    }
    
    forceRestoreSubViews(keyWin);
}

static void killAllAdSubviewsDeep(UIView *root) {
    if (!root) return;
    NSArray *subs = [root subviews];
    for (UIView *sub in subs) {
        NSString *cn = NSStringFromClass([sub class]);
        if ([cn containsString:@"Splash"] || [cn containsString:@"Ad"] || 
            [cn containsString:@"CMAd"] || [cn containsString:@"CMSplash"] ||
            [cn containsString:@"LaunchAd"] || [cn containsString:@"CMLaunch"] ||
            [cn containsString:@"Advertising"]) {
            NSLog(@"[CMAdBlock] Deep kill: %@", cn);
            [sub setHidden:YES];
            [sub removeFromSuperview];
            continue;
        }
        killAllAdSubviewsDeep(sub);
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

@interface CMSplashManager : NSObject
@end

@interface CMAdManager : NSObject
@end

@interface CMLaunchAdView : UIView
@end

@interface CMAdSplashView : UIView
@end

@interface CMLaunchAdController : UIViewController
@end

// 增强版视图控制器拦截
%hook UIViewController

- (void)viewDidLoad {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"] || [className containsString:@"Advertising"] ||
        [className containsString:@"CMLaunch"] || [className containsString:@"LaunchScreen"]) {
        NSLog(@"[CMAdBlock] Blocked splash-like VC in viewDidLoad: %@", className);
        if ([self presentingViewController]) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }
        [[self view] setHidden:YES];
        [[self view] removeFromSuperview];
        return;
    }
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"] || [className containsString:@"Advertising"] ||
        [className containsString:@"CMLaunch"] || [className containsString:@"LaunchScreen"]) {
        NSLog(@"[CMAdBlock] Blocked splash-like VC in viewWillAppear: %@", className);
        if ([self presentingViewController]) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }
        [[self view] setHidden:YES];
        [[self view] removeFromSuperview];
        return;
    }
    %orig;
}

- (void)viewDidAppear:(BOOL)animated {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"] || [className containsString:@"Advertising"] ||
        [className containsString:@"CMLaunch"] || [className containsString:@"LaunchScreen"]) {
        NSLog(@"[CMAdBlock] Blocked splash-like VC in viewDidAppear: %@", className);
        if ([self presentingViewController]) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }
        [[self view] setHidden:YES];
        [[self view] removeFromSuperview];
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
    [self removeFromSuperview];
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
    if ([self presentingViewController]) [self dismissViewControllerAnimated:NO completion:nil];
    [[self view] setHidden:YES];
    [[self view] removeFromSuperview];
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"[CMAdBlock] Blocked KSAdSplashViewController viewWillAppear");
    if ([self presentingViewController]) [self dismissViewControllerAnimated:NO completion:nil];
    [[self view] setHidden:YES];
    [[self view] removeFromSuperview];
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
    [self setHidden:YES];
    [self removeFromSuperview];
}

%end

%hook CMAdSplashView

- (void)show {
    NSLog(@"[CMAdBlock] Blocked CMAdSplashView show");
    [self setHidden:YES];
    [self removeFromSuperview];
}

%end

%hook CMLaunchAdController

- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"[CMAdBlock] Blocked CMLaunchAdController");
    if ([self presentingViewController]) [self dismissViewControllerAnimated:NO completion:nil];
    [[self view] setHidden:YES];
    [[self view] removeFromSuperview];
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
        [className containsString:@"LaunchAd"] || [className containsString:@"CMLaunch"] ||
        [className containsString:@"AdContainer"] || [className containsString:@"LaunchScreen"]) {
        NSLog(@"[CMAdBlock] Blocked addSubview of splash view: %@", className);
        return;
    }
    %orig;
}

%end

// 额外防护：拦截 present
%hook UIViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    NSString *className = NSStringFromClass([viewControllerToPresent class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"CMAd"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"LaunchAd"] || [className containsString:@"CMLaunch"] ||
        [className containsString:@"LaunchScreen"]) {
        NSLog(@"[CMAdBlock] Blocked present splash VC: %@", className);
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
          CMLaunchAdView=objc_getClass("CMLaunchAdView"),
          CMAdSplashView=objc_getClass("CMAdSplashView"),
          CMLaunchAdController=objc_getClass("CMLaunchAdController"));
    
    // 极致多重强杀 + 更密集的早期执行
    UIWindow *win = get_keyWindow();
    aggressivelyKillSplashViews();
    killAllAdSubviewsDeep(win);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
        killAllAdSubviewsDeep(get_keyWindow());
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
        killAllAdSubviewsDeep(get_keyWindow());
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
        killAllAdSubviewsDeep(get_keyWindow());
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
        killAllAdSubviewsDeep(get_keyWindow());
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressivelyKillSplashViews();
        killAllAdSubviewsDeep(get_keyWindow());
    });
    
    // 更高频兜底定时器(前10秒密集)
    [NSTimer scheduledTimerWithTimeInterval:0.8 repeats:YES block:^(NSTimer * _Nonnull timer) {
        UIWindow *w = get_keyWindow();
        if (w) {
            killAllAdSubviewsDeep(w);
            forceRestoreSubViews(w);
        }
    }];
    
    NSLog(@"[CMAdBlock] 中国移动营业厅去广告 Tweak 已加载 - 开屏终极强化版 v2 (cn.10086.app)");
}