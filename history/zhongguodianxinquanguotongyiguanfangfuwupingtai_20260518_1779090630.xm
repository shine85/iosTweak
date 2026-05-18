#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <objc/runtime.h>
#import <WebKit/WebKit.h>

#pragma mark - Class Declarations
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUSplashAdView : NSObject @end
@interface BUZNativeSplash : NSObject @end
@interface BUNativeAdSplash : NSObject @end
@interface BaiduMobAdSplash : NSObject @end
@interface KSAdSplashViewController : NSObject @end
@interface PAGLAppOpenAd : NSObject @end
@interface ABUSplashAd : NSObject @end
@interface GDTUnifiedInterstitialAd : NSObject @end
@interface GDTRewardVideoAd : NSObject @end
@interface GDTNativeExpressInterstitialAd : NSObject @end
@interface BUInterstitialAd : NSObject @end
@interface BUNativeExpressInterstitialAd : NSObject @end
@interface CSJInterstitialAd : NSObject @end
@interface KSInterstitialAd : NSObject @end
@interface US_IOS_Ad : NSObject @end

#pragma mark - Globals
static NSMutableSet *adHostMutableSet = nil;
static NSSet *adHostSet = nil;

#pragma mark - Helper Functions
static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

static BOOL shouldBlockURL(NSURL *url) {
    if (!url) return NO;
    NSString *host = url.host;
    if (!host) return NO;
    if ([adHostSet containsObject:host]) return YES;
    for (NSString *prefix in @[@"http://", @"https://"]) {
        if ([host hasPrefix:prefix]) {
            NSString *clean = [host stringByReplacingOccurrencesOfString:prefix withString:@""];
            if ([adHostSet containsObject:clean]) return YES;
        }
    }
    return NO;
}

static void downloadRemoteRules(NSArray<NSString *> *urls, void (^completion)(void)) {
    if (!urls || urls.count == 0) { completion(); return; }
    __block NSInteger remaining = urls.count;
    for (NSString *urlString in urls) {
        NSURL *url = [NSURL URLWithString:urlString];
        NSURLSessionDataTask *task = [[NSURLSession sharedSession]
            dataTaskWithURL:url
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!error && data) {
                NSString *content = [[NSString alloc] initWithData:data
                                                          encoding:NSUTF8StringEncoding];
                NSArray *lines = [content componentsSeparatedByCharactersInSet:
                                   [NSCharacterSet newlineCharacterSet]];
                for (NSString *line in lines) {
                    NSString *trim =
                        [line stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    if (trim.length > 0 && ![trim hasPrefix:@"#"]) {
                        if (!adHostMutableSet) adHostMutableSet = [NSMutableSet set];
                        [adHostMutableSet addObject:trim];
                    }
                }
            }
            remaining--;
            if (remaining == 0) {
                adHostSet = [adHostMutableSet copy];
                dispatch_async(dispatch_get_main_queue(), completion);
            }
        }];
        [task resume];
    }
}

#pragma mark - UI Hook: Splash Ads
%hook GDTSplashAd
- (void)showAdInWindow:(UIWindow *)window {
    NSLog(@"[AdRemoval] GDTSplashAd blocked");
}
%end

%hook CSJSplashAd
- (void)showAdInWindow:(UIWindow *)window {
    NSLog(@"[AdRemoval] CSJSplashAd blocked");
}
%end

%hook BUSplashAdView
- (void)loadAd {
    NSLog(@"[AdRemoval] BUSplashAdView blocked");
}
%end

%hook BUZNativeSplash
- (void)loadAd {
    NSLog(@"[AdRemoval] BUZNativeSplash blocked");
}
%end

%hook BUNativeAdSplash
- (void)loadAd {
    NSLog(@"[AdRemoval] BUNativeAdSplash blocked");
}
%end

%hook BaiduMobAdSplash
- (void)showAd {
    NSLog(@"[AdRemoval] BaiduMobAdSplash blocked");
}
%end

%hook KSAdSplashViewController
- (void)presentFromViewController:(UIViewController *)vc {
    NSLog(@"[AdRemoval] KSAdSplashViewController blocked");
}
%end

%hook PAGLAppOpenAd
- (void)presentFromRootViewController:(UIViewController *)vc {
    NSLog(@"[AdRemoval] PAGLAppOpenAd blocked");
}
%end

%hook ABUSplashAd
- (void)loadAd {
    NSLog(@"[AdRemoval] ABUSplashAd blocked");
}
%end

#pragma mark - UI Hook: Interstitial & Popup Ads
%hook GDTUnifiedInterstitialAd
- (void)loadAd {
    NSLog(@"[AdRemoval] GDTUnifiedInterstitialAd blocked");
}
- (void)presentFromRootViewController:(UIViewController *)vc {
    NSLog(@"[AdRemoval] GDTUnifiedInterstitialAd blocked");
}
%end

