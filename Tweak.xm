#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>
#import <WebKit/WebKit.h>

/*---------------------------10 类声明---------------------------*/
@interface GDTSplashAd : NSObject @end
@interface BUSplashAdView : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUMNativeSplash : NSObject @end
@interface BUSplashZoomOutView : NSObject @end
@class BaiduMobAdSplash; @interface BaiduMobAdSplash : NSObject @end
@interface KSAdSplashViewController : NSObject @end
@interface PAGLAppOpenAd : NSObject @end
@interface ABUSplashAd : NSObject @end
@interface GDTUnifiedInterstitialAd : NSObject @end
@interface BUInterstitialAd : NSObject @end
@interface BUNativeExpressInterstitialAd : NSObject @end
@interface CSJInterstitialAd : NSObject @end
@interface KSInterstitialAd : NSObject @end
@interface KSAdInterstitialViewController : NSObject @end
@interface BaiduMobAdInterstitial : NSObject @end
@interface GDTUnifiedRewardad : NSObject @end
@interface GDTNativeExpressRewardad : NSObject @end
@interface GDTRewardedVideoAd : NSObject @end
@interface GDTRewardedVideoAd : NSObject @end
@interface GDTInterstitialAd : NSObject @end
@interface GDTBannerAd : NSObject @end
@interface GDTAdView : NSObject @end
@interface GDTAd : NSObject @end
@interface CSJBannerAd : NSObject @end
@interface CSJRewardedVideoAd : NSObject @end
@interface CSJNativeExpressRewardad : NSObject @end
@interface CSJNativeExpressAd : NSObject @end
@interface CSMobAd : NSObject @end

/*---------------------------全局辅助---------------------------*/
static void forceRestoreSubViews(UIView *view){
    if(!view) return;
    for(UIView *sub in view.subviews){
        sub.hidden = NO;
        sub.alpha = 1.0;
        if(sub.subviews.count>0) forceRestoreSubViews(sub);
    }
}

/*------网络去广告规则管理------*/
static NSSet *adHostPatterns = nil;
static void loadAdHosts(){
    NSString *path=[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"ad_hosts.plist"];
    NSArray *arr = [NSArray arrayWithContentsOfFile:path];
    if(arr) adHostPatterns = [NSSet setWithArray:arr];
}
static BOOL isAdHost(NSURL *url){
    if(!adHostPatterns) return NO;
    NSString *host = url.host.lowercaseString;
    for(NSString *pattern in adHostPatterns){
        if([host containsString:pattern]) return YES;
    }
    return NO;
}
static void downloadRuleFromURL(NSString *urlString, NSString *fileName){
    NSURL *url=[NSURL URLWithString:urlString];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(data && !error){
            NSString *path=[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:fileName];
            [data writeToFile:path atomically:YES];
        }
    }];
    [task resume];
}
static void initAdHosts(){
    NSArray *defaults = @[@"https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/%E5%B9%BF%E5%91%8A%E5%B9%B3%E5%8F%B0%E6%8B%A6%E6%88%AA%E5%99%A8.beta.sgmodule",
                          @"https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/HTTPDNS%E6%8B%A6%E6%88%AA%E5%99%A8.beta.sgmodule",
                          @"https://yfamilys.com/plugin/adultraplus.plugin"];
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    [ud setObject:defaults forKey:@"AdRuleURLs"];
    [ud synchronize];
    for(NSString *urlStr in defaults){
        NSString *fileName=[urlStr lastPathComponent];
        downloadRuleFromURL(urlStr,fileName);
    }
}

/*---------------------------Hooks---------------------------*/
/*--- Splash Ads ---*/
%group SplashAds
%hook GDTSplashAd
- (void)loadAd{ /* do nothing */ }
- (void)showAdInWindow:(UIWindow *)window{ /* cancel */ }
- (void)showInWindow:(UIWindow *)window{ /* cancel */ }
%end
%hook BUSplashAdView
- (void)loadAd{ }
- (void)show{ }
- (BOOL)showInWindow:(UIWindow *)window{ return NO; }
%end
%hook CSJSplashAd
- (void)loadAd{ }
- (void)showInWindow:(UIWindow *)window{ }
%end
%hook BUMNativeSplash
- (void)loadAd{ }
- (void)showInWindow:(UIWindow *)window{ }
%end
%hook BUSplashZoomOutView
- (void)loadAd{ }
- (void)showInWindow:(UIWindow *)window{ }
%end
%hook BaiduMobAdSplash
- (void)loadAd{ }
- (void)showInWindow:(UIWindow *)window{ }
%end
%hook KSAdSplashViewController
- (void)loadAd{ }
- (void)showInWindow:(UIWindow *)window{ }
%end
%hook PAGLAppOpenAd
- (void)loadAd{ }
- (void)showAdInWindow:(UIWindow *)window{ }
%end
%hook ABUSplashAd
- (void)requestAd{ }
- (void)show{ }
%end
%end

