#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <objc/runtime.h>

/* ---------- 前向声明 ---------- */
@class GDTSplashAd;
@class CSJSplashAd;
@class BUSplashAdView;
@class BaiduMobAdSplash;
@class KSAdSplashViewController;
@class CMSplashManager;
@class CMAdManager;

/* ---------- 空实现函数 ---------- */
static void emptyVoid(id self, SEL _cmd) { }
static void emptyWindow(id self, SEL _cmd, UIWindow *window) { }

/* ---------- 奖励视频安全 Hook ---------- */
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

/* ---------- UIViewController 过滤 ---------- */
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName rangeOfString:@"Ad"].location != NSNotFound ||
        [clsName rangeOfString:@"Splash"].location != NSNotFound) {
        self.view.hidden = YES;
        return;
    }
    %orig;
}
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

/* ---------- UIView 过滤 ---------- */
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

/* ---------- 构造函数 ---------- */
%ctor {
    /* ---------- 类初始化 ---------- */
    %init(GDTSplashAd = objc_getClass("GDTSplashAd"),
          CSJSplashAd = objc_getClass("CSJSplashAd"),
          BUSplashAdView = objc_getClass("BUSplashAdView"),
          BaiduMobAdSplash = objc_getClass("BaiduMobAdSplash"),
          KSAdSplashViewController = objc_getClass("KSAdSplashViewController"),
          CMSplashManager = objc_getClass("CMSplashManager"),
          CMAdManager = objc_getClass("CMAdManager"));

    /* ---------- 开屏广告方法拦截列表 ---------- */
    NSArray *splashHooks = @[
        @{@"class": @"GDTSplashAd", @"selectors": @[
            @"loadAdAndShowInWindow:",
            @"showInWindow:",
            @"loadAd"
        ]},
        @{@"class": @"CSJSplashAd", @"selectors": @[
            @"loadAdAndShowInWindow:",
            @"showInWindow:",
            @"loadAd"
        ]},
        @{@"class": @"BUSplashAdView", @"selectors": @[
            @"loadAd",
            @"showAd"
        ]},
        @{@"class": @"BaiduMobAdSplash", @"selectors": @[
            @"loadAndDisplayInWindow:",
            @"showInWindow:",
            @"loadAd"
        ]},
        @{@"class": @"KSAdSplashViewController", @"selectors": @[
            @"loadAndShow",
            @"showInWindow:",
            @"loadAd"
        ]},
        @{@"class": @"CMSplashManager", @"selectors": @[
            @"requestSplashAd",
            @"loadSplashAd",
            @"showSplashAd"
        ]},
        @{@"class": @"CMAdManager", @"selectors": @[
            @"fetchAd",
            @"loadAd"
        ]}
    ];

    for (NSDictionary *info in splashHooks) {
        const char *clsName = [info[@"class"] UTF8String];
        Class cls = objc_getClass(clsName);
        if (!cls) continue;

        NSArray *sels = info[@"selectors"];
        for (NSString *selName in sels) {
            SEL sel = NSSelectorFromString(selName);
            Method m = class_getInstanceMethod(cls, sel);
            if (!m) continue;

            const char *type = method_getTypeEncoding(m);
            /* 判断是否带 UIWindow 参数 */
            if (strstr(type, "@@:@") && strstr(type, "UIWindow")) {
                MSHookMessageEx(cls, sel, (IMP)emptyWindow, NULL);
            } else {
                MSHookMessageEx(cls, sel, (IMP)emptyVoid, NULL);
            }
        }
    }

    /* ---------- 奖励视频 Hook ---------- */
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
