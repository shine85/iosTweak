#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

/* ---------- 辅助函数 ---------- */
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        if (objc_getClass("UIView") && [sub isKindOfClass:objc_getClass("UIView")]) {
            [sub setHidden:NO];
            [sub setAlpha:1.0];
            if (sub.subviews.count) forceRestoreSubViews(sub);
        }
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
        foundWindow = [[UIApplication sharedApplication] valueForKey:@"keyWindow"];
    }
    return foundWindow;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-property-no-attribute"

/* ---------- 需要声明的未知类 ---------- */
@interface GDTSplashAd : NSObject @end
@interface GDTSplashAdView : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUSplashAdView : UIView @end
@interface BaiduMobAdSplash : UIView @end
@interface KSAdSplashViewController : UIViewController @end
@interface CMSplashViewController : UIViewController @end
@interface CMSplashAd : NSObject @end
@interface CFAdSplashViewController : UIViewController @end
@interface PAGSplashRequest : NSObject @end
@interface PAGSplashAd : NSObject @end
@interface PAGSplashViewController : UIViewController @end

/* ---------- Hook 逻辑 ---------- */
%ctor {
    /* 确保在类加载时立即激活Hook */
    /* 1. 开屏SDK全局拦截 */
    // 被 WebUI 自动过滤: 移除了未提供 %hook 的无意义 %init 赋值防报错
}

/* --- GDTSplashAd --- */
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    /* 阻断 */
}
- (void)showAdInWindow:(UIWindow *)window {
    /* 阻断 */
}
- (void)loadAd {
    /* 阻断 */
}
%end

/* --- CSJSplashAd --- */
%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    /* 阻断 */
}
- (void)showAdInWindow:(UIWindow *)window {
    /* 阻断 */
}
- (void)loadAd {
    /* 阻断 */
}
%end

/* --- BUSplashAdView --- */
%hook BUSplashAdView
- (instancetype)initWithFrame:(CGRect)frame {
    return nil;
}
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    /* 阻断 */
}
- (void)showAdInWindow:(UIWindow *)window {
    /* 阻断 */
}
%end

/* --- BaiduMobAdSplash --- */
%hook BaiduMobAdSplash
- (instancetype)init {
    return nil;
}
- (void)showInWindow:(UIWindow *)window {
    /* 阻断 */
}
%end

/* --- KSAdSplashViewController --- */
%hook KSAdSplashViewController
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [(UIViewController *)self.view setHidden:YES];
    /* 模拟广告关闭回调 */
    if ([self respondsToSelector:@selector(splashAdClosed:)]) {
        [self performSelector:@selector(splashAdClosed:) withObject:self];
    }
}
%end

/* --- CMSplashViewController --- */
%hook CMSplashViewController
- (instancetype)init {
    return nil;
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [(UIViewController *)self.view setHidden:YES];
    /* 触发可能的代理回调 */
    if ([self respondsToSelector:@selector(splashAdDidClose:)]) {
        [self performSelector:@selector(splashAdDidClose:) withObject:self];
    }
}
%end

/* --- CFAdSplashViewController --- */
%hook CFAdSplashViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return nil;
}
%end

/* --- PAGSplashViewController --- */
%hook PAGSplashViewController
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [(UIViewController *)self.view setHidden:YES];
    if ([self respondsToSelector:@selector(splashAdDidDismissScreen:)]) {
        [self performSelector:@selector(splashAdDidDismissScreen:) withObject:self];
    }
}
%end

/* --- PAGSplashRequest --- */
%hook PAGSplashRequest
- (void)loadAd {
    /* 阻断 */
}
%end

/* --- UIWindow 关键点兜底 --- */
%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"SplashWindow"] || [cls containsString:@"AdWindow"] ||
        [cls containsString:@"PAGWindow"] || [cls containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"SplashWindow"] || [cls containsString:@"AdWindow"] ||
        [cls containsString:@"PAGWindow"] || [cls containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"SplashWindow"] || [cls containsString:@"AdWindow"] ||
        [cls containsString:@"PAGWindow"] || [cls.containsString(@"CSJWindow")]) {
        %orig(YES);
        return;
    }
    %orig(hidden);
}
%end

/* --- UIViewController 兜底 --- */
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Bidding"] || [cls containsString:@"AdViewController"] || [cls containsString:@"CMAd"]) {
        [(UIView *)self setHidden:YES];
    }
    %orig(animated);
}
- (void)viewDidAppear:(BOOL)animated {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Bidding"] || [cls containsString:@"AdViewController"] || [cls containsString:@"CMAd"]) {
        [(UIView *)self setHidden:YES];
    }
    %orig(animated);
}
%end

#pragma clang diagnostic pop