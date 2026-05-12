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

@interface CMSplashAd : NSObject
@end

@interface CMSplashManager : NSObject
@end

@interface CMAdSplashView : UIView
@end

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

static void forceRestoreSubViews(UIView *view) {
    if(!view) return;
    view.hidden = NO;
    view.alpha = 1.0;
    view.userInteractionEnabled = YES;
    [view setNeedsLayout];
    [view layoutIfNeeded];
    for(UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        sub.userInteractionEnabled = YES;
        [sub setNeedsLayout];
        [sub layoutIfNeeded];
        if(sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

static void notifyAdDismiss(id adObject) {
    if (!adObject) return;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([adObject respondsToSelector:@selector(delegate)]) {
        id delegate = [adObject performSelector:@selector(delegate)];
        if (delegate) {
            SEL selectors[] = {
                @selector(splashAdClosed:),
                @selector(splashAdDidDismiss:),
                @selector(splashAdDidDismissFullScreenContent:),
                @selector(splashAdDidClose:),
                @selector(splashDidDismissScreen:),
                @selector(splashAdViewDidDismissScreen:),
                nil
            };
            for (int i = 0; selectors[i] != nil; i++) {
                if ([delegate respondsToSelector:selectors[i]]) {
                    [delegate performSelector:selectors[i] withObject:adObject];
                    break;
                }
            }
        }
    }
#pragma clang diagnostic pop
}

static void killSplashWindow() {
    UIWindow *keyWin = get_keyWindow();
    for (UIWindow *window in [[UIApplication sharedApplication].windows copy]) {
        if (window == keyWin) continue;
        NSString *className = NSStringFromClass([window class]);
        BOOL isAdWindow = [className containsString:@"Splash"] || 
                         [className containsString:@"GDTSplash"] ||
                         [className containsString:@"CSJSplash"] ||
                         [className containsString:@"BUAd"] ||
                         [className containsString:@"KSAd"] ||
                         [className containsString:@"PAG"] ||
                         [className containsString:@"CMAd"] ||
                         window.windowLevel >= UIWindowLevelNormal + 1;
        
        if (isAdWindow) {
            window.hidden = YES;
            [window.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            if (window.rootViewController) {
                [window.rootViewController.view removeFromSuperview];
            }
            NSLog(@"[AdHook] Killed splash window: %@", className);
        }
    }
}

static void restoreMainUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWin = get_keyWindow();
        if (keyWin && keyWin.rootViewController) {
            UIViewController *rootVC = keyWin.rootViewController;
            UIView *mainView = rootVC.view;
            mainView.hidden = NO;
            mainView.alpha = 1.0;
            mainView.userInteractionEnabled = YES;
            forceRestoreSubViews(mainView);
            
            if ([rootVC isKindOfClass:[UITabBarController class]]) {
                UITabBarController *tab = (UITabBarController *)rootVC;
                tab.tabBar.hidden = NO;
                tab.tabBar.alpha = 1.0;
            }
        }
        killSplashWindow();
    });
}

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    NSLog(@"[AdHook] Blocked GDTSplashAd");
    notifyAdDismiss(self);
    killSplashWindow();
}

- (void)showAdInWindow:(UIWindow *)window {
    NSLog(@"[AdHook] Blocked GDTSplashAd show");
    notifyAdDismiss(self);
    killSplashWindow();
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    NSLog(@"[AdHook] Blocked CSJSplashAd");
    killSplashWindow();
}
%end

%hook BUSplashAdView
- (void)loadAdData {
    NSLog(@"[AdHook] Blocked BUSplashAdView");
    [(UIView *)self setHidden:YES];
    [self removeFromSuperview];
    notifyAdDismiss(self);
    killSplashWindow();
}
%end

%hook BaiduMobAdSplash
- (void)loadAd {
    NSLog(@"[AdHook] Blocked BaiduMobAdSplash");
    notifyAdDismiss(self);
    killSplashWindow();
}
%end

%hook KSAdSplashViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSLog(@"[AdHook] Blocked KSAdSplashViewController");
    [self dismissViewControllerAnimated:NO completion:nil];
    killSplashWindow();
}
%end

%hook PAGSplashAd
- (void)loadAd {
    NSLog(@"[AdHook] Blocked PAGSplashAd");
    killSplashWindow();
}
%end

%hook CMSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    NSLog(@"[AdHook] Blocked CMSplashAd");
    notifyAdDismiss(self);
    killSplashWindow();
}
%end

%hook CMSplashManager
- (void)showSplashAd {
    NSLog(@"[AdHook] Blocked CMSplashManager");
    killSplashWindow();
}
%end

%hook CMAdSplashView
- (void)loadAdData {
    NSLog(@"[AdHook] Blocked CMAdSplashView");
    [(UIView *)self setHidden:YES];
    [self removeFromSuperview];
    killSplashWindow();
}
%end

%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    NSString *vcClass = NSStringFromClass([viewControllerToPresent class]);
    if ([vcClass containsString:@"Splash"] || [vcClass containsString:@"GDTSplash"] || 
        [vcClass containsString:@"CSJSplash"] || [vcClass containsString:@"BU"] || 
        [vcClass containsString:@"KSAd"] || [vcClass containsString:@"PAG"] || 
        [vcClass containsString:@"CMSplash"] || [vcClass containsString:@"CMAd"]) {
        NSLog(@"[AdHook] Blocked present splash VC: %@", vcClass);
        notifyAdDismiss(viewControllerToPresent);
        killSplashWindow();
        if (completion) completion();
        return;
    }
    %orig;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *selfClass = NSStringFromClass([self class]);
    if ([selfClass containsString:@"Splash"] || [selfClass containsString:@"GDTSplash"] || 
        [selfClass containsString:@"CSJSplash"] || [selfClass containsString:@"CMSplash"] ||
        [selfClass containsString:@"CMAd"]) {
        NSLog(@"[AdHook] Detected splash VC: %@", selfClass);
        notifyAdDismiss(self);
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:NO completion:nil];
        } else {
            [[self view] removeFromSuperview];
        }
        killSplashWindow();
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            restoreMainUI();
        });
    }
}
%end

%hook UIApplication
- (void)setDelegate:(id)delegate {
    %orig;
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            killSplashWindow();
            restoreMainUI();
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            killSplashWindow();
            restoreMainUI();
        });
    }];
}
%end

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          PAGSplashAd=objc_getClass("PAGSplashAd"),
          CMSplashAd=objc_getClass("CMSplashAd"),
          CMSplashManager=objc_getClass("CMSplashManager"),
          CMAdSplashView=objc_getClass("CMAdSplashView"));
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
    });
    
    NSLog(@"[AdHook] 中国移动手机营业厅去开屏广告 Tweak 已加载 - 加强防白屏版");
}