#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* ---------- 动态类声明 ---------- */
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUSplashAdView : NSObject @end
@interface BaiduMobAdSplash : NSObject @end
@interface KSAdSplashViewController : UIViewController @end
@interface CMSplashManager : NSObject @end
@interface CMSplashViewController : UIViewController @end
@interface CMSplashAd : UIView @end
@interface BiddingSplashAd : NSObject @end
@interface CMAdSplashView : UIView @end
@interface GADAppOpenAd : NSObject @end
@interface GADInterstitialAd : NSObject @end
@interface PAGAppOpenAd : NSObject @end
@interface PAGInterstitialAd : NSObject @end
@class GADAdError;     /* 前向声明 */

/* ---------- 公共工具函数 ---------- */
#pragma mark - 视图恢复
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        [sub setHidden:NO];
        [sub setAlpha:1.0];
        if (sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

#pragma mark - 获取 keyWindow
static UIWindow* get_keyWindow(void) {
    UIWindow *foundWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
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

#pragma mark - 统一委托回调
static void dispatchDelegateCallback(id instance, SEL selector) {
    if (![instance respondsToSelector:selector]) return;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id delegate = [instance performSelector:@selector(delegate)];
    if (!delegate) {
        #pragma clang diagnostic pop
        return;
    }
    const struct {
        SEL sel;
        const char *name;
    } callbacks[] = {
        {@selector(splashAdClosed:), "splashAdClosed:"},
        {@selector(splashAdDidDismissFullScreenContent:), "splashAdDidDismissFullScreenContent:"},
        {@selector(splashAdDidClose:), "splashAdDidClose:"},
        {@selector(splashDidDismissScreen:), "splashDidDismissScreen:"}
    };
    for (int i = 0; i < sizeof(callbacks)/sizeof(callbacks[0]); i++) {
        if ([delegate respondsToSelector:callbacks[i].sel]) {
            [delegate performSelector:callbacks[i].sel withObject:instance];
            break;
        }
    }
    #pragma clang diagnostic pop
}

#pragma mark - Ctor
%ctor {
    // 预先清理可能残留的开屏窗口，避免容错
    UIWindow *keyW = get_keyWindow();
    if (keyW) {
        for (UIWindow *win in keyW.windowScene.windows) {
            NSString *className = NSStringFromClass([win class]);
            if ([className containsString:@"Splash"] ||
                [className containsString:@"AdWindow"] ||
                [className containsString:@"PAGWindow"] ||
                [className containsString:@"CSJWindow"]) {
                [win setHidden:YES];
            }
        }
    }
}

/* ---------- Core Hook  ---------- */
%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] ||
        [className containsString:@"AdWindow"] ||
        [className containsString:@"PAGWindow"] ||
        [className containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] ||
        [className containsString:@"AdWindow"] ||
        [className containsString:@"PAGWindow"] ||
        [className containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] ||
        [className containsString:@"AdWindow"] ||
        [className containsString:@"PAGWindow"] ||
        [className containsString:@"CSJWindow"]) {
        if (!hidden) {
            %orig(YES);
            return;
        }
    }
    %orig(hidden);
}
%end

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    Class klass = [self class];
    NSString *className = NSStringFromClass(klass);
    if ([className containsString:@"Splash"] ||
        [className containsString:@"Bidding"] ||
        [className containsString:@"AdViewController"] ||
        [className containsString:@"CMAd"]) {
        UIView *vcView = ((UIViewController *)self).view;
        if (vcView) [vcView setHidden:YES];
        return;
    }
    %orig(animated);
}
- (void)viewDidAppear:(BOOL)animated {
    Class klass = [self class];
    NSString *className = NSStringFromClass(klass);
    if ([className containsString:@"Splash"] ||
        [className containsString:@"Bidding"] ||
        [className containsString:@"AdViewController"] ||
        [className containsString:@"CMAd"]) {
        UIView *vcView = ((UIViewController *)self).view;
        if (vcView) [vcView setHidden:YES];
        return;
    }
    %orig(animated);
}
%end

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
}
- (void)showAdInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
}
- (void)showAdInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
}
%end

%hook BUSplashAdView
- (void)loadAd { }
- (void)showInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
}
%end

%hook BaiduMobAdSplash
- (void)loadAd { }
- (void)showInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
}
%end

%hook KSAdSplashViewController
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
}
%end

%hook CMSplashManager
- (instancetype)init {
    return nil;
}
%end

%hook CMSplashViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return nil;
}
- (instancetype)init { return nil; }
- (void)viewDidLoad { }
%end

%hook CMSplashAd
- (void)loadAd { }
- (void)show { dispatchDelegateCallback(self, @selector(splashAdClosed:)); }
%end

%hook BiddingSplashAd
- (instancetype)init { return nil; }
%end

%hook CMAdSplashView
- (void)layoutSubviews { }
- (void)didMoveToSuperview { }
%end

%hook GADAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)viewController completionHandler:(void (^)(GADAdError * _Nullable))completionHandler {
    if (completionHandler) completionHandler(nil);
}
%end

%hook GADInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook PAGAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook PAGInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end