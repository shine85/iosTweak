#import <UIKit/UIKit.h>
#import <substrate.h>

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
@property (nonatomic, weak) id delegate;
@end

@interface PAGSplashRequest : NSObject
@end

// 应用可能自定义类
@interface CMSplashViewController : UIViewController
@property (nonatomic, weak) id delegate;
@end

@interface CMSplashAd : NSObject
@property (nonatomic, weak) id delegate;
@end

// 通用辅助函数
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

static void forceRemoveSplashWindow() {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        NSString *className = NSStringFromClass([window class]);
        if ([className containsString:@"Splash"] || 
            [className containsString:@"Ad"] || 
            [className containsString:@"Launch"] ||
            window.windowLevel >= UIWindowLevelNormal + 1) {
            window.hidden = YES;
            [window.rootViewController.view removeFromSuperview];
            NSLog(@"[CMAdKiller] Removed splash window: %@", className);
        }
    }
}

static void notifyAdClosed(id adObject) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([adObject respondsToSelector:@selector(delegate)]) {
        id delegate = [adObject performSelector:@selector(delegate)];
        SEL selectors[] = {
            @selector(splashAdClosed:),
            @selector(splashAdDidDismiss:),
            @selector(splashAdDidDismissFullScreenContent:),
            @selector(splashAdDidClose:),
            @selector(splashDidDismissScreen:),
            @selector(splashAdDidDismissScreen:)
        };
        for (int i = 0; i < 6; i++) {
            if ([delegate respondsToSelector:selectors[i]]) {
                [delegate performSelector:selectors[i] withObject:adObject];
                NSLog(@"[CMAdKiller] Notified delegate with selector");
                break;
            }
        }
    }
#pragma clang diagnostic pop
}

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    NSLog(@"[CMAdKiller] Blocked GDTSplashAd loadAdAndShowInWindow");
    notifyAdClosed(self);
    if (window) window.hidden = NO;
}
- (void)showAdInWindow:(UIWindow *)window {
    NSLog(@"[CMAdKiller] Blocked GDTSplashAd showAdInWindow");
    notifyAdClosed(self);
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    NSLog(@"[CMAdKiller] Blocked CSJSplashAd");
    notifyAdClosed(self);
}
%end

%hook BUSplashAdView
- (instancetype)initWithSlotID:(id)slotID size:(CGSize)size rootViewController:(UIViewController *)rootViewController {
    NSLog(@"[CMAdKiller] Blocked BUSplashAdView init");
    return nil;
}
- (void)loadAdData {
    NSLog(@"[CMAdKiller] Blocked BUSplashAdView loadAdData");
}
%end

%hook BaiduMobAdSplash
- (void)loadAndShowInWindow:(UIWindow *)window {
    NSLog(@"[CMAdKiller] Blocked BaiduMobAdSplash");
    notifyAdClosed(self);
}
%end

%hook KSAdSplashViewController
- (void)loadAd {
    NSLog(@"[CMAdKiller] Blocked KSAdSplashViewController");
    [self dismissViewControllerAnimated:NO completion:nil];
}
%end

%hook PAGSplashRequest
- (instancetype)init {
    NSLog(@"[CMAdKiller] Blocked PAGSplashRequest");
    return nil;
}
%end

%hook CMSplashViewController
- (instancetype)init {
    NSLog(@"[CMAdKiller] Blocked CMSplashViewController init");
    return nil;
}
- (void)viewDidAppear:(BOOL)animated {
    NSLog(@"[CMAdKiller] Blocked CMSplashViewController viewDidAppear");
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    } else {
        [self.view removeFromSuperview];
    }
}
%end

%hook CMSplashAd
- (instancetype)init {
    NSLog(@"[CMAdKiller] Blocked CMSplashAd init");
    return nil;
}
%end

%hook UIApplication
- (void)setDelegate:(id)delegate {
    %orig;
    NSLog(@"[CMAdKiller] UIApplication delegate set, scheduling splash cleanup");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        forceRemoveSplashWindow();
    });
}
%end

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          PAGSplashRequest=objc_getClass("PAGSplashRequest"),
          CMSplashViewController=objc_getClass("CMSplashViewController"),
          CMSplashAd=objc_getClass("CMSplashAd"));
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification 
                                                      object:nil 
                                                       queue:nil 
                                                  usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            forceRemoveSplashWindow();
        });
    }];
    
    NSLog(@"[CMAdKiller] Tweak loaded for cn.10086.app");
}