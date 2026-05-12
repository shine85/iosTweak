#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

@interface UIView (Tweak)
@property (nonatomic, strong) id delegate;
@end

@interface UIViewController (Tweak)
@property (nonatomic, strong) id delegate;
@end

@interface GDTSplashAd : NSObject
@end

@interface BUSplashAd : NSObject
@end

@interface CSJSplashAd : NSObject
@end

@interface BaiduMobAdSplash : NSObject
@end

@interface KSAdSplashViewController : UIViewController
@end

@interface PAGSplashRequest : NSObject
@end

// 通用辅助函数 - 顶层定义
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

static void forceRemoveAdWindow() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            NSString *className = NSStringFromClass([window class]);
            if ([className containsString:@"Splash"] || [className containsString:@"Ad"] || 
                [className containsString:@"Launch"] || window.windowLevel >= UIWindowLevelNormal + 1) {
                if (window != get_keyWindow()) {
                    window.hidden = YES;
                    [window.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                }
            }
        }
    });
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
            @selector(splashDidDismissScreen:),
            @selector(splashAdDidClose:)
        };
        for (int i = 0; i < 5; i++) {
            if ([delegate respondsToSelector:selectors[i]]) {
                [delegate performSelector:selectors[i] withObject:adObject];
                break;
            }
        }
    }
#pragma clang diagnostic pop
}

// 通用兜底 - UIApplicationDidBecomeActive
%hook UIApplication
- (void)sendEvent:(UIEvent *)event {
    %orig;
}
%end

%ctor {
    %init;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification 
                                                      object:nil 
                                                       queue:[NSOperationQueue mainQueue] 
                                                  usingBlock:^(NSNotification *note) {
        forceRemoveAdWindow();
    }];
}

// 开屏 SDK Hook
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(id)window {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
- (void)showAdInWindow:(id)window {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
%end

%hook BUSplashAd
- (void)loadAdData {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
- (void)showSplashViewInRootViewController:(UIViewController *)viewController {
    notifyAdClosed(self);
    if (viewController.presentingViewController) {
        [viewController dismissViewControllerAnimated:NO completion:nil];
    }
    forceRemoveAdWindow();
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(id)window {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
%end

%hook BaiduMobAdSplash
- (void)load {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
- (void)showInContainer:(id)container {
    notifyAdClosed(self);
    forceRemoveAdWindow();
}
%end

%hook KSAdSplashViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    forceRemoveAdWindow();
}
%end

%hook PAGSplashRequest
- (instancetype)init {
    return nil;
}
%end

// 中国移动可能自定义类(基于常见命名推测，精准拦截)
%hook CMSplashManager
- (instancetype)init {
    return nil;
}
- (void)loadSplashAd {
    // 阻断加载
}
%end

%hook CMSplashViewController
- (void)viewDidLoad {
    %orig;
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    forceRemoveAdWindow();
}
- (instancetype)initWithNibName:(id)nib bundle:(id)bundle {
    return nil;
}
%end

%hook BiddingSplashAd
- (instancetype)init {
    return nil;
}
%end

// 通用视图层防护(仅限明确广告特征，防误杀)
%hook UIView
- (void)didMoveToWindow {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"AdView"] || 
        [className containsString:@"GDTSplash"] || [className containsString:@"BUSplash"] || 
        [className containsString:@"KSAd"]) {
        [(UIView *)self setHidden:YES];
        [self removeFromSuperview];
        forceRemoveAdWindow();
    }
}
%end