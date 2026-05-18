#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/* Auxiliary function – restores hidden subviews that might be suppressed */
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

/* ────────────────────────────────────────────────────────────────────────*/
/*   1.  Class declarations – avoid “no known instance method” errors         */
/* ────────────────────────────────────────────────────────────────────────*/
@interface GDTSplashAd : NSObject @end
@interface GDTUnifiedInterstitialAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface CSJInterstitialAd : NSObject @end
@interface BUSplashAdView : NSObject @end
@interface BUInterstitialAd : NSObject @end
@interface BaiduMobAdSplash : NSObject @end
@interface BaiduMobAdInterstitial : NSObject @end
@interface KSAdSplashViewController : NSObject @end
@interface KSInterstitialAd : NSObject @end
@interface KSAdInterstitialViewController : NSObject @end
@interface GADBannerView : NSObject @end
@interface GADInterstitialAd : NSObject @end
@interface GADFullScreenContent : NSObject @end
@interface PAGSplashAd : NSObject @end
@interface SigmobSplashAd : NSObject @end
@interface MintegralSplashAd : NSObject @end

/* ────────────────────────────────────────────────────────────────────────*/
/*   2.  Splash ad hooks                                                    */
/* ────────────────────────────────────────────────────────────────────────*/
%group AdBlockSplash
%hook GDTSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook CSJSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook BUSplashAdView
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook BaiduMobAdSplash
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook KSAdSplashViewController
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook PAGSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook SigmobSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%hook MintegralSplashAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
%end
%end

/* ────────────────────────────────────────────────────────────────────────*/
/*   3.  Interstitial / Popup hooks                                         */
/* ────────────────────────────────────────────────────────────────────────*/
%group AdBlockInterstitial
%hook GDTUnifiedInterstitialAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)presentFromViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {}
%end
%hook CSJInterstitialAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)presentFromViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {}
%end
%hook BUInterstitialAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)presentFromViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {}
%end
%hook BaiduMobAdInterstitial
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)presentFromViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {}
%end
%hook KSInterstitialAd
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)presentFromViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {}
%end
%hook KSAdInterstitialViewController
- (void)loadAd {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)presentFromViewController:(UIViewController *)vc animated:(BOOL)animated completion:(void (^)(void))completion {}
%end
%hook GADInterstitialAd
- (void)load {}
- (void)presentFromRootViewController:(UIViewController *)rootViewController {}
%end
%hook GADFullScreenContent
- (void)presentFromRootViewController:(UIViewController *)rootViewController {}
%end
%hook PAGInterstitialAd {}
%end
%hook SigmobInterstitialAd {}
%end
%hook MintegralInterstitialAd {}
%end
%end

/* ────────────────────────────────────────────────────────────────────────*/
/*   4.  Global window control – hide ad windows                            */
/* ────────────────────────────────────────────────────────────────────────*/
%group AdBlockWindow
%hook UIWindow
- (void)makeKeyAndVisible {}
- (void)becomeKeyWindow {}
- (void)setHidden:(BOOL)hidden {
    Class rootCls = [(UIViewController *)self rootViewController] ? [(UIViewController *)self rootViewController].class : nil;
    NSString *rootName = rootCls ? NSStringFromClass(rootCls) : @"";
    if ([rootName containsString:@"Splash"] ||
        [rootName containsString:@"Interstitial"] ||
        [rootName containsString:@"Ad"]) {
        [super setHidden:YES];
    } else {
        [super setHidden:hidden];
    }
}
%end
%end

/* ────────────────────────────────────────────────────────────────────────*/
/*   5.  Global view controller – dismiss ad view controllers automatically */
/* ────────────────────────────────────────────────────────────────────────*/
%group AdBlockVC
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    Class c = [self class];
    NSString *name = NSStringFromClass(c);
    if ([name containsString:@"Interstitial"] ||
        [name containsString:@"Popup"] ||
        [name containsString:@"Ad"] ||
        [name containsString:@"Splash"]) {
        // Dismiss with completion
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}
%end
%hook UINavigationController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    for (UIViewController *vc in self.viewControllers) {
        if ([NSStringFromClass([vc class]) containsString:@"Interstitial"] ||
            [NSStringFromClass([vc class]) containsString:@"Popup"] ||
            [NSStringFromClass([vc class]) containsString:@"Ad"] ||
            [NSStringFromClass([vc class]) containsString:@"Splash"]) {
            [vc dismissViewControllerAnimated:NO completion:nil];
        }
    }
}
%end
%end

/* ────────────────────────────────────────────────────────────────────────*/
/*   6.  Application launch – confirm injection                         */
/* ────────────────────────────────────────────────────────────────────────*/
%group AdBlockApplication
%hook UIApplication
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig;
    NSLog(@"[!!!] Tweak 注入成功");
}
%end
%end

/* ────────────────────────────────────────────────────────────────────────*/
/*   7.  Constructor – initialise all groups                             */
/* ────────────────────────────────────────────────────────────────────────*/
%ctor {
    %init(AdBlockSplash);
    %init(AdBlockInterstitial);
    %init(AdBlockWindow);
    %init(AdBlockVC);
    %init(AdBlockApplication);
}