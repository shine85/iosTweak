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

// 广告SDK接口声明
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

@interface CMSplashAdManager : NSObject
@property (nonatomic, weak) id delegate;
@end

@interface CMAdSplashView : UIView
@end

@interface CMLaunchAdViewController : UIViewController
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
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || [className containsString:@"Launch"] || 
        [className containsString:@"CMSplash"] || [className containsString:@"CMAd"]) {
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

%hook CMSplashAdManager

- (void)loadAd {
    if ([self.delegate respondsToSelector:@selector(splashAdClosed:)]) {
        [self.delegate splashAdClosed:self];
    }
}

- (void)showInWindow:(UIWindow *)window {
    if (window) window.hidden = YES;
}

%end

%hook CMAdSplashView

- (void)show {
    self.hidden = YES;
    [self removeFromSuperview];
}

%end

%hook CMLaunchAdViewController

- (void)viewDidLoad {
    %orig;
    [self dismissViewControllerAnimated:NO completion:nil];
}

%end

// 通用兜底 Window 处理
%ctor {
    Class gdtClass = objc_getClass("GDTSplashAd");
    Class csjClass = objc_getClass("CSJSplashAd");
    Class buClass = objc_getClass("BUSplashAdView");
    Class baiduClass = objc_getClass("BaiduMobAdSplash");
    Class cmSplashClass = objc_getClass("CMSplashAdManager");
    Class cmAdViewClass = objc_getClass("CMAdSplashView");
    Class cmLaunchClass = objc_getClass("CMLaunchAdViewController");
    
    %init(GDTSplashAd = gdtClass,
          CSJSplashAd = csjClass,
          BUSplashAdView = buClass,
          BaiduMobAdSplash = baiduClass,
          CMSplashAdManager = cmSplashClass,
          CMAdSplashView = cmAdViewClass,
          CMLaunchAdViewController = cmLaunchClass);
    
    // 通知监听兜底 + 防白屏(针对中国移动加强)
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            for (UIWindow *win in [UIApplication sharedApplication].windows) {
                NSString *winClass = NSStringFromClass([win class]);
                if ([winClass containsString:@"Splash"] || [winClass containsString:@"Ad"] || 
                    [winClass containsString:@"Launch"] || [winClass containsString:@"CM"] ||
                    win.windowLevel >= UIWindowLevelAlert) {
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