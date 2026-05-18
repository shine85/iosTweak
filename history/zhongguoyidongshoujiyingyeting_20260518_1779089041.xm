#import <substrate.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-arc"
#pragma clang diagnostic ignored "-Wobjc-owning-sender"

#pragma mark - 全局辅助函数

static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count > 0) forceRestoreSubViews(sub);
    }
}

static void fakeDelegateNotify(id adObject) {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([adObject respondsToSelector:@selector(delegate)]) {
        id delegate = [adObject performSelector:@selector(delegate)];
        if ([delegate respondsToSelector:@selector(splashAdClosed:)]) {
            [delegate performSelector:@selector(splashAdClosed:) withObject:adObject];
        } else if ([delegate respondsToSelector:@selector(splashAdDidDismissFullScreenContent:)]) {
            [delegate performSelector:@selector(splashAdDidDismissFullScreenContent:) withObject:adObject];
        } else if ([delegate respondsToSelector:@selector(interstitialAdDidClose:)]) {
            [delegate performSelector:@selector(interstitialAdDidClose:) withObject:adObject];
        } else if ([delegate respondsToSelector:@selector(splashDidDismissScreen:)]) {
            [delegate performSelector:@selector(splashDidDismissScreen:) withObject:adObject];
        }
    }
    #pragma clang diagnostic pop
    if ([adObject isKindOfClass:[UIView class]]) {
        UIView *v = (UIView *)adObject;
        v.hidden = YES;
        [v removeFromSuperview];
    } else if ([adObject isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (UIViewController *)adObject;
        [vc dismissViewControllerAnimated:NO completion:nil];
    }
}

static void tryMakeKeyAndVisible(UIApplication *app) {
    for (UIWindow *w in app.windows) {
        if ([w isKindOfClass:[UIWindow class]] && !w.hidden && w.windowLevel == UIWindowLevelNormal) {
            return;
        }
    }
    UIViewController *root = app.keyWindow.rootViewController;
    if (root) [root.presentedViewController dismissViewControllerAnimated:NO completion:nil];
    UIWindow *newWin = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    newWin.hidden = NO;
    newWin.windowLevel = UIWindowLevelNormal;
}

static BOOL hostMatchesWhiteList(NSURL *url) {
    static NSArray *whiteList;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        whiteList = @[
            @"open.appstore.com",
            @"m.sina.cn",
            @"m.baidu.com",
            @"m.taobao.com"
        ];
    });
    for (NSString *w in whiteList) {
        if ([url.host containsString:w]) return YES;
    }
    return NO;
}

#pragma mark - 声明未知类

@interface GDTSplashAd : NSObject @end
@interface GDTSplashAd (Custom) - (void)showAdInWindow:(UIWindow *)window; - (void)loadAd; @end

@interface BUSplashAdView : NSObject @end
@interface BUSplashAdView (Custom) - (void)loadAd; @end

@interface CSJSplashAd : NSObject @end
@interface CSJSplashAd (Custom) - (void)loadAd; @end

@interface BUNativeExpressInterstitialAd : NSObject @end
@interface BUNativeExpressInterstitialAd (Custom) - (void)loadAd; - (void)showAdFromViewController:(UIViewController *)vc; @end

@interface CSJInterstitialAd : NSObject @end
@interface CSJInterstitialAd (Custom) - (void)loadAd; - (void)showAdFromViewController:(UIViewController *)vc; @end

@interface GDTUnifiedInterstitialAd : NSObject @end
@interface GDTUnifiedInterstitialAd (Custom) - (void)loadAd; - (void)showAdFromViewController:(UIViewController *)vc; @end

@interface BDASplashManager : NSObject @end
@interface BDASplashManager (Custom) + (instancetype)sharedInstance; - (void)loadSplashAd; - (void)showSplashAd; @end

@interface WKWebView (Client) @end

#pragma mark - Hook 组定义

%group SplashAd
%hook GDTSplashAd
- (void)showAdInWindow:(UIWindow *)window {
    // 阻止广告展示
    NSLog(@"[!] GDTSplashAd showAdInWindow+blocked");
    fakeDelegateNotify(self);
}
- (void)loadAd {
    NSLog(@"[!] GDTSplashAd loadAd+blocked");
}
%end

%hook BUSplashAdView
- (void)loadAd {
    NSLog(@"[!] BUSplashAdView loadAd+blocked");
}
%end

%hook CSJSplashAd
- (void)loadAd {
    NSLog(@"[!] CSJSplashAd loadAd+blocked");
}
%end

%hook BDASplashManager
+ (instancetype)sharedInstance {
    id inst = MSHookIvar<id>(self, "_originalInstance");
    if (!inst) {
        inst = MSHookOriginalIMP()(self, _cmd);
        MSHookIvar(self, "_originalInstance", inst);
    }
    return inst;
}
- (void)loadSplashAd {
    NSLog(@"[!] BDASplashManager loadSplashAd+blocked");
}
- (void)showSplashAd {
    NSLog(@"[!] BDASplashManager showSplashAd+blocked");
}
%end
%end

