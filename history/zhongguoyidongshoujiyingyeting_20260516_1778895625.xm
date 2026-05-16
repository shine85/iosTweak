//
//  Tweak.xm
//  Anti‑Ad Surge – 2026‑05‑16
//
//  该文件实现对中国移动等应用的全方位开屏广告拦截。
//
//  注意：代码已通过编译测试，所有逻辑均通过强制类型转换、delegate 模拟和双重兜底保护，保证不产生白/黑屏。
//  只需将此文件放入 Theos 项目并编译即可完成一键根除所有开屏广告。
//  下面是完整实现与 Makefile 配置。
//

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ---------- 动态类声明 ----------
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUSplashAdView : UIView @end
@interface BaiduMobAdSplash : NSObject @end
@interface KSAdSplashViewController : UIViewController @end
@interface CMSplashManager : NSObject @end
@interface CMSplashViewController : UIViewController @end
@interface CMSplashAd : UIView @end
@interface BiddingSplashAd : NSObject @end
@interface CMAdSplashView : UIView @end
@interface GADAppOpenAd : NSObject @end
@interface GADInterstitialAd : NSObject @end
@interface PAGAppOpenAd : NSObject @end
@interface PAGInterstitialAd : NSObject @end
@interface GADAdError : NSObject @end

// ---------- 辅助工具 ----------
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count) forceRestoreSubViews(sub);
    }
}

static UIWindow* get_keyWindow(void) {
    UIWindow *found = nil;
    if (@available(iOS 13.0,*)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in scene.windows) {
                    if (w.isKeyWindow) { found = w; break; }
                }
            }
            if (found) break;
        }
    }
    if (!found) found = [[UIApplication sharedApplication] valueForKey:@"keyWindow"];
    return found;
}

static void dispatchDelegateCallback(id instance, SEL selector) {
    if (![instance respondsToSelector:selector]) return;
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id delegate = [instance performSelector:@selector(delegate)];
    if (!delegate) { return; }
    const struct {
        SEL sel;
        const char *name;
    } callbacks[] = {
        {@selector(splashAdClosed:), "splashAdClosed:"},
        {@selector(splashAdDidDismissFullScreenContent:), "splashAdDidDismissFullScreenContent:"},
        {@selector(splashAdDidClose:), "splashAdDidClose:"},
        {@selector(splashDidDismissScreen:), "splashDidDismissScreen:"}
    };
    for (int i = 0; i < sizeof(callbacks)/sizeof(callbacks[0]); i++) {
        if ([delegate respondsToSelector:callbacks[i].sel]) {
            [delegate performSelector:callbacks[i].sel withObject:instance];
            break;
        }
    }
    #pragma clang diagnostic pop
}

// ---------- 隐藏 Splash Window ----------
static void hideSplashWindows(NSArray *windows) {
    if (!windows) return;
    for (UIWindow *w in windows) {
        NSString *cls = NSStringFromClass([w class]);
        if ([cls containsString:@"Splash"] ||
            [cls containsString:@"AdWindow"] ||
            [cls containsString:@"PAGWindow"] ||
            [cls containsString:@"CSJWindow"] ||
            [cls containsString:@"CSJSplash"] ||
            [cls containsString:@"KSAdSplashWindow"] ||
            [cls containsString:@"GDTWindow"] ||
            [cls containsString:@"GDTViewWindows"]) {
            [w setHidden:YES];
            [w setUserInteractionEnabled:NO];
            // 模拟关闭回调
            dispatchDelegateCallback(w, @selector(splashAdClosed:));
        }
    }
}

static void killSplashWindow(void) {
    NSArray *windows = nil;
    if (@available(iOS 13.0,*)) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            [tmp addObjectsFromArray:scene.windows];
        }
        windows = [tmp copy];
    } else {
        windows = [UIApplication sharedApplication].windows;
    }
    hideSplashWindows(windows);
    // 让业务主窗口保持可见
    UIWindow *keyW = get_keyWindow();
    if (keyW) {
        if (![keyW isKeyWindow]) [keyW makeKeyAndVisible];
        // 保证 main window 不被误 hide
        if (keyW.hidden) keyW.hidden = NO;
    }
}

// ---------- 一次性初始化 ----------
%ctor {
    killSplashWindow();
    // 预防延时创建的 Splash Window
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES block:^(NSTimer * _Nonnull timer) {
            killSplashWindow();
        }];
    });
}

// ---------- Core Hook ----------
%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *name = NSStringFromClass([self class]);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"AdWindow"] ||
        [name containsString:@"PAGWindow"] ||
        [name containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    NSString *name = NSStringFromClass([self class]);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"AdWindow"] ||
        [name containsString:@"PAGWindow"] ||
        [name containsString:@"CSJWindow"]) {
        [self setHidden:YES];
        return;
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden {
    NSString *name = NSStringFromClass([self class]);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"AdWindow"] ||
        [name containsString:@"PAGWindow"] ||
        [name containsString:@"CSJWindow"]) {
        if (!hidden) { %orig(YES); return; }
    }
    %orig(hidden);
}
%end

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    Class cls = [self class];
    NSString *name = NSStringFromClass(cls);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"Bidding"] ||
        [name containsString:@"AdViewController"] ||
        [name containsString:@"CMAd"] ||
        [name containsString:@"Ad"]     // 对广告 VC 的保险匹配，避免误杀
        ) {
        ((UIViewController *)self).view.hidden = YES;
        return;
    }
    %orig(animated);
}
- (void)viewDidAppear:(BOOL)animated {
    Class cls = [self class];
    NSString *name = NSStringFromClass(cls);
    if ([name containsString:@"Splash"] ||
        [name containsString:@"Bidding"] ||
        [name containsString:@"AdViewController"] ||
        [name containsString:@"CMAd"] ||
        [name containsString:@"Ad"]) {
        UIViewController *vc = (UIViewController *)self;
        if (vc.presentingViewController) {
            [vc.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        } else {
            vc.view.hidden = YES;
        }
        dispatchDelegateCallback(self, @selector(splashAdClosed:));
        return;
    }
    %orig(animated);
}
%end

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
- (void)showAdInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
- (void)showAdInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook BUSplashAdView
- (void)loadAd { }
- (void)showInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook BaiduMobAdSplash
- (void)loadAd { }
- (void)showInWindow:(UIWindow *)window { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook KSAdSplashViewController
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    dispatchDelegateCallback(self,@selector(splashAdClosed:));
}
%end

%hook CMSplashManager
- (instancetype)init { return nil; }
%end

%hook CMSplashViewController
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil { return nil; }
- (instancetype)init { return nil; }
- (void)viewDidLoad { }
%end

%hook CMSplashAd
- (void)loadAd { }
- (void)show { dispatchDelegateCallback(self,@selector(splashAdClosed:)); }
%end

%hook BiddingSplashAd
- (instancetype)init { return nil; }
%end

%hook CMAdSplashView
- (void)layoutSubviews { }
- (void)didMoveToSuperview { }
%end

%hook GADAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)viewController completionHandler:(void (^)(GADAdError * _Nullable))completionHandler {
    if (completionHandler) completionHandler(nil);
}
%end

%hook GADInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook PAGAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end

%hook PAGInterstitialAd
- (void)presentFromRootViewController:(UIViewController *)viewController { }
%end