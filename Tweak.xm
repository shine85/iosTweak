/* RemoveAds.xm
 * All hooks and helpers are written in English and compliant with Theos logs.
 */

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

/* Forward class declarations for unknown SDK classes */
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUSplashAd : NSObject @end
@interface KSAdSplashViewController : UIViewController @end
@interface BaiduMobAdSplash : NSObject @end
@interface GADFullScreenAd : NSObject @end
@interface PAGSplashViewController : UIViewController @end
@interface CMSplashManager : NSObject @end
@interface CMSplashViewController : UIViewController @end
@interface CMSplashAd : NSObject @end
@interface CMAdSplashView : UIView @end

/* Helper to notify delegate that the ad has closed */
static void notifyDelegateClosed(id self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self respondsToSelector:@selector(delegate)]) {
        id delegate = [self performSelector:@selector(delegate)];
        if ([delegate respondsToSelector:@selector(splashAdClosed:)]) {
            [delegate performSelector:@selector(splashAdClosed:) withObject:self];
        } else if ([delegate respondsToSelector:@selector(splashAdDidDismissFullScreenContent:)]) {
            [delegate performSelector:@selector(splashAdDidDismissFullScreenContent:) withObject:self];
        } else if ([delegate respondsToSelector:@selector(splashAdDidClose:)]) {
            [delegate performSelector:@selector(splashAdDidClose:) withObject:self];
        } else if ([delegate respondsToSelector:@selector(splashDidDismissScreen:)]) {
            [delegate performSelector:@selector(splashDidDismissScreen:) withObject:self];
        }
    }
#pragma clang diagnostic pop
    /* Hide the view or controller */
    if ([self isKindOfClass:[UIView class]]) {
        [(UIView *)self setHidden:YES];
    } else if ([self isKindOfClass:[UIViewController class]]) {
        [(UIViewController *)self view].hidden = YES;
    }
}

/* Force restore subviews utility */
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count) forceRestoreSubViews(sub);
    }
}

/* Safe key window fetcher */
static UIWindow *get_keyWindow(void) {
    UIWindow *foundWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *windowScene in [UIApplication sharedApplication].connectedScenes) {
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
    if (!foundWindow) foundWindow = [[UIApplication sharedApplication] valueForKey:@"keyWindow"];
    return foundWindow;
}

%ctor {
    /* Dynamic class loading and initialization */
    Class GDTSplashAd = objc_getClass("GDTSplashAd");
    Class CSJSplashAd = objc_getClass("CSJSplashAd");
    Class BUSplashAd = objc_getClass("BUSplashAd");
    Class KSAdSplashViewController = objc_getClass("KSAdSplashViewController");
    Class BaiduMobAdSplash = objc_getClass("BaiduMobAdSplash");
    Class GADFullScreenAd = objc_getClass("GADFullScreenAd");
    Class PAGSplashViewController = objc_getClass("PAGSplashViewController");
    Class CMSplashManager = objc_getClass("CMSplashManager");
    Class CMSplashViewController = objc_getClass("CMSplashViewController");
    Class CMSplashAd = objc_getClass("CMSplashAd");
    Class CMAdSplashView = objc_getClass("CMAdSplashView");
    %init(GDTSplashAd=GDTSplashAd, CSJSplashAd=CSJSplashAd, BUSplashAd=BUSplashAd, KSAdSplashViewController=KSAdSplashViewController, BaiduMobAdSplash=BaiduMobAdSplash, GADFullScreenAd=GADFullScreenAd, PAGSplashViewController=PAGSplashViewController, CMSplashManager=CMSplashManager, CMSplashViewController=CMSplashViewController, CMSplashAd=CMSplashAd, CMAdSplashView=CMAdSplashView);
}

/* ---------- SDK SPECIFIC HOOKS ---------- */

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    notifyDelegateClosed(self);
}
- (void)loadAd {
    notifyDelegateClosed(self);
}
- (instancetype)init {
    notifyDelegateClosed(self);
    return nil;
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window {
    notifyDelegateClosed(self);
}
- (void)loadAd {
    notifyDelegateClosed(self);
}
- (instancetype)init {
    notifyDelegateClosed(self);
    return nil;
}
%end

%hook BUSplashAd
- (instancetype)initWithFrame:(CGRect)frame {
    notifyDelegateClosed(self);
    return nil;
}
- (void)loadAd {
    notifyDelegateClosed(self);
}
%end

%hook KSAdSplashViewController
- (void)viewDidLoad {
    %orig;
    notifyDelegateClosed(self);
}
%end

%hook BaiduMobAdSplash
- (void)loadAd {
    notifyDelegateClosed(self);
}
%end

%hook GADFullScreenAd
- (void)presentFromRootViewController:(UIViewController *)rootViewController {
    notifyDelegateClosed(self);
}
%end

%hook PAGSplashViewController
- (void)viewDidLoad {
    %orig;
    notifyDelegateClosed(self);
}
%end

%hook CMSplashManager
- (instancetype)init {
    notifyDelegateClosed(self);
    return nil;
}
- (void)loadAd {
    notifyDelegateClosed(self);
}
%end

%hook CMSplashViewController
- (void)viewDidLoad {
    %orig;
    notifyDelegateClosed(self);
}
%end

%hook CMSplashAd
- (instancetype)init {
    notifyDelegateClosed(self);
    return nil;
}
- (void)loadAd {
    notifyDelegateClosed(self);
}
%end

%hook CMAdSplashView
- (instancetype)init {
    notifyDelegateClosed(self);
    return nil;
}
- (void)layoutSubviews {
    %orig;
    [(UIView *)self setHidden:YES];
}
%end

/* ---------- WINDOW BASIC INTERCEPTS ---------- */

%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"AdWindow"] ||
        [className containsString:@"PAGWindow"] || [className containsString:@"CSJWindow"]) {
        [(UIWindow *)self setHidden:YES];
        return;
    }
    %orig;
}
- (void)becomeKeyWindow {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"AdWindow"] ||
        [className containsString:@"PAGWindow"] || [className containsString:@"CSJWindow"]) {
        [(UIWindow *)self setHidden:YES];
        return;
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"Splash"] || [className containsString:@"AdWindow"] ||
        [className containsString:@"PAGWindow"] || [className containsString:@"CSJWindow"]) {
        %orig(YES);
        return;
    }
    %orig(hidden);
}
%end

/* ---------- VIEW CONTROLLER GLOBAL FALLBACK ---------- */

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    Class class = [self class];
    NSString *name = NSStringFromClass(class);
    if ([name containsString:@"Splash"] || [name containsString:@"AdViewController"] ||
        [name containsString:@"CMAd"]) {
        if (((UIViewController *)self).presentingViewController) {
            [((UIViewController *)self) dismissViewControllerAnimated:NO completion:nil];
        }
        if ([self isKindOfClass:[UIView class]]) {
            [(UIView *)self setHidden:YES];
        } else if ([self isKindOfClass:[UIViewController class]]) {
            ((UIViewController *)self view).hidden = YES;
        }
    }
}
%end