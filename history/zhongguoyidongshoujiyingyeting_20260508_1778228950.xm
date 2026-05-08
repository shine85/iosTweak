#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <objc/runtime.h>

/* ---------- Splash Ad Hooks ---------- */
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
%end

%hook BUSplashAdView
- (void)loadAd { }
%end

%hook BaiduMobAdSplash
- (void)loadAndDisplayInWindow:(UIWindow *)window { }
%end

%hook KSAdSplashViewController
- (void)loadAndShow { }
%end

%hook CMSplashManager
- (void)requestSplashAd { }
%end

%hook CMAdManager
- (void)fetchAd { }
%end

/* ---------- UIViewController Filter ---------- */
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    NSString *clsName = NSStringFromClass([self class]);
    BOOL likelyAdVC = ([clsName rangeOfString:@"Ad"].location != NSNotFound) ||
                      ([clsName rangeOfString:@"Splash"].location != NSNotFound);
    if (likelyAdVC) {
        BOOL hasAdSubview = NO;
        for (UIView *sub in self.view.subviews) {
            NSString *subCls = NSStringFromClass([sub class]);
            if ([subCls rangeOfString:@"Ad"].location != NSNotFound ||
                [subCls rangeOfString:@"Splash"].location != NSNotFound) {
                hasAdSubview = YES;
                break;
            }
        }
        if (hasAdSubview) {
            self.view.hidden = YES;
            return;
        }
    }
    %orig;
}
%end

/* ---------- UIView Filter ---------- */
%hook UIView
- (void)didMoveToWindow {
    NSString *clsName = NSStringFromClass([self class]);
    BOOL likelyAdView = ([clsName rangeOfString:@"Ad"].location != NSNotFound) ||
                        ([clsName rangeOfString:@"Splash"].location != NSNotFound);
    if (likelyAdView) {
        if (![self isKindOfClass:[UIWindow class]] &&
            ![self isKindOfClass:[UIButton class]] &&
            ![self isKindOfClass:[UILabel class]]) {
            self.hidden = YES;
            return;
        }
    }
    %orig;
}
%end

/* ---------- Rewarded Video Safe Hooks ---------- */
static NSInteger (*origRemainingTime)(id, SEL);
static NSInteger remainingTimeHook(id self, SEL _cmd) {
    return 3;
}

static void (*origRewardUser)(id, SEL);
static void rewardUserHook(id self, SEL _cmd) {
    if (origRewardUser) origRewardUser(self, _cmd);
    Ivar delIvar = class_getInstanceVariable([self class], "_delegate");
    if (delIvar) {
        id delegate = object_getIvar(self, delIvar);
        SEL rewardSel = NSSelectorFromString(@"rewardedVideoDidRewardUser:");
        if (delegate && [delegate respondsToSelector:rewardSel]) {
            ((void (*)(id, SEL, id))objc_msgSend)(delegate, rewardSel, self);
        }
    }
}

/* ---------- Constructor ---------- */
%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"),
          CSJSplashAd=objc_getClass("CSJSplashAd"),
          BUSplashAdView=objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController=objc_getClass("KSAdSplashViewController"),
          CMSplashManager=objc_getClass("CMSplashManager"),
          CMAdManager=objc_getClass("CMAdManager"));

    NSArray *rewardClasses = @[
        @"RewardedVideoAd",
        @"GMRewardedVideoAd",
        @"KSRewardedVideoAd"
    ];
    for (NSString *clsName in rewardClasses) {
        Class cls = objc_getClass(clsName.UTF8String);
        if (!cls) continue;

        SEL selTime = NSSelectorFromString(@"remainingTime");
        if (class_getInstanceMethod(cls, selTime)) {
            MSHookMessageEx(cls, selTime, (IMP)remainingTimeHook, (IMP *)&origRemainingTime);
        }

        SEL selReward = NSSelectorFromString(@"rewardUser");
        if (class_getInstanceMethod(cls, selReward)) {
            MSHookMessageEx(cls, selReward, (IMP)rewardUserHook, (IMP *)&origRewardUser);
        }
    }
}
