#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

@interface UIView (AdHook)
@property (nonatomic, strong) id delegate;
@end

@interface UIViewController (AdHook)
@property (nonatomic, strong) id delegate;
@end

@interface GDTSplashAd : NSObject
@end

@interface CSJSplashAd : NSObject
@end

@interface BUSplashAdView : UIView
@end

@interface BaiduMobAdSplash : NSObject
@end

@interface KSAdSplashViewController : UIViewController
@end

@interface PAGSplashAd : NSObject
@end

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

static void killSplashWindow() {
    for (UIWindow *win in [UIApplication sharedApplication].windows) {
        NSString *className = NSStringFromClass([win class]);
        if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
            [className containsString:@"Launch"] || win.windowLevel >= UIWindowLevelNormal + 1) {
            win.hidden = YES;
            [win.rootViewController.view removeFromSuperview];
            [win resignKeyWindow];
        }
    }
}

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window withBottomView:(UIView *)bottomView skipView:(UIView *)skipView {
    %orig;
    if (window) {
        window.hidden = YES;
    }
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self performSelector:@selector(delegate)];
        if ([delegate respondsToSelector:@selector(splashAdClosed:)]) {
            [delegate performSelector:@selector(splashAdClosed:) withObject:self];
        } else if ([delegate respondsToSelector:@selector(splashAdDidDismissFullScreenContent:)]) {
            [delegate performSelector:@selector(splashAdDidDismissFullScreenContent:) withObject:self];
        }
    }
    #pragma clang diagnostic pop
    killSplashWindow();
}

- (void)showAdInWindow:(UIWindow *)window {
    if (window) window.hidden = YES;
    killSplashWindow();
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    killSplashWindow();
}
%end

%hook BUSplashAdView
- (void)loadAdData {
}
- (instancetype)initWithSlotID:(NSString *)slotID rootViewController:(UIViewController *)rootViewController {
    return nil;
}
%end

%hook BaiduMobAdSplash
- (void)load {
}
- (void)showInContainer:(UIView *)containerView {
    if (containerView) {
        [(UIView *)containerView setHidden:YES];
        [containerView removeFromSuperview];
    }
    killSplashWindow();
}
%end

%hook KSAdSplashViewController
- (void)viewDidAppear:(BOOL)animated {
    [self dismissViewControllerAnimated:NO completion:nil];
    killSplashWindow();
}
%end

%hook PAGSplashAd
- (void)loadAd {
}
%end

%hook UIApplication
- (void)setDelegate:(id)delegate {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            killSplashWindow();
        });
    }];
}
%end

%ctor {
    %init(GDTSplashAd = objc_getClass("GDTSplashAd"),
          CSJSplashAd = objc_getClass("CSJSplashAd"),
          BUSplashAdView = objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash = objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController = objc_getClass("KSAdSplashViewController"),
          PAGSplashAd = objc_getClass("PAGSplashAd"));
    
    // 通用兜底
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
    });
}