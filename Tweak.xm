#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

@interface GDTSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)showAdInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface CSJSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)showAdInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface BUSplashAdView : NSObject
- (void)loadAndShowInWindow:(UIWindow *)window;
- (void)showInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface BaiduMobAdSplash : NSObject
- (void)loadAndShowInWindow:(UIWindow *)window;
- (void)showInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface KSAdSplashViewController : UIViewController
- (void)loadAndShowInWindow:(UIWindow *)window;
- (void)showInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface PAGSplashRequest : NSObject
- (void)loadAd;
@end

@interface CMSplashManager : NSObject
- (void)fetchSplashAd;
- (void)showSplashAdInWindow:(UIWindow *)window;
@end

@interface CMAdManager : NSObject
- (void)requestSplash;
@end

// ---------- empty implementations ----------
static void voidEmpty(id self, SEL _cmd) { }

static BOOL boolYES(id self, SEL _cmd) { return YES; }

static NSInteger intZero(id self, SEL _cmd) { return 0; }

static void replaceVoidMethod(Class cls, SEL sel) {
    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        MSHookMessageEx(cls, sel, (IMP)voidEmpty, NULL);
    }
}

static void replaceBOOLMethod(Class cls, SEL sel) {
    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        MSHookMessageEx(cls, sel, (IMP)boolYES, NULL);
    }
}

static void replaceIntMethod(Class cls, SEL sel) {
    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        MSHookMessageEx(cls, sel, (IMP)intZero, NULL);
    }
}

// ---------- specific class hooks ----------
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)showAdInWindow:(UIWindow *)window { }
- (void)loadAd { }
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)showAdInWindow:(UIWindow *)window { }
- (void)loadAd { }
%end

%hook BUSplashAdView
- (void)loadAndShowInWindow:(UIWindow *)window { }
- (void)showInWindow:(UIWindow *)window { }
- (void)loadAd { }
%end

%hook BaiduMobAdSplash
- (void)loadAndShowInWindow:(UIWindow *)window { }
- (void)showInWindow:(UIWindow *)window { }
- (void)loadAd { }
%end

%hook KSAdSplashViewController
- (void)loadAndShowInWindow:(UIWindow *)window { }
- (void)showInWindow:(UIWindow *)window { }
- (void)loadAd { }
%end

%hook PAGSplashRequest
- (void)loadAd { }
%end

%hook CMSplashManager
- (void)fetchSplashAd { }
- (void)showSplashAdInWindow:(UIWindow *)window { }
%end

%hook CMAdManager
- (void)requestSplash { }
%end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
        self.view.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook UIView
- (void)addSubview:(UIView *)view {
    NSString *cls = NSStringFromClass([view class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
        [view removeFromSuperview];
        return;
    }
    %orig;
}
%end

%ctor {
    @autoreleasepool {
        %init(GDTSplashAd = objc_getClass("GDTSplashAd"),
              CSJSplashAd = objc_getClass("CSJSplashAd"),
              BUSplashAdView = objc_getClass("BUSplashAdView"),
              BaiduMobAdSplash = objc_getClass("BaiduMobAdSplash"),
              KSAdSplashViewController = objc_getClass("KSAdSplashViewController"),
              PAGSplashRequest = objc_getClass("PAGSplashRequest"),
              CMSplashManager = objc_getClass("CMSplashManager"),
              CMAdManager = objc_getClass("CMAdManager"));

        // Generic method replacement for any class that may expose countdown or readiness APIs
        const char *runtimeClasses[] = {
            "PAGSplashRequest",
            "CMSplashManager",
            "CMAdManager",
            "GDTSplashAd",
            "CSJSplashAd",
            "BUSplashAdView",
            "BaiduMobAdSplash",
            "KSAdSplashViewController",
            NULL
        };
        const char *voidSelectors[] = {
            "startTimer",
            "setCountDown:",
            "updateCountdown:",
            "show",
            "display",
            NULL
        };
        const char *boolSelectors[] = {
            "isReady",
            "isValid",
            "hasAd",
            NULL
        };
        const char *intSelectors[] = {
            "remainingTime",
            "getCountDown",
            NULL
        };

        for (int i = 0; runtimeClasses[i] != NULL; i++) {
            Class cls = objc_getClass(runtimeClasses[i]);
            if (!cls) continue;

            for (int j = 0; voidSelectors[j] != NULL; j++) {
                SEL sel = sel_getUid(voidSelectors[j]);
                if (class_respondsToSelector(cls, sel)) {
                    replaceVoidMethod(cls, sel);
                }
            }
            for (int j = 0; boolSelectors[j] != NULL; j++) {
                SEL sel = sel_getUid(boolSelectors[j]);
                if (class_respondsToSelector(cls, sel)) {
                    replaceBOOLMethod(cls, sel);
                }
            }
            for (int j = 0; intSelectors[j] != NULL; j++) {
                SEL sel = sel_getUid(intSelectors[j]);
                if (class_respondsToSelector(cls, sel)) {
                    replaceIntMethod(cls, sel);
                }
            }
        }
    }
}
