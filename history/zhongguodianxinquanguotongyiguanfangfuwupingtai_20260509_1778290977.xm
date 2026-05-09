#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <substrate.h>

@interface GDTSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface CSJSplashAd : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface BUSplashAdView : NSObject
- (void)loadAdAndShowInWindow:(UIWindow *)window;
- (void)loadAd;
@end

@interface BaiduMobAdSplash : NSObject
- (void)loadAndDisplay;
- (void)loadAd;
@end

@interface KSAdSplashViewController : UIViewController
- (void)loadAd;
- (void)showAdInWindow:(UIWindow *)window;
@end

@interface CMAdManager : NSObject
- (void)requestSplashAd;
- (void)showSplashAd;
@end

@interface NSURLSession (AdBlock)
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler;
@end

%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)loadAd { }
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)loadAd { }
%end

%hook BUSplashAdView
- (void)loadAdAndShowInWindow:(UIWindow *)window { }
- (void)loadAd { }
%end

%hook BaiduMobAdSplash
- (void)loadAndDisplay { }
- (void)loadAd { }
%end

%hook KSAdSplashViewController
- (void)loadAd { }
- (void)showAdInWindow:(UIWindow *)window { }
%end

%hook CMAdManager
- (void)requestSplashAd { }
- (void)showSplashAd { }
%end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *clsName = NSStringFromClass([self class]);
    if ([clsName containsString:@"Splash"] || [clsName containsString:@"Ad"]) {
        ((UIViewController *)self).view.hidden = YES;
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}
%end

%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *urlStr = request.URL.absoluteString;
    if (urlStr && ( [urlStr containsString:@"gdt.qq.com"] ||
                    [urlStr containsString:@"adservice"] ||
                    [urlStr containsString:@"kuaishou.com"] ||
                    [urlStr containsString:@"unionapi"] ||
                    [urlStr containsString:@"ads"] )) {
        if (completionHandler) {
            completionHandler(nil, nil, nil);
        }
        return nil;
    }
    return %orig;
}
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSString *urlStr = url.absoluteString;
    if (urlStr && ( [urlStr containsString:@"gdt.qq.com"] ||
                    [urlStr containsString:@"adservice"] ||
                    [urlStr containsString:@"kuaishou.com"] ||
                    [urlStr containsString:@"unionapi"] ||
                    [urlStr containsString:@"ads"] )) {
        if (completionHandler) {
            completionHandler(nil, nil, nil);
        }
        return nil;
    }
    return %orig;
}
%end

%ctor {
    %init(GDTSplashAd=objc_getClass("GDTSplashAd"), CSJSplashAd=objc_getClass("CSJSplashAd"), BUSplashAdView=objc_getClass("BUSplashAdView"), BaiduMobAdSplash=objc_getClass("BaiduMobAdSplash"), KSAdSplashViewController=objc_getClass("KSAdSplashViewController"), CMAdManager=objc_getClass("CMAdManager"), UIViewController=objc_getClass("UIViewController"), NSURLSession=objc_getClass("NSURLSession"));
}
