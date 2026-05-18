#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/* ---------------- Helpers ---------------- */

static void forceRestoreSubViews(UIView *view) {
    if (!view) return;
    for (UIView *sub in view.subviews) {
        sub.hidden = NO;
        sub.alpha = 1.0;
        if (sub.subviews.count) forceRestoreSubViews(sub);
    }
}

/* ---------------- Network Blocker ---------------- */

static NSSet *_blockedHosts = nil;
static void loadRuleSet(void) {
    NSString *path = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:@"ad_rules.plist"] copy];
    NSArray *arr = [NSArray arrayWithContentsOfFile:path];
    if (arr) _blockedHosts = [NSSet setWithArray:arr];
}
static BOOL shouldBlockRequest(NSURLRequest *request) {
    if (!_blockedHosts) loadRuleSet();
    NSString *host = request.URL.host.lowercaseString;
    for (NSString *pattern in _blockedHosts) {
        if ([host containsString:pattern]) return YES;
    }
    return NO;
}
static void downloadRemoteRules(NSArray *urls) {
    for (NSString *urlStr in urls) {
        NSURL *url = [NSURL URLWithString:urlStr];
        if (!url) continue;
        NSURLRequest *req = [NSURLRequest requestWithURL:url];
        [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (data) {
                NSString *path = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches"] stringByAppendingPathComponent:@"ad_rules.plist"] copy];
                [data writeToFile:path atomically:YES];
                _blockedHosts = nil;
            }
        }] resume];
    }
}

/* ---------------- Default Remote Rule URLs ---------------- */

static NSArray *defaultRemoteURLs(void) {
    return @[
        @"https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/广告平台拦截器.beta.sgmodule",
        @"https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/HTTPDNS拦截器.beta.sgmodule",
        @"https://yfamilys.com/plugin/adultraplus.plugin"
    ];
}

/* ---------------- Global Injection Log ---------------- */

%group InjectionLog
%hook UIApplication
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSLog(@"[!!!] Tweak 注入成功");
    return %orig;
}
%end
%end

/* ---------------- Splash Ad – GDT ---------------- */

%group SplashGDT
%init(GDTSplashAd=objc_getClass("GDTSplashAd"));
%hook GDTSplashAd
- (BOOL)loadAd { return NO; }
- (void)showAdInWindow:(UIWindow *)window { }
%end
%end

/* ---------------- Splash Ad – CSJ ---------------- */

%group SplashCSJ
%init(BUSplashAdView=objc_getClass("BUSplashAdView"));
%hook BUSplashAdView
- (BOOL)loadAd { return NO; }
- (void)showAdInWindow:(UIWindow *)window { }
%end
%end

%group SplashCSJ2
%init(CSJSplashAd=objc_getClass("CSJSplashAd"));
%hook CSJSplashAd
- (void)loadAd { }
- (void)showAdInWindow:(UIWindow *)window { }
- (void)showAd { }
%end
%end

/* ---------------- Splash Ad – BUM ---------------- */

%group SplashBUM
%init(BUMNativeSplash=objc_getClass("BUMNativeSplash"));
%hook BUMNativeSplash
- (void)loadAd{ }
- (void)presentFromRootViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion { }
%end
%end

/* ---------------- Splash Ad – Baidu ---------------- */

