#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/* Forward declarations for dynamically loaded classes */
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

/* Helper to restore subviews */
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        [sub setHidden:NO];
        [sub setAlpha:1.0];
        if (sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

/* Get key window */
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

/* Send callback to delegate if present */
static void dispatchDelegateCallback(id instance, SEL selector) {
    if (![instance respondsToSelector:selector]) return;
    id delegate = [instance performSelector:@selector(delegate)];
    if (!delegate) return;
    if ([delegate respondsToSelector:selector]) {
        [delegate performSelector:selector withObject:instance];
    }
}

%group AdBlocker

%ctor {
    Class GDTSplashAd = objc_getClass("GDTSplashAd");
    Class CSJSplashAd = objc_getClass("CSJSplashAd");
    Class BUSplashAdView = objc_getClass("BUSplashAdView");
    Class BaiduMobAdSplash = objc_getClass("BaiduMobAdSplash");
    Class KSAdSplashViewController = objc_getClass("KSAdSplashViewController");
    Class CMSplashManager = objc_getClass("CMSplashManager");
    Class CMSplashViewController = objc_getClass("CMSplashViewController");
    Class CMSplashAd = objc_getClass("CMSplashAd");
    Class BiddingSplashAd = objc_getClass("BiddingSplashAd");
    Class CMAdSplashView = objc_getClass("CMAdSplashView");
    Class GADAppOpenAd = objc_getClass("GADAppOpenAd");
    Class GADInterstitialAd = objc_getClass("GADInterstitialAd");
    Class PAGAppOpenAd = objc_getClass("PAGAppOpenAd");
    Class PAGInterstitialAd = objc_getClass("PAGInterstitialAd");

    /* Force cleanup of any existing splash windows */
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

%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"AdWindow"] ||
        [className containsString:@"PAGWindow"] || [className containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"AdWindow"] ||
        [className containsString:@"PAGWindow"] || [className containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"AdWindow"] ||
        [className containsString:@"PAGWindow"] || [className containsString:@"CSJWindow"]) {
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
    Class class = [self class];
    NSString *className = NSStringFromClass(class);
    if ([className containsString:@"Splash"] || [className containsString:@"Bidding"] ||
        [className containsString:@"AdViewController"] || [className containsString:@"CMAd"]) {
        UIView *vcView = ((UIViewController *)self).view;
        if (vcView) [vcView setHidden:YES];
        return;
    }
    %orig(animated);
}
- (void)viewDidAppear:(BOOL)animated {
    Class class = [self class];
    NSString *className = NSStringFromClass(class);
    if ([className containsString:@"Splash"] || [className containsString:@"Bidding"] ||
        [className containsString:@"AdViewController"] || [className containsString:@"CMAd"]) {
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
    return;
}
- (void)showAdInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
    return;
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
    return;
}
- (void)showAdInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
    return;
}
%end

%hook BUSplashAdView
- (void)loadAd {
    return;
}
- (void)showInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
    return;
}
%end

%hook BaiduMobAdSplash
- (void)loadAd {
    return;
}
- (void)showInWindow:(UIWindow *)window {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
    return;
}
%end

%hook KSAdSplashViewController
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
    return;
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
- (instancetype)init {
    return nil;
}
- (void)viewDidLoad {
    return;
}
%end

%hook CMSplashAd
- (void)loadAd {
    return;
}
- (void)show {
    dispatchDelegateCallback(self, @selector(splashAdClosed:));
    return;
}
%end

%hook BiddingSplashAd
- (instancetype)init {
    return nil;
}
%end

%hook CMAdSplashView
- (void)layoutSubviews {
    return;
}
- (void)didMoveToSuperview {
    return;
}
%end

%hook GADAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)viewController completionHandler:(void (^)(GADAdError * _Nullable))completionHandler {
    if (completionHandler) completionHandler(nil);
    return;
}
%end

%hook GADInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)viewController {
    return;
}
%end

%hook PAGAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)viewController {
    return;
}
%end

%hook PAGInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)viewController {
    return;
}
%end

%end