/*--- Interstitial Ads ---*/
%group InterstitialAds
%hook GDTUnifiedInterstitialAd
- (void)loadAd{ }
- (void)showAdInWindow:(UIWindow *)window{ }
%end
%hook BUInterstitialAd
- (void)loadAd{ }
- (void)showAdInWindow:(UIWindow *)window{ }
%end
%hook BUNativeExpressInterstitialAd
- (void)loadAd{ }
- (void)showAdInWindow:(UIWindow *)window{ }
%end
%hook CSJInterstitialAd
- (void)loadAd{ }
- (void)showInWindow:(UIWindow *)window{ }
%end
%hook KSInterstitialAd
- (void)loadAd{ }
- (void)showAdInWindow:(UIWindow *)window{ }
%end
%hook KSAdInterstitialViewController
- (void)loadAd{ }
- (void)showInWindow:(UIWindow *)window{ }
%end
%hook BaiduMobAdInterstitial
- (void)loadAd{ }
- (void)showInWindow:(UIWindow *)window{ }
%end
%end

/*--- Popup / Banner Ads ---*/
%group PopupAds
%hook GDTBannerAd
- (void)loadAd{ }
%end
%hook GDTAdView
- (void)loadAd{ }
%end
%hook GDTAd
- (void)loadAd{ }
%end
%hook CSJBannerAd
- (void)loadAd{ }
%end
%hook CSJRewardedVideoAd
- (void)prepareAd{ }
- (void)showAd{ }
%end
%hook CSJNativeExpressRewardad
- (void)loadAd{ }
%end
%hook CSJNativeExpressAd
- (void)loadAd{ }
%end
%hook CSMobAd
- (void)loadAd{ }
%end
%end

/*--- UIWindow Hook for Fallback ---*/
%group WindowHook
%hook UIWindow
- (void)makeKeyAndVisible{
    NSString *cls = NSStringFromClass([self class]);
    if([cls containsString:@"Ad"] || [cls containsString:@"Interstitial"] || [cls containsString:@"Popup"]){
        self.hidden = YES;
        [self resignKeyWindow];
    }
    %orig;
}
- (void)becomeKeyWindow{
    NSString *cls = NSStringFromClass([self class]);
    if([cls containsString:@"Ad"] || [cls containsString:@"Interstitial"] || [cls containsString:@"Popup"]){
        self.hidden = YES;
        [self resignKeyWindow];
    }
    %orig;
}
- (void)setHidden:(BOOL)hidden{
    NSString *cls = NSStringFromClass([self class]);
    if([cls containsString:@"Ad"] && hidden==NO){
        return;
    }
    %orig;
}
%end
%end

/*--- ViewController Fallback ---*/
%group ViewControllerHook
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated{
    NSString *cls = NSStringFromClass([self class]);
    if([cls containsString:@"Interstitial"] || [cls containsString:@"Popup"] || [cls containsString:@"Reward"] || [cls containsString:@"Ad"]){
        if([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]){
            [((UIViewController *)self) dismissViewControllerAnimated:NO completion:nil];
        }
        ((UIViewController *)self).view.hidden = YES;
    }
    %orig;
}
%end
%end

/*--- Network Hook ---*/
%group NetworkHook
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    NSURL *url = request.URL;
    if(isAdHost(url)){
        NSURLSessionDataTask *task = %orig;
        [task cancel];
        return task;
    }
    return %orig;
}
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url{
    if(isAdHost(url)){
        NSURLSessionDataTask *task = %orig;
        [task cancel];
        return task;
    }
    return %orig;
}
%end

%hook WKWebView
- (void)decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    NSURL *url = navigationAction.request.URL;
    if(isAdHost(url)){
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        %orig;
    }
}
%end
%end

/*--- Constructor - 初始化所有组并下载规则 ---*/
%ctor {
    %init(SplashAds);
    %init(InterstitialAds);
    %init(PopupAds);
    %init(WindowHook);
    %init(ViewControllerHook);
    %init(NetworkHook);

    // 注入日志
    NSLog(@"[!!!] 4G Mobile Tweak 注入成功");

    // 设定默认规则并下载
    initAdHosts();
    loadAdHosts();
}