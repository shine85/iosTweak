#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

@interface UIViewController (AdHook)
@property (nonatomic, weak) id delegate;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIWindow *window;
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;
@end

@interface UIView (AdHook)
@property (nonatomic, strong) UIView *superview;
- (void)removeFromSuperview;
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
    for(UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if(sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
static void handleAdDismiss(id self) {
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self performSelector:@selector(delegate)];
        if (delegate) {
            SEL selectors[] = {
                @selector(splashAdClosed:),
                @selector(splashAdDidDismiss:),
                @selector(splashAdDidDismissFullScreenContent:),
                @selector(splashAdDidClose:),
                @selector(splashDidDismissScreen:),
                @selector(splashAdViewDidDismiss:),
                nil
            };
            for (int i = 0; selectors[i] != nil; i++) {
                if ([delegate respondsToSelector:selectors[i]]) {
                    [delegate performSelector:selectors[i] withObject:self];
                    break;
                }
            }
        }
    }
    if ([self isKindOfClass:[UIView class]]) {
        [(UIView *)self setHidden:YES];
        [(UIView *)self removeFromSuperview];
    } else if ([self isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)self;
        [vc.view setHidden:YES];
        if (vc.presentingViewController) {
            [vc dismissViewControllerAnimated:NO completion:nil];
        } else if (vc.view.superview) {
            [vc.view removeFromSuperview];
        }
    }
}
#pragma clang diagnostic pop

%hook GDTSplashAd
- (id)init { return nil; }
- (void)loadAdAndShowInWindow:(id)window withBottomView:(id)bottomView skipView:(id)skipView { handleAdDismiss(self); }
- (void)loadAdAndShowInWindow:(id)window { handleAdDismiss(self); }
%end

%hook CSJSplashAd
- (id)init { return nil; }
- (void)loadAdAndShowInWindow:(id)window { handleAdDismiss(self); }
%end

%hook BUSplashAdView
- (id)initWithSlotID:(id)slotID size:(CGSize)size { return nil; }
- (void)loadAdData { handleAdDismiss(self); }
%end

%hook BaiduMobAdSplash
- (id)init { return nil; }
- (void)load { handleAdDismiss(self); }
%end

%hook KSAdSplashViewController
- (id)init { return nil; }
- (void)loadAd { handleAdDismiss(self); }
%end

%hook PAGSplashRequest
- (id)init { return nil; }
%end

// 应用特定猜测类
%hook CMSplashManager
- (id)init { return nil; }
- (void)loadSplashAd { handleAdDismiss(self); }
%end

%hook CMSplashViewController
- (id)init { return nil; }
- (void)viewDidLoad { handleAdDismiss(self); }
%end

%hook CMSplashAd
- (id)init { return nil; }
%end

%hook BiddingSplashAd
- (id)init { return nil; }
%end

%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
}
%end

static void checkAndKillSplashWindows() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            NSString *className = NSStringFromClass([window class]);
            if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
                [className containsString:@"Launch"] || window.windowLevel >= UIWindowLevelNormal + 1) {
                if (window != get_keyWindow()) {
                    window.hidden = YES;
                    [window.rootViewController.view removeFromSuperview];
                    window.rootViewController = nil;
                }
            }
        }
    });
}

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          PAGSplashRequest=objc_getClass("PAGSplashRequest"),
          CMSplashManager=objc_getClass("CMSplashManager"),
          CMSplashViewController=objc_getClass("CMSplashViewController"),
          CMSplashAd=objc_getClass("CMSplashAd"),
          BiddingSplashAd=objc_getClass("BiddingSplashAd"));

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification 
                                                      object:nil 
                                                       queue:nil 
                                                  usingBlock:^(NSNotification *note) {
        checkAndKillSplashWindows();
    }];
}