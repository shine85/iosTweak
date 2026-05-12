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

@interface PAGSplashRequest : NSObject
@end

// 中国移动相关可能类
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
    if (CGRectIsEmpty(view.frame) || view.frame.size.width < 10) {
        view.frame = [UIScreen mainScreen].bounds;
    }
    [view setNeedsLayout];
    [view layoutIfNeeded];
    [view setNeedsDisplay];
    
    // 额外增强：确保背景不透明
    if ([view isKindOfClass:[UIView class]] && view.backgroundColor == nil) {
        view.backgroundColor = [UIColor whiteColor];
    }
    
    for(UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        sub.userInteractionEnabled = YES;
        if (CGRectIsEmpty(sub.frame) || sub.frame.size.width < 10) {
            sub.frame = view.bounds;
        }
        [sub setNeedsLayout];
        [sub layoutIfNeeded];
        [sub setNeedsDisplay];
        if(sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

static BOOL isLikelyAdView(UIView *view) {
    if (!view) return NO;
    NSString *className = NSStringFromClass([view class]);
    if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
        [className containsString:@"Launch"] || [className containsString:@"GDTSplash"] ||
        [className containsString:@"CSJSplash"] || [className containsString:@"BU"] ||
        [className containsString:@"KSAd"] || [className containsString:@"PAG"] ||
        [className containsString:@"CM"] || [className containsString:@"CMSplash"] ||
        [className containsString:@"MobileAd"] || [className containsString:@"MobileHall"] ||
        [className containsString:@"AdView"] || [className containsString:@"ChinaMobile"]) {
        return YES;
    }
    CGRect screen = [UIScreen mainScreen].bounds;
    if (CGRectEqualToRect(view.frame, screen) && ([className containsString:@"Ad"] || [className containsString:@"Splash"])) {
        return YES;
    }
    return NO;
}

static void aggressiveKillAdViews(UIView *rootView) {
    if (!rootView) return;
    for (UIView *sub in [rootView.subviews copy]) {
        if (isLikelyAdView(sub)) {
            sub.hidden = YES;
            [sub removeFromSuperview];
            NSLog(@"[AdHook] Aggressive killed ad subview: %@", NSStringFromClass([sub class]));
        } else if (sub.subviews.count > 0) {
            aggressiveKillAdViews(sub);
        }
    }
}

static void aggressiveKillAdWindows() {
    UIWindow *keyWin = get_keyWindow();
    for (UIWindow *window in [[UIApplication sharedApplication].windows copy]) {
        if (window == keyWin) continue;
        NSString *className = NSStringFromClass([window class]);
        BOOL isAdWindow = [className containsString:@"Splash"] || [className containsString:@"Ad"] || 
                         [className containsString:@"Launch"] || [className containsString:@"GDTSplash"] ||
                         [className containsString:@"CSJSplash"] || [className containsString:@"BUAd"] ||
                         [className containsString:@"KSAd"] || [className containsString:@"PAG"] ||
                         [className containsString:@"CM"] || [className containsString:@"CMSplash"] ||
                         [className containsString:@"MobileHall"] ||
                         window.windowLevel >= UIWindowLevelNormal + 1;
        
        if (isAdWindow) {
            window.hidden = YES;
            [window.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [window removeFromSuperview];
            NSLog(@"[AdHook] Killed splash window: %@", className);
        }
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
                @selector(splashAdDidClick:),
                nil
            };
            for (int i = 0; selectors[i] != nil; i++) {
                if ([delegate respondsToSelector:selectors[i]]) {
                    [delegate performSelector:selectors[i] withObject:adObject];
                    NSLog(@"[AdHook] Notified delegate dismiss for splash");
                    break;
                }
            }
        }
    }
#pragma clang diagnostic pop
}

static void forceShowMainContent() {
    UIWindow *keyWin = get_keyWindow();
    if (keyWin && keyWin.rootViewController) {
        UIViewController *rootVC = keyWin.rootViewController;
        UIView *mainView = rootVC.view;
        
        mainView.hidden = NO;
        mainView.alpha = 1.0;
        mainView.userInteractionEnabled = YES;
        mainView.frame = [UIScreen mainScreen].bounds;
        
        forceRestoreSubViews(mainView);
        aggressiveKillAdViews(mainView);
        
        // 重点强化 TabBar + 白屏修复
        if ([rootVC isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)rootVC;
            tab.tabBar.hidden = NO;
            tab.tabBar.alpha = 1.0;
            if (tab.selectedViewController && tab.selectedViewController.view) {
                UIView *contentView = tab.selectedViewController.view;
                contentView.hidden = NO;
                contentView.alpha = 1.0;
                contentView.frame = CGRectMake(0, 0, tab.view.bounds.size.width, tab.view.bounds.size.height - tab.tabBar.frame.size.height);
                forceRestoreSubViews(contentView);
            }
            for (UIViewController *vc in tab.viewControllers) {
                if (vc.view) {
                    forceRestoreSubViews(vc.view);
                }
            }
        } else if ([rootVC isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)rootVC;
            if (nav.visibleViewController && nav.visibleViewController.view) {
                forceRestoreSubViews(nav.visibleViewController.view);
            }
        }
        
        // 递归恢复所有子控制器视图
        for (UIViewController *child in rootVC.childViewControllers) {
            if (child.view) {
                forceRestoreSubViews(child.view);
            }
        }
        
        UIViewController *current = rootVC;
        while (current.presentedViewController) {
            current = current.presentedViewController;
            if (current.view) {
                forceRestoreSubViews(current.view);
            }
        }
        
        [mainView setNeedsLayout];
        [mainView layoutIfNeeded];
        [mainView setNeedsDisplay];
        
        NSLog(@"[AdHook] Force restored main content with enhanced tabbar fix");
    }
    
    // 全局遍历恢复
    for (UIWindow *win in [UIApplication sharedApplication].windows) {
        if (win.rootViewController && win.rootViewController.view) {
            forceRestoreSubViews(win.rootViewController.view);
        }
    }
}

