#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>
#import <objc/message.h>

// ---------- Forward declarations ----------
@class GDTSplashAd;
@class CSJSplashAd;
@class BUSplashAdView;
@class BaiduMobAdSplash;
@class KSAdSplashViewController;
@class CMSplashManager;
@class CMAdManager;
@class GDTRewardedVideoAd;
@class CSJRewardedVideoAd;
@class BUDRewardedVideoAd;

// ---------- Helper for safe hooking ----------
static inline void hookIfExists(Class cls, SEL sel, IMP newImp, IMP *orig) {
    if (cls && sel) {
        MSHookMessageEx(cls, sel, newImp, orig);
    }
}

// ---------- Empty splash implementations ----------
static void GDTSplashAd_loadAdAndShowInWindow(id self, SEL _cmd, UIWindow *window) { }
static void GDTSplashAd_showAdInWindow(id self, SEL _cmd, UIWindow *window) { }
static void GDTSplashAd_loadAd(id self, SEL _cmd) { }

static void CSJSplashAd_loadAdAndShowInWindow(id self, SEL _cmd, UIWindow *window) { }
static void CSJSplashAd_showAdInWindow(id self, SEL _cmd, UIWindow *window) { }
static void CSJSplashAd_loadAd(id self, SEL _cmd) { }

static void BUSplashAdView_loadAdAndShowInWindow(id self, SEL _cmd, UIWindow *window) { }
static void BUSplashAdView_showAdInWindow(id self, SEL _cmd, UIWindow *window) { }
static void BUSplashAdView_loadAd(id self, SEL _cmd) { }

static void BaiduMobAdSplash_loadAndShowInWindow(id self, SEL _cmd, UIWindow *window) { }
static void BaiduMobAdSplash_showInWindow(id self, SEL _cmd, UIWindow *window) { }
static void BaiduMobAdSplash_load(id self, SEL _cmd) { }

static void KSAdSplashViewController_loadSplashAd(id self, SEL _cmd) { }
static void KSAdSplashViewController_showSplashAd(id self, SEL _cmd) { }

static void CMSplashManager_requestSplashAd(id self, SEL _cmd) { }
static void CMSplashManager_displaySplashAd(id self, SEL _cmd) { }

static void CMAdManager_loadSplash(id self, SEL _cmd) { }
static void CMAdManager_showSplash(id self, SEL _cmd) { }

// ---------- Rewarded video hooks ----------
static NSInteger RewardVideo_remainingTime(id self, SEL _cmd) {
    return 3;
}

static void RewardVideo_rewardDidEarn(id self, SEL _cmd) {
    Ivar ivar = class_getInstanceVariable([self class], "_delegate");
    if (ivar) {
        id delegate = object_getIvar(self, ivar);
        if (delegate && [delegate respondsToSelector:@selector(rewardVideoAdDidRewardUser:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(delegate, @selector(rewardVideoAdDidRewardUser:), self);
        }
    }
}

// ---------- UI filtering ----------
static IMP orig_UIViewController_viewDidAppear = NULL;
static void UIViewController_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
        self.view.hidden = YES;
        return;
    }
    if (orig_UIViewController_viewDidAppear) {
        ((void (*)(id, SEL, BOOL))orig_UIViewController_viewDidAppear)(self, _cmd, animated);
    }
}

static IMP orig_UIView_addSubview = NULL;
static void UIView_addSubview(id self, SEL _cmd, UIView *subview) {
    NSString *cls = NSStringFromClass([subview class]);
    if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
        subview.hidden = YES;
        return;
    }
    if (orig_UIView_addSubview) {
        ((void (*)(id, SEL, UIView *))orig_UIView_addSubview)(self, _cmd, subview);
    }
}

// ---------- Network request blocker ----------
static IMP orig_NSURLSession_dataTaskWithRequest_completionHandler = NULL;
static NSURLSessionDataTask * NSURLSession_dataTaskWithRequest_completionHandler(id self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData *, NSURLResponse *, NSError *)) {
    NSString *urlStr = request.URL.absoluteString.lowercaseString;
    if ([urlStr containsString:@"ad"] || [urlStr containsString:@"splash"]) {
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(nil, nil, nil);
            });
        }
        return nil;
    }
    return ((NSURLSessionDataTask *(*)(id, SEL, NSURLRequest *, void (^)(NSData *, NSURLResponse *, NSError *)))orig_NSURLSession_dataTaskWithRequest_completionHandler)(self, _cmd, request, completionHandler);
}

// ---------- Empty %hook blocks for each class ----------
%hook GDTSplashAd
%end

%hook CSJSplashAd
%end

%hook BUSplashAdView
%end

%hook BaiduMobAdSplash
%end

%hook KSAdSplashViewController
%end

%hook CMSplashManager
%end

%hook CMAdManager
%end

%hook GDTRewardedVideoAd
%end

%hook CSJRewardedVideoAd
%end