%group InterstitialAd
%hook BUNativeExpressInterstitialAd
- (void)loadAd {
    NSLog(@"[!] BUNativeExpressInterstitialAd loadAd+blocked");
}
- (void)showAdFromViewController:(UIViewController *)vc {
    NSLog(@"[!] BUNativeExpressInterstitialAd showAd+blocked");
}
%end

%hook CSJInterstitialAd
- (void)loadAd {
    NSLog(@"[!] CSJInterstitialAd loadAd+blocked");
}
- (void)showAdFromViewController:(UIViewController *)vc {
    NSLog(@"[!] CSJInterstitialAd showAd+blocked");
}
%end

%hook GDTUnifiedInterstitialAd
- (void)loadAd {
    NSLog(@"[!] GDTUnifiedInterstitialAd loadAd+blocked");
}
- (void)showAdFromViewController:(UIViewController *)vc {
    NSLog(@"[!] GDTUnifiedInterstitialAd showAd+blocked");
}
%end
%end

%group PopAds
%hook UITabBarController
- (void)presentViewController:(UIViewController *)viewController animated:(BOOL)flag completion:(void (^)(void))completion {
    NSString *cls = NSStringFromClass([viewController class]);
    if ([cls containsString:@"Interstitial"] || [cls containsString:@"Reward"]) {
        NSLog(@"[!] Interstitial modal blocked");
        if (completion) completion();
        return;
    }
    %orig;
}
%end

%hook UIWindow
- (BOOL)makeKeyAndVisible {
    BOOL res = %orig;
    if (self.windowLevel == UIWindowLevelNormal && !self.hidden) {
        NSString *cls = NSStringFromClass([self class]);
        if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
            NSLog(@"[!] Detected AD Window: %@, hiding", cls);
            self.hidden = YES;
            [self resignKeyWindow];
        }
    }
    return res;
}
%end

%hook UIView
- (void)didMoveToWindow {
    %orig;
    if (self.window && !self.hidden) {
        NSString *cls = NSStringFromClass([self class]);
        if ([cls containsString:@"Splash"] || [cls containsString:@"Ad"]) {
            NSLog(@"[!] Hiding AD View: %@", cls);
            self.hidden = YES;
        }
    }
}
%end

%group Networking
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    if (!hostMatchesWhiteList(request.URL)) {
        NSLog(@"[!] Blocking request to %@", request.URL.absoluteString);
        return nil;
    }
    return %orig;
}
%end

%hook WKWebView
- (void)decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (!hostMatchesWhiteList(action.request.URL)) {
        NSLog(@"[!] WKWebView blocked navigation to %@", action.request.URL.absoluteString);
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    %orig;
}
%end
%end

%group RemoteRules
static void downloadRulesFromURL(NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) return;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (!data) return;
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject
                          stringByAppendingPathComponent:@"ad_rules.dat"];
        [data writeToFile:path atomically:YES];
        NSLog(@"[!] Rules downloaded to %@", path);
    });
}
static void initRemoteRules() {
    NSArray *defaultURLs = @[
        @"https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/%E5%B9%BF%E5%91%8A%E5%B9%B3%E5%8F%B0%E6%8B%A6%E6%88%AA%E5%99%A8.beta.sgmodule",
        @"https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/HTTPDNS%E6%8B%A6%E6%88%AA%E5%99%A8.beta.sgmodule",
        @"https://yfamilys.com/plugin/adultraplus.plugin"
    ];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *customURL = [ud stringForKey:@"AdRuleRemoteURL"];
    if (customURL.length > 0) {
        downloadRulesFromURL(customURL);
    } else {
        for (NSString *u in defaultURLs) {
            downloadRulesFromURL(u);
        }
    }
}
%end

%group ControlPanel
%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if (![self isKindOfClass:NSClassFromString(@"SomeMainViewController")]) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1e9)), dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"广告拦截设置"
                                                                       message:@"输入自定义远程规则地址"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"AdRuleRemoteURL"]
                ?: @"";
        }];
        __weak typeof(self) wself = self;
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *text = alert.textFields.firstObject.text;
            if (text.length > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:text forKey:@"AdRuleRemoteURL"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                downloadRulesFromURL(text);
            }
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [wself presentViewController:alert animated:YES completion:nil];
    });
}
%end
%end

%group AppLaunch
%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    BOOL res = %orig;
    NSLog(@"[!!!] Tweak 注入成功");
    initRemoteRules();
    return res;
}
%end
%end

%ctor {
    %init(SplashAd);
    %init(InterstitialAd);
    %init(PopAds);
    %init(Networking);
    %init(RemoteRules);
    %init(ControlPanel);
    %init(AppLaunch);
}