static void restoreMainUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        forceShowMainContent();
        aggressiveKillAdWindows();
    });
}

static void killSplashWindow() {
    aggressiveKillAdWindows();
    restoreMainUI();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressiveKillAdWindows();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressiveKillAdWindows();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressiveKillAdWindows();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressiveKillAdWindows();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressiveKillAdWindows();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        forceShowMainContent();
        restoreMainUI();
    });
}

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    NSLog(@"[AdHook] Blocked GDTSplashAd loadAdAndShowInWindow");
    notifyAdDismiss(self);
    killSplashWindow();
}

- (void)showAdInWindow:(UIWindow *)window {
    NSLog(@"[AdHook] Blocked GDTSplashAd showAdInWindow");
    notifyAdDismiss(self);
    killSplashWindow();
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    NSLog(@"[AdHook] Blocked CSJSplashAd loadAdAndShowInWindow");
    notifyAdDismiss(self);
    killSplashWindow();
}
%end

%hook BUSplashAdView
- (void)loadAdData {
    NSLog(@"[AdHook] Blocked BUSplashAdView loadAdData");
    notifyAdDismiss(self);
    [(UIView *)self setHidden:YES];
    [self removeFromSuperview];
    killSplashWindow();
}
%end

%hook BaiduMobAdSplash
- (void)loadAd {
    NSLog(@"[AdHook] Blocked BaiduMobAdSplash loadAd");
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

%hook PAGSplashRequest
- (void)loadAd {
    NSLog(@"[AdHook] Blocked PAGSplashRequest");
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
    NSLog(@"[AdHook] Blocked CMSplashManager showSplashAd");
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
    if ([vcClass containsString:@"Splash"] || [vcClass containsString:@"Ad"] || [vcClass containsString:@"Launch"] || 
        [vcClass containsString:@"GDTSplash"] || [vcClass containsString:@"CSJSplash"] || 
        [vcClass containsString:@"BU"] || [vcClass containsString:@"KSAd"] || [vcClass containsString:@"PAG"] ||
        [vcClass containsString:@"CM"] || [vcClass containsString:@"CMSplash"] || [vcClass containsString:@"MobileHall"]) {
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
    if ([selfClass containsString:@"Splash"] || [selfClass containsString:@"Ad"] || 
        [selfClass containsString:@"Launch"] || [selfClass containsString:@"GDTSplash"] ||
        [selfClass containsString:@"CSJSplash"] || [selfClass containsString:@"CM"] || 
        [selfClass containsString:@"CMSplash"] || [selfClass containsString:@"MobileHall"]) {
        NSLog(@"[AdHook] Detected splash VC appear: %@", selfClass);
        notifyAdDismiss(self);
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:NO completion:nil];
        } else {
            [[self view] removeFromSuperview];
        }
        killSplashWindow();
    } else {
        if ([selfClass containsString:@"Main"] || [selfClass containsString:@"Home"] || 
            [selfClass containsString:@"Root"] || [selfClass containsString:@"Tab"] || 
            [selfClass containsString:@"Nav"] || [selfClass containsString:@"ViewController"]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                forceShowMainContent();
            });
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    NSString *selfClass = NSStringFromClass([self class]);
    if (![selfClass containsString:@"Splash"] && ![selfClass containsString:@"Ad"] && 
        ![selfClass containsString:@"Launch"] && ![selfClass containsString:@"GDTSplash"] &&
        ![selfClass containsString:@"CSJSplash"] && ![selfClass containsString:@"CM"] && 
        ![selfClass containsString:@"CMSplash"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            forceShowMainContent();
        });
    }
}
%end

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          PAGSplashRequest=objc_getClass("PAGSplashRequest"),
          CMSplashAd=objc_getClass("CMSplashAd"),
          CMSplashManager=objc_getClass("CMSplashManager"),
          CMAdSplashView=objc_getClass("CMAdSplashView"));
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification 
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue] 
                                                  usingBlock:^(NSNotification *note) {
        killSplashWindow();
        restoreMainUI();
        forceShowMainContent();
    }];
    
    // 针对只有底部导航栏的白屏问题加强恢复频率和深度
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
        forceShowMainContent();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        forceShowMainContent();
        restoreMainUI();
    });
    
    NSLog(@"[AdHook] 中国移动手机营业厅去开屏广告 Tweak 已加载 - 强化防白屏版 v5");
}