%hook BUDRewardedVideoAd
%end

// ---------- Constructor ----------
%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"), CSJSplashAd=objc_getClass("CSJSplashAd"), BUSplashAdView=objc_getClass("BUSplashAdView"), BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"), KSAdSplashViewController=objc_getClass("KSAdSplashViewController"), CMSplashManager=objc_getClass("CMSplashManager"), CMAdManager=objc_getClass("CMAdManager"), GDTRewardedVideoAd=objc_getClass("GDTRewardedVideoAd"), CSJRewardedVideoAd=objc_getClass("CSJRewardedVideoAd"), BUDRewardedVideoAd=objc_getClass("BUDRewardedVideoAd"));
    
    hookIfExists(GDTSplashAd, @selector(loadAdAndShowInWindow:), (IMP)GDTSplashAd_loadAdAndShowInWindow, NULL);
    hookIfExists(GDTSplashAd, @selector(showAdInWindow:), (IMP)GDTSplashAd_showAdInWindow, NULL);
    hookIfExists(GDTSplashAd, @selector(loadAd), (IMP)GDTSplashAd_loadAd, NULL);
    
    hookIfExists(CSJSplashAd, @selector(loadAdAndShowInWindow:), (IMP)CSJSplashAd_loadAdAndShowInWindow, NULL);
    hookIfExists(CSJSplashAd, @selector(showAdInWindow:), (IMP)CSJSplashAd_showAdInWindow, NULL);
    hookIfExists(CSJSplashAd, @selector(loadAd), (IMP)CSJSplashAd_loadAd, NULL);
    
    hookIfExists(BUSplashAdView, @selector(loadAdAndShowInWindow:), (IMP)BUSplashAdView_loadAdAndShowInWindow, NULL);
    hookIfExists(BUSplashAdView, @selector(showAdInWindow:), (IMP)BUSplashAdView_showAdInWindow, NULL);
    hookIfExists(BUSplashAdView, @selector(loadAd), (IMP)BUSplashAdView_loadAd, NULL);
    
    hookIfExists(BaiduMobAdSplash, @selector(loadAndShowInWindow:), (IMP)BaiduMobAdSplash_loadAndShowInWindow, NULL);
    hookIfExists(BaiduMobAdSplash, @selector(showInWindow:), (IMP)BaiduMobAdSplash_showInWindow, NULL);
    hookIfExists(BaiduMobAdSplash, @selector(load), (IMP)BaiduMobAdSplash_load, NULL);
    
    hookIfExists(KSAdSplashViewController, @selector(loadSplashAd), (IMP)KSAdSplashViewController_loadSplashAd, NULL);
    hookIfExists(KSAdSplashViewController, @selector(showSplashAd), (IMP)KSAdSplashViewController_showSplashAd, NULL);
    
    hookIfExists(CMSplashManager, @selector(requestSplashAd), (IMP)CMSplashManager_requestSplashAd, NULL);
    hookIfExists(CMSplashManager, @selector(displaySplashAd), (IMP)CMSplashManager_displaySplashAd, NULL);
    
    hookIfExists(CMAdManager, @selector(loadSplash), (IMP)CMAdManager_loadSplash, NULL);
    hookIfExists(CMAdManager, @selector(showSplash), (IMP)CMAdManager_showSplash, NULL);
    
    // Rewarded video hooks
    hookIfExists(GDTRewardedVideoAd, @selector(remainingTime), (IMP)RewardVideo_remainingTime, NULL);
    hookIfExists(GDTRewardedVideoAd, @selector(rewardDidEarn), (IMP)RewardVideo_rewardDidEarn, NULL);
    
    hookIfExists(CSJRewardedVideoAd, @selector(remainingTime), (IMP)RewardVideo_remainingTime, NULL);
    hookIfExists(CSJRewardedVideoAd, @selector(rewardDidEarn), (IMP)RewardVideo_rewardDidEarn, NULL);
    
    hookIfExists(BUDRewardedVideoAd, @selector(remainingTime), (IMP)RewardVideo_remainingTime, NULL);
    hookIfExists(BUDRewardedVideoAd, @selector(rewardDidEarn), (IMP)RewardVideo_rewardDidEarn, NULL);
    
    // UI filtering hooks
    hookIfExists(objc_getClass("UIViewController"), @selector(viewDidAppear:), (IMP)UIViewController_viewDidAppear, (IMP *)&orig_UIViewController_viewDidAppear);
    hookIfExists(objc_getClass("UIView"), @selector(addSubview:), (IMP)UIView_addSubview, (IMP *)&orig_UIView_addSubview);
    
    // Network request blocker
    hookIfExists(objc_getClass("NSURLSession"), @selector(dataTaskWithRequest:completionHandler:), (IMP)NSURLSession_dataTaskWithRequest_completionHandler, (IMP *)&orig_NSURLSession_dataTaskWithRequest_completionHandler);
}
