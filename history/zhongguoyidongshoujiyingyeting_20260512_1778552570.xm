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
    for(UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
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
        [className containsString:@"CMAd"] || [className containsString:@"MobileAd"] ||
        [className containsString:@"CMSplash"] || [className containsString:@"ChinaMobile"] ||
        [className containsString:@"MobileHall"] || [className containsString:@"AdView"] ||
        [className containsString:@"CMSplash"]) {
        return YES;
    }
    CGRect screen = [UIScreen mainScreen].bounds;
    if (CGRectEqualToRect(view.frame, screen) && [className containsString:@"Ad"]) {
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
                         window.windowLevel >= UIWindowLevelNormal + 1;
        
        if (isAdWindow) {
            window.hidden = YES;
            [window.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
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

static void restoreMainUI() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWin = get_keyWindow();
        if (keyWin && keyWin.rootViewController && keyWin.rootViewController.view) {
            UIView *mainView = keyWin.rootViewController.view;
            forceRestoreSubViews(mainView);
            mainView.hidden = NO;
            mainView.alpha = 1.0;
            [mainView setNeedsLayout];
            [mainView layoutIfNeeded];
            aggressiveKillAdViews(mainView);
        }
        aggressiveKillAdWindows();
    });
}

static void killSplashWindow() {
    aggressiveKillAdWindows();
    restoreMainUI();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressiveKillAdWindows();
        restoreMainUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressiveKillAdWindows();
        restoreMainUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        aggressiveKillAdWindows();
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

%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    NSString *vcClass = NSStringFromClass([viewControllerToPresent class]);
    if ([vcClass containsString:@"Splash"] || [vcClass containsString:@"Ad"] || [vcClass containsString:@"Launch"] || 
        [vcClass containsString:@"GDTSplash"] || [vcClass containsString:@"CSJSplash"] || 
        [vcClass containsString:@"BU"] || [vcClass containsString:@"KSAd"] || [vcClass containsString:@"PAG"] ||
        [vcClass containsString:@"CM"] || [vcClass containsString:@"Mobile"] || [vcClass containsString:@"CMSplash"]) {
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
    }
}
%end

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          PAGSplashRequest=objc_getClass("PAGSplashRequest"));
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification 
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue] 
                                                  usingBlock:^(NSNotification *note) {
        killSplashWindow();
        restoreMainUI();
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        killSplashWindow();
        restoreMainUI();
    });
    
    NSLog(@"[AdHook] 中国移动手机营业厅去开屏广告 Tweak 已加载 - 强化无白屏版");
}