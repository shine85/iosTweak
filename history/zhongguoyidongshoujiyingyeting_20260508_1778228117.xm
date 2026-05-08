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
- (void)showAdInWindow:(UIWindow *)window;
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

/* Empty implementations */
static void voidEmpty(id self, SEL _cmd) { }
static BOOL boolYES(id self, SEL _cmd) { return YES; }
static NSInteger intZero(id self, SEL _cmd) { return 0; }

/* Replacement helpers */
static void replaceVoidMethod(Class cls, SEL sel) {
    Method m = class_getInstanceMethod(cls, sel);
    if (m) MSHookMessageEx(cls, sel, (IMP)voidEmpty, NULL);
}
static void replaceBOOLMethod(Class cls, SEL sel) {
    Method m = class_getInstanceMethod(cls, sel);
    if (m) MSHookMessageEx(cls, sel, (IMP)boolYES, NULL);
}
static void replaceIntMethod(Class cls, SEL sel) {
    Method m = class_getInstanceMethod(cls, sel);
    if (m) MSHookMessageEx(cls, sel, (IMP)intZero, NULL);
}

/* Specific class hooks */
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window) { }
- (void)showAdInWindow:(UIWindow *)window) { }
- (void)loadAd { }
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window) { }
- (void)showAdInWindow:(UIWindow *)window) { }
- (void)loadAd { }
%end

%hook BUSplashAdView
- (void)loadAndShowInWindow:(UIWindow *)window) { }
- (void)showInWindow:(UIWindow *)window) { }
- (void)loadAd { }
%end

%hook BaiduMobAdSplash
- (void)loadAndShowInWindow:(UIWindow *)window) { }
- (void)showInWindow:(UIWindow *)window) { }
- (void)loadAd { }
%end

%hook KSAdSplashViewController
- (void)loadAndShowInWindow:(UIWindow *)window) { }
- (void)showAdInWindow:(UIWindow *)window) { }
- (void)loadAd { }
%end

%hook PAGSplashRequest
- (void)loadAd { }
%end

%hook CMSplashManager
- (void)fetchSplashAd { }
- (void)showSplashAdInWindow:(UIWindow *)window) { }
%end

%hook CMAdManager
- (void)requestSplash { }
%end

/* View controller filtering */
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        self.view.hidden = YES;
        return;
    }
    %orig;
}
%end

/* Subview filtering */
%hook UIView
- (void)addSubview:(UIView *)view {
    NSString *clsName = NSStringFromClass([view class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        [view removeFromSuperview];
        return;
    }
    %orig;
}
%end

/* Reward video delegate auto‑reward */
%hook NSObject
- (void)rewardedVideoAdDidRewardUser:(id)ad {
    if ([self respondsToSelector:@selector(rewardUser)]) {
        ((void (*)(id, SEL))objc_msgSend)(self, @selector(rewardUser));
    }
    %orig;
}
%end

%ctor {
    @autoreleasepool {
        %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
              CSJSplashAd=objc_getClass("CSJSplashAd"),
              BUSplashAdView=objc_getClass("BUSplashAdView"),
              BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
              KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
              PAGSplashRequest=objc_getClass("PAGSplashRequest"),
              CMSplashManager=objc_getClass("CMSplashManager"),
              CMAdManager=objc_getClass("CMAdManager"));

        const char *targetClasses[] = {
            "GDTSplashAd", "CSJSplashAd", "BUSplashAdView",
            "BaiduMobAdSplash", "KSAdSplashViewController",
            "PAGSplashRequest", "CMSplashManager", "CMAdManager",
            NULL
        };
        const char *voidSels[] = {
            "startTimer", "setCountDown:", "updateCountdown:",
            "show", "display", NULL
        };
        const char *boolSels[] = {
            "isReady", "isValid", "hasAd", NULL
        };
        const char *intSels[] = {
            "remainingTime", "getCountDown", NULL
        };

        for (int i = 0; targetClasses[i] != NULL; i++) {
            Class cls = objc_getClass(targetClasses[i]);
            if (!cls) continue;

            for (int j = 0; voidSels[j] != NULL; j++) {
                SEL sel = sel_getUid(voidSels[j]);
                if (class_respondsToSelector(cls, sel)) replaceVoidMethod(cls, sel);
            }
            for (int j = 0; boolSels[j] != NULL; j++) {
                SEL sel = sel_getUid(boolSels[j]);
                if (class_respondsToSelector(cls, sel)) replaceBOOLMethod(cls, sel);
            }
            for (int j = 0; intSels[j] != NULL; j++) {
                SEL sel = sel_getUid(intSels[j]);
                if (class_respondsToSelector(cls, sel)) replaceIntMethod(cls, sel);
            }
        }
    }
}
