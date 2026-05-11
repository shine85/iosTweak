#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
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

@interface GDTSplashAd : NSObject
@property (nonatomic, weak) id delegate;
@end

@interface CSJSplashAd : NSObject
@property (nonatomic, weak) id delegate;
@end

@interface BUSplashAdView : UIView
@property (nonatomic, weak) id delegate;
@end

@interface BaiduMobAdSplash : NSObject
@property (nonatomic, weak) id delegate;
@end

@interface KSAdSplashViewController : UIViewController
@end

@interface PAGSplashRequest : NSObject
@end

// 通用兜底
%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
}
%end

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || [className containsString:@"Launch"]) {
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:NO completion:nil];
        } else {
            [self.view removeFromSuperview];
        }
    }
}

%end

%hook GDTSplashAd

- (void)loadAdAndShowInWindow:(UIWindow *)window withBottomView:(UIView *)bottomView skipView:(UIView *)skipView {
    if ([self.delegate respondsToSelector:@selector(splashAdClosed:)]) {
        [self.delegate splashAdClosed:self];
    }
    if ([self.delegate respondsToSelector:@selector(splashAdDidDismissFullScreenContent:)]) {
        [self.delegate splashAdDidDismissFullScreenContent:self];
    }
    if (window) {
        window.hidden = YES;
    }
}

- (void)loadAdAndShowInWindow:(UIWindow *)window {
    if ([self.delegate respondsToSelector:@selector(splashAdClosed:)]) {
        [self.delegate splashAdClosed:self];
    }
    if (window) window.hidden = YES;
}

%end

%hook CSJSplashAd

- (void)loadAdAndShowInWindow:(id)window {
    if ([self.delegate respondsToSelector:@selector(splashAdClosed:)]) {
        [self.delegate splashAdClosed:self];
    }
    if ([self.delegate respondsToSelector:@selector(splashAdDidDismiss:)]) {
        [self.delegate splashAdDidDismiss:self];
    }
}

%end

%hook BUSplashAdView

- (void)loadAdData {
    self.hidden = YES;
    [self removeFromSuperview];
    if ([self.delegate respondsToSelector:@selector(splashAdDidClose:)]) {
        [self.delegate splashAdDidClose:self];
    }
}

%end

%hook BaiduMobAdSplash

- (void)load {
    if ([self.delegate respondsToSelector:@selector(splashDidDismissScreen:)]) {
        [self.delegate splashDidDismissScreen:self];
    }
}

%end

// 通用兜底 Window 处理
%ctor {
    // 动态初始化主流广告类(单次 %init)
    Class gdtClass = objc_getClass("GDTSplashAd");
    Class csjClass = objc_getClass("CSJSplashAd");
    Class buClass = objc_getClass("BUSplashAdView");
    Class baiduClass = objc_getClass("BaiduMobAdSplash");
    Class ksClass = objc_getClass("KSAdSplashViewController");
    Class pagClass = objc_getClass("PAGSplashRequest");
    
    %init(GDTSplashAd = gdtClass,
          CSJSplashAd = csjClass,
          BUSplashAdView = buClass,
          BaiduMobAdSplash = baiduClass,
          KSAdSplashViewController = ksClass,
          PAGSplashRequest = pagClass);
    
    // 通知监听兜底 + 防白屏
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            for (UIWindow *win in [UIApplication sharedApplication].windows) {
                NSString *winClass = NSStringFromClass([win class]);
                if ([winClass containsString:@"Splash"] || [winClass containsString:@"Ad"] || [winClass containsString:@"Launch"] || win.windowLevel >= UIWindowLevelAlert) {
                    win.hidden = YES;
                    if (win.rootViewController) {
                        [win.rootViewController.view removeFromSuperview];
                    }
                }
            }
            
            UIWindow *keyWin = get_keyWindow();
            if (keyWin && keyWin.rootViewController) {
                forceRestoreSubViews(keyWin.rootViewController.view);
            }
        });
    }];
}