%group SplashBaidu
%init(BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"));
%hook BaiduMobAdSplash
- (id)init { return nil; }
- (void)loadAd { }
%end
%end

/* ---------------- Splash Ad – KS ---------------- */

%group SplashKS
%init(KSAdSplashViewController=objc_getClass("KSAdSplashViewController"));
%hook KSAdSplashViewController
- (void)loadAd { }
- (void)showAd { }
%end
%end

%group SplashPAG
%init(PAGLAppOpenAd=objc_getClass("PAGLAppOpenAd"));
%hook PAGLAppOpenAd
- (BOOL)loadAd { return NO; }
- (void)showAdInWindow:(UIWindow *)window { }
%end
%end

%group SplashABU
%init(ABUSplashAd=objc_getClass("ABUSplashAd"));
%hook ABUSplashAd
- (void)loadAd { }
- (void)showAd { }
- (void)viewDidLoad { }
%end
%end

/* ---------------- Interstitial Ad – GDT ---------------- */

%group InterstitialGDT
%init(GDTUnifiedInterstitialAd=objc_getClass("GDTUnifiedInterstitialAd"));
%hook GDTUnifiedInterstitialAd
- (void)loadAd { }
- (void)showAdInViewController:(UIViewController *)controller { }
%end
%end

/* ---------------- Interstitial Ad – CSJ ---------------- */

%group InterstitialCSJ
%init(USnapInterstitial=objc_getClass("USnapInterstitial"));
%hook USnapInterstitial
- (void)load { }
- (void)show { }
%end
%end

%group InterstitialCSJ2
%init(CSJInterstitialAd=objc_getClass("CSJInterstitialAd"));
%hook CSJInterstitialAd
- (void)loadAd { }
- (void)showAd { }
- (void)showAdFromRootViewController:(UIViewController *)controller options:(NSDictionary *)options { }
%end
%end

/* ---------------- Interstitial Ad – BU ---------------- */

%group InterstitialBU
%init(BUInterstitialAd=objc_getClass("BUInterstitialAd"));
%hook BUInterstitialAd
- (void)loadAd{ }
- (void)showAd { }
%end
%end

%group InterstitialBU2
%init(BUNativeExpressInterstitialAd=objc_getClass("BUNativeExpressInterstitialAd"));
%hook BUNativeExpressInterstitialAd
- (void)loadAd { }
- (void)showAd { }
%end
%end

/* ---------------- Interstitial Ad – Baidu ---------------- */

%group InterstitialBaidu
%init(BaiduMobAdInterstitial=objc_getClass("BaiduMobAdInterstitial"));
%hook BaiduMobAdInterstitial
- (void)loadAd { }
- (void)showAd { }
%end
%end

/* ---------------- Interstitial Ad – KS ---------------- */

%group InterstitialKS
%init(KSInterstitialAd=objc_getClass("KSInterstitialAd"));
%hook KSInterstitialAd
- (void)loadAd { }
- (void)showAd { }
%end
%end

%group InterstitialKS2
%init(KSAdInterstitialViewController=objc_getClass("KSAdInterstitialViewController"));
%hook KSAdInterstitialViewController
- (void)loadAd { }
- (void)showAd { }
%end
%end

/* ---------------- Popup Ad – Generic ---------------- */

%group PopupCSJ
%init(CSJPopupAd=objc_getClass("CSJPopupAd"));
%hook CSJPopupAd
- (void)loadAd { }
- (void)presentFromViewController:(UIViewController *)vc { }
%end
%end

%group PopupBU
%init(BUPopupAd=objc_getClass("BUPopupAd"));
%hook BUPopupAd
- (void)loadAd { }
- (void)presentFromRootViewController:(UIViewController *)vc { }
%end
%end

%group PopupBaidu
%init(BaiduMobAdPopup=objc_getClass("BaiduMobAdPopup"));
%hook BaiduMobAdPopup
- (void)showAd { }
%end
%end

%group PopupKS
%init(KSAdPopup=objc_getClass("KSAdPopup"));
%hook KSAdPopup
- (void)show { }
%end
%end

/* ---------------- PopupManager / MarketingDialog ---------------- */

%group Dialogs
%init(MarketingDialog=objc_getClass("MarketingDialog"));
%hook MarketingDialog
- (void)show { }
- (void)dismiss { }
%end
%end

%group PopupMan
%init(PopupManager=objc_getClass("PopupManager"));
%hook PopupManager
- (void)showPopup { }
- (void)dismissPopup { }
%end
%end

/* ---------------- Global Window Hook ---------------- */

%group WindowHook
%hook UIWindow
- (void)makeKeyAndVisible {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Ad"] || [cls containsString:@"Splash"]) {
        [self setHidden:YES];
        [self resignKeyWindow];
    } else {
        %orig;
    }
}
- (void)becomeKeyWindow {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Ad"] || [cls containsString:@"Splash"]) {
        [self setHidden:YES];
        [self resignKeyWindow];
    } else {
        %orig;
    }
}
- (void)setHidden:(BOOL)hidden {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Ad"]) hidden = YES;
    %orig(hidden);
}
%end
%end

/* ---------------- ViewController Hook ---------------- */

%group ViewControllerHook
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Ad"] || [cls containsString:@"Interstitial"] || [cls containsString:@"Popup"]) {
        // Dismiss or hide
        if ([self isKindOfClass:[UIViewController class]]) {
            [(UIViewController *)self dismissViewControllerAnimated:NO completion:nil];
        }
        if ([self isKindOfClass:[UIView class]]) {
            [((UIView *)self) removeFromSuperview];
        }
    } else {
        %orig;
    }
}
%end
%end

/* ---------------- Network Session Hook ---------------- */

%group NetworkHook
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData * __nullable, NSURLResponse * __nullable, NSError * __nullable))completionHandler {
    if (shouldBlockRequest(request)) {
        if (completionHandler) {
            completionHandler(nil, nil, [NSError errorWithDomain:@"com.adblock" code:-999 userInfo:nil]);
        }
        return nil;
    }
    return %orig(request, completionHandler);
}
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData * __nullable, NSURLResponse * __nullable, NSError * __nullable))completionHandler {
    if (shouldBlockRequest([NSURLRequest requestWithURL:url])) {
        if (completionHandler) {
            completionHandler(nil, nil, [NSError errorWithDomain:@"com.adblock" code:-999 userInfo:nil]);
        }
        return nil;
    }
    return %orig(url, completionHandler);
}
%end
%end

/* ---------------- Console Instruction Hook ---------------- */

%group ConsoleHook
%hook NSLog
- (void)logv:(NSString *)format, ... {
    // Suppress logs that mention ad
    va_list argv;
    va_start(argv, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:argv];
    va_end(argv);
    if (![msg containsString:@"Ad"] && ![msg containsString:@"Ad"]) {
        %orig(msg);
    }
}
%end
%end

/* ---------------- Transparent Creator for Remote Rules ---------------- */

%group RemoteRuleInitializer
%hook NSObject (RemoteRuleInit)
+ (void)load {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *userURLs = [[NSUserDefaults standardUserDefaults] objectForKey:@"ad_remote_urls"];
        if (!userURLs || userURLs.count==0) userURLs = defaultRemoteURLs();
        downloadRemoteRules(userURLs);
    });
}
%end
%end

/* ---------------- ctor to register all groups ---------------- */

%ctor {
    // Initialize all groups explicitly
    %init(SplashGDT);
    %init(SplashCSJ);
    %init(SplashCSJ2);
    %init(SplashBUM);
    %init(SplashBaidu);
    %init(SplashKS);
    %init(SplashPAG);
    %init(SplashABU);
    %init(InterstitialGDT);
    %init(InterstitialCSJ);
    %init(InterstitialCSJ2);
    %init(InterstitialBU);
    %init(InterstitialBU2);
    %init(InterstitialBaidu);
    %init(InterstitialKS);
    %init(InterstitialKS2);
    %init(PopupCSJ);
    %init(PopupBU);
    %init(PopupBaidu);
    %init(PopupKS);
    %init(Diagrams); // MarketingDialog & PopupManager
    %init(WindowHook);
    %init(ViewControllerHook);
    %init(NetworkHook);
    %init(ConsoleHook);
    %init(RemoteRuleInitializer);
}