#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

@interface UIViewController (AdHook)
@property (nonatomic, weak) id delegate;
@end

@interface UIView (AdHook)
@end

@interface UIWindow (AdHook)
@end

// 主流广告 SDK 开屏类声明
@interface GDTSplashAd : NSObject
@property (nonatomic, weak) id delegate;
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)showAdInWindow:(UIWindow *)window;
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

// 应用可能特有类(基于常见命名推测)
@interface CMSplashManager : NSObject
@end

@interface CMSplashViewController : UIViewController
@property (nonatomic, weak) id delegate;
@end

@interface CMSplashAd : NSObject
@property (nonatomic, weak) id delegate;
@end

@interface BiddingSplashAd : NSObject
@property (nonatomic, weak) id delegate;
@end

static UIWindow* get_keyWindow(void) {
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

static void forceRemoveAdWindow(void) {
    for (UIWindow *win in [UIApplication sharedApplication].windows) {
        NSString *className = NSStringFromClass([win class]);
        if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
            [className containsString:@"Launch"] || win.windowLevel >= UIWindowLevelNormal + 1) {
            win.hidden = YES;
            [win.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
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
            @selector(splashAdViewDidClose:)
        };
        for (int i = 0; i < sizeof(selectors)/sizeof(SEL); i++) {
            if ([delegate respondsToSelector:selectors[i]]) {
                [delegate performSelector:selectors[i] withObject:adObject];
                break;
            }
        }
    }
#pragma clang diagnostic pop
}

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
- (void)showAdInWindow:(UIWindow *)window {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
%end

%hook BUSplashAdView
- (instancetype)initWithFrame:(CGRect)frame {
    return nil;
}
- (void)loadAdData {
    notifyAdClosed(self);
    forceRemoveAdWindow();
    [(UIView *)self setHidden:YES];
    [self removeFromSuperview];
}
%end

%hook BaiduMobAdSplash
- (void)loadAd {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
%end

%hook KSAdSplashViewController
- (void)viewDidAppear:(BOOL)animated {
    [self dismissViewControllerAnimated:NO completion:nil];
}
%end

%hook CMSplashManager
+ (instancetype)sharedInstance {
    return nil;
}
%end

%hook CMSplashViewController
- (instancetype)init {
    return nil;
}
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return nil;
}
- (void)viewDidLoad {
    [self dismissViewControllerAnimated:NO completion:nil];
}
%end

%hook CMSplashAd
- (instancetype)init {
    return nil;
}
%end

%hook BiddingSplashAd
- (instancetype)init {
    return nil;
}
%end

%hook PAGSplashRequest
- (instancetype)init {
    return nil;
}
%end

%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    NSString *vcClass = NSStringFromClass([viewControllerToPresent class]);
    if ([vcClass containsString:@"Splash"] || [vcClass containsString:@"Ad"]) {
        if (completion) completion();
        return;
    }
    %orig;
}
%end

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          CMSplashManager=objc_getClass("CMSplashManager"),
          CMSplashViewController=objc_getClass("CMSplashViewController"),
          CMSplashAd=objc_getClass("CMSplashAd"),
          BiddingSplashAd=objc_getClass("BiddingSplashAd"),
          PAGSplashRequest=objc_getClass("PAGSplashRequest"));
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            forceRemoveAdWindow();
        });
    }];
}