%hook GDTRewardVideoAd
- (void)loadAd {
    NSLog(@"[AdRemoval] GDTRewardVideoAd blocked");
}
- (void)presentFromRootViewController:(UIViewController *)vc {
    NSLog(@"[AdRemoval] GDTRewardVideoAd blocked");
}
%end

%hook GDTNativeExpressInterstitialAd
- (void)loadAd {
    NSLog(@"[AdRemoval] GDTNativeExpressInterstitialAd blocked");
}
- (void)showInView:(UIView *)view {
    NSLog(@"[AdRemoval] GDTNativeExpressInterstitialAd blocked");
}
%end

%hook BUInterstitialAd
- (void)loadAd {
    NSLog(@"[AdRemoval] BUInterstitialAd blocked");
}
- (void)presentFromRootViewController:(UIViewController *)vc {
    NSLog(@"[AdRemoval] BUInterstitialAd blocked");
}
%end

%hook BUNativeExpressInterstitialAd
- (void)loadAd {
    NSLog(@"[AdRemoval] BUNativeExpressInterstitialAd blocked");
}
- (void)showInView:(UIView *)view {
    NSLog(@"[AdRemoval] BUNativeExpressInterstitialAd blocked");
}
%end

%hook CSJInterstitialAd
- (void)loadAd {
    NSLog(@"[AdRemoval] CSJInterstitialAd blocked");
}
- (void)presentFromViewController:(UIViewController *)vc {
    NSLog(@"[AdRemoval] CSJInterstitialAd blocked");
}
%end

%hook KSInterstitialAd
- (void)loadAd {
    NSLog(@"[AdRemoval] KSInterstitialAd blocked");
}
- (void)presentFromRootViewController:(UIViewController *)vc {
    NSLog(@"[AdRemoval] KSInterstitialAd blocked");
}
%end

%hook US_IOS_Ad
- (void)presentFromViewController:(UIViewController *)vc {
    NSLog(@"[AdRemoval] US_IOS_Ad blocked");
}
%end

#pragma mark - Global UI Cleanup
%hook UIWindow
- (void)makeKeyAndVisible {
    %orig;
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Ad"] || [cls containsString:@"Splash"]) {
        [self setHidden:YES];
        [self resignKeyWindow];
    }
}
- (void)becomeKeyWindow {
    %orig;
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Ad"] || [cls containsString:@"Splash"]) {
        [self setHidden:YES];
        [self resignKeyWindow];
    }
}
- (void)setHidden:(BOOL)hidden {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Ad"] || [cls containsString:@"Splash"]) hidden = YES;
    %orig(hidden);
}
%end

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Interstitial"] || [cls containsString:@"Popup"] || [cls containsString:@"Reward"] || [cls containsString:@"Ad"]) {
        [[self performingSelector:@selector(presentingViewController)] performSelector:@selector(dismissViewControllerAnimated:completion:) withObject:@NO withObject:nil];
        forceRestoreSubViews(((UIViewController *)self).view);
    }
}
%end

#pragma mark - Network Filter
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    if (shouldBlockURL(request.URL)) {
        NSLog(@"[AdRemoval] Blocking NSURLSession request to %@", request.URL);
        return [NSURLSessionDataTask new];
    }
    return %orig;
}
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url {
    if (shouldBlockURL(url)) {
        NSLog(@"[AdRemoval] Blocking NSURLSession URL to %@", url);
        return [NSURLSessionDataTask new];
    }
    return %orig;
}
%end

%hook WKWebView
- (void)loadRequest:(NSURLRequest *)request {
    if (shouldBlockURL(request.URL)) {
        NSLog(@"[AdRemoval] Blocking WKWebView request to %@", request.URL);
        return;
    }
    %orig;
}
%end

#pragma mark - Injection Log
%ctor {
    NSLog(@"[!!!] CtClient Tweak 注入成功");
    adHostMutableSet = [NSMutableSet setWithArray:@[
        @"ads.baidu.com",
        @"cpm.m.doubleclick.net",
        @"api.ad.intelliflow.com"
    ]];
    adHostSet = [adHostMutableSet copy];

    NSArray *defaultURLs = @[
        @"https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/%E5%B9%BF%E5%91%8A%E5%B9%B3%E5%8F%B0%E6%8B%A6%E6%88%AA%E5%99%A8.beta.sgmodule",
        @"https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/HTTPDNS%E6%8B%A6%E6%88%AA%E5%99%A8.beta.sgmodule",
        @"https://yfamilys.com/plugin/adultraplus.plugin"
    ];
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    NSArray *saved = [defs objectForKey:@"AdRemovalRuleURLs"];
    if (!saved) {
        [defs setObject:defaultURLs forKey:@"AdRemovalRuleURLs"];
        [defs synchronize];
    } else {
        defaultURLs = saved;
    }
    downloadRemoteRules(defaultURLs, ^{
        NSLog(@"[AdRemoval] Remote rules loaded");
        adHostSet = [adHostMutableSet copy];
    });
}