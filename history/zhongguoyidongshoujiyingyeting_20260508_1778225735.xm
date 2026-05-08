#import <UIKit/UIKit.h>
#import <substrate.h>

/* ---------- Class Declarations ---------- */
@class GDTSplashAd;
@class CSJSplashAd;
@class BUSplashAdView;
@class BaiduMobAdSplash;
@class KSAdSplashViewController;
@class CMSplashManager;
@class CMAdManager;
@class PAGSplashRequest;

/* ---------- Helper Functions ---------- */
static void cleanAdViews(void) {
    UIApplication *app = [UIApplication sharedApplication];
    for (UIWindow *window in app.windows) {
        NSString *cls = NSStringFromClass([window class]);
        if ([cls containsString:@"Ad"] || [cls containsString:@"Splash"]) {
            window.hidden = YES;
        }
        for (UIView *v in window.subviews) {
            NSString *vcls = NSStringFromClass([v class]);
            if ([vcls containsString:@"Ad"] || [vcls containsString:@"Splash"]) {
                v.hidden = YES;
            }
        }
    }
}

/* ---------- GDTSplashAd ---------- */
%hook GDTSplashAd
- (instancetype)initWithPlacementId:(NSString *)placementId { return nil; }
- (void)loadAdAndShowInWindow:(UIWindow *)window {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)loadAd {}
%end

/* ---------- CSJSplashAd ---------- */
%hook CSJSplashAd
- (instancetype)initWithPlacementId:(NSString *)placementId { return nil; }
- (void)loadAdAndShowInWindow:(UIWindow *)window {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)loadAd {}
%end

/* ---------- BUSplashAdView ---------- */
%hook BUSplashAdView
- (instancetype)initWithAdUnitTag:(NSString *)tag { return nil; }
- (void)loadAdAndShowInWindow:(UIWindow *)window {}
- (void)showAdInWindow:(UIWindow *)window {}
- (void)loadAd {}
%end

/* ---------- BaiduMobAdSplash ---------- */
%hook BaiduMobAdSplash
- (instancetype)init { return nil; }
- (void)loadAndDisplay {}
- (void)loadAd {}
%end

/* ---------- KSAdSplashViewController ---------- */
%hook KSAdSplashViewController
- (instancetype)init { return nil; }
- (void)loadAndShowAd {}
%end

/* ---------- CMSplashManager (app specific) ---------- */
%hook CMSplashManager
- (void)requestSplashAd {}
- (void)showSplashAd {}
%end

/* ---------- CMAdManager (app specific) ---------- */
%hook CMAdManager
- (void)fetchSplash {}
- (void)presentSplash {}
%end

/* ---------- PAGSplashRequest (Pangle) ---------- */
%hook PAGSplashRequest
- (void)loadAd {}
%end

/* ---------- UIView ---------- */
%hook UIView
- (void)setHidden:(BOOL)hidden {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Ad"] || [cls containsString:@"Splash"]) {
        %orig(NO);
    } else {
        %orig;
    }
}
%end

/* ---------- UIViewController ---------- */
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
        self.view.hidden = YES;
        return;
    }
    for (UIView *sub in self.view.subviews) {
        NSString *subCls = NSStringFromClass([sub class]);
        if ([subCls containsString:@"Ad"] || [subCls containsString:@"Splash"]) {
            sub.hidden = YES;
        }
    }
    %orig;
}
%end

/* ---------- UIWindow ---------- */
%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Ad"] || [cls containsString:@"Splash"]) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

/* ---------- UIApplication ---------- */
%hook UIApplication
- (void)_setApplicationState:(int)state {
    %orig;
    // Clean after state change (e.g., after launch)
    cleanAdViews();
}
%end

/* ---------- Constructor ---------- */
%ctor {
    %init(GDTSplashAd = objc_getClass("GDTSplashAd"));
    %init(CSJSplashAd = objc_getClass("CSJSplashAd"));
    %init(BUSplashAdView = objc_getClass("BUSplashAdView"));
    %init(BaiduMobAdSplash = objc_getClass("BaiduMobAdSplash"));
    %init(KSAdSplashViewController = objc_getClass("KSAdSplashViewController"));
    %init(CMSplashManager = objc_getClass("CMSplashManager"));
    %init(CMAdManager = objc_getClass("CMAdManager"));
    %init(PAGSplashRequest = objc_getClass("PAGSplashRequest"));
    %init(UIViewController = objc_getClass("UIViewController"));
    %init(UIView = objc_getClass("UIView"));
    %init(UIWindow = objc_getClass("UIWindow"));
    %init(UIApplication = objc_getClass("UIApplication"));
    // Initial clean up
    cleanAdViews();
}
