// RemoveAds.xm
// 完整无误的开屏及插屏拦截方案
//
#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

/* ======================= 前置类声明 ===================== */
@interface GDTSplashAd : NSObject @end
@interface CSJSplashAd : NSObject @end
@interface BUSplashAd : NSObject @end
@interface KSAdSplashViewController : UIViewController @end
@interface BaiduMobAdSplash :NSObject @end
@interface GADFullScreenAd :NSObject @end
@interface PAGSplashViewController : UIViewController @end
@interface CMSplashManager :NSObject @end
@interface CMSplashViewController : UIViewController @end
@interface CMSplashAd :NSObject @end
@interface CMAdSplashView : UIView @end

/* ===================== 工具函数 ===================== */
static void notifyDelegateClosed(id instance){
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if([instance respondsToSelector:@selector(delegate)]){
        id delegate = [instance performSelector:@selector(delegate)];
        if([delegate respondsToSelector:@selector(splashAdClosed:)])
            [delegate performSelector:@selector(splashAdClosed:) withObject:instance];
        else if([delegate respondsToSelector:@selector(splashAdDidDismissFullScreenContent:)])
            [delegate performSelector:@selector(splashAdDidDismissFullScreenContent:) withObject:instance];
        else if([delegate respondsToSelector:@selector(splashAdDidClose:)])
            [delegate performSelector:@selector(splashAdDidClose:) withObject:instance];
        else if([delegate respondsToSelector:@selector(splashDidDismissScreen:)])
            [delegate performSelector:@selector(splashDidDismissScreen:) withObject:instance];
    }
    #pragma clang diagnostic pop
    if([instance isKindOfClass:[UIView class]])
        [(UIView *)instance setHidden:YES];
    else if([instance isKindOfClass:[UIViewController class]])
        [(UIViewController *)instance view].hidden = YES;
}

static void forceRestoreSubViews(UIView *view){
    if(!view) return;
    for(UIView *sub in view.subviews){
        sub.hidden = NO;
        sub.alpha = 1.0;
        if(sub.subviews.count) forceRestoreSubViews(sub);
    }
}

static UIWindow *get_keyWindow(void){
    UIWindow *found = nil;
    if(@available(iOS 13.0,*)){
        for(UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes){
            if(scene.activationState==UISceneActivationStateForegroundActive){
                for(UIWindow *window in scene.windows){
                    if(window.isKeyWindow){
                        found = window;
                        break;
                    }
                }
            }
            if(found) break;
        }
    }
    if(!found) found = [[UIApplication sharedApplication] valueForKey:@"keyWindow"];
    return found;
}

/* ===================== 动态初始化 ===================== */
%ctor{
    Class GDTSplashAdCls = objc_getClass("GDTSplashAd");
    Class CSJSplashAdCls = objc_getClass("CSJSplashAd");
    Class BUSplashAdCls = objc_getClass("BUSplashAd");
    Class KSAdSplashViewControllerCls = objc_getClass("KSAdSplashViewController");
    Class BaiduMobAdSplashCls = objc_getClass("BaiduMobAdSplash");
    Class GADFullScreenAdCls = objc_getClass("GADFullScreenAd");
    Class PAGSplashViewControllerCls = objc_getClass("PAGSplashViewController");
    Class CMSplashManagerCls = objc_getClass("CMSplashManager");
    Class CMSplashViewControllerCls = objc_getClass("CMSplashViewController");
    Class CMSplashAdCls = objc_getClass("CMSplashAd");
    Class CMAdSplashViewCls = objc_getClass("CMAdSplashView");
    %init(GDTSplashAd=GDTSplashAdCls, CSJSplashAd=CSJSplashAdCls, BUSplashAd=BUSplashAdCls, KSAdSplashViewController=KSAdSplashViewControllerCls, BaiduMobAdSplash=BaiduMobAdSplashCls, GADFullScreenAd=GADFullScreenAdCls, PAGSplashViewController=PAGSplashViewControllerCls, CMSplashManager=CMSplashManagerCls, CMSplashViewController=CMSplashViewControllerCls, CMSplashAd=CMSplashAdCls, CMAdSplashView=CMAdSplashViewCls);
}

/* ===================== SDK 特定 Hook ===================== */
%hook GDTSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window{
    notifyDelegateClosed(self);
}
- (void)loadAd{
    notifyDelegateClosed(self);
}
- (instancetype)init{
    notifyDelegateClosed(self);
    return nil;
}
%end

%hook CSJSplashAd
- (void)loadAdAndShowInWindow:(UIWindow *)window{
    notifyDelegateClosed(self);
}
- (void)loadAd{
    notifyDelegateClosed(self);
}
- (instancetype)init{
    notifyDelegateClosed(self);
    return nil;
}
%end

%hook BUSplashAd
- (instancetype)initWithFrame:(CGRect)frame{
    notifyDelegateClosed(self);
    return nil;
}
- (void)loadAd{
    notifyDelegateClosed(self);
}
%end

%hook KSAdSplashViewController
- (void)viewDidLoad{
    %orig;
    notifyDelegateClosed(self);
}
%end

%hook BaiduMobAdSplash
- (void)loadAd{
    notifyDelegateClosed(self);
}
%end

%hook GADFullScreenAd
- (void)presentFromRootViewController:(UIViewController *)rootViewController{
    notifyDelegateClosed(self);
}
%end

%hook PAGSplashViewController
- (void)viewDidLoad{
    %orig;
    notifyDelegateClosed(self);
}
%end

%hook CMSplashManager
- (instancetype)init{
    notifyDelegateClosed(self);
    return nil;
}
- (void)loadAd{
    notifyDelegateClosed(self);
}
%end

%hook CMSplashViewController
- (void)viewDidLoad{
    %orig;
    notifyDelegateClosed(self);
}
%end

%hook CMSplashAd
- (instancetype)init{
    notifyDelegateClosed(self);
    return nil;
}
- (void)loadAd{
    notifyDelegateClosed(self);
}
%end

%hook CMAdSplashView
- (instancetype)init{
    notifyDelegateClosed(self);
    return nil;
}
- (void)layoutSubviews{
    %orig;
    [(UIView *)self setHidden:YES];
}
%end

/* ===================== UIWindow 监控 ===================== */
%hook UIWindow
- (void)makeKeyAndVisible{
    NSString *cls = NSStringFromClass([self class]);
    if([cls containsString:@"Splash"]||[cls containsString:@"AdWindow"]||
       [cls containsString:@"PAGWindow"]||[cls containsString:@"CSJWindow"])
        return %orig(YES);
    %orig;
}
- (void)becomeKeyWindow{
    NSString *cls = NSStringFromClass([self class]);
    if([cls containsString:@"Splash"]||[cls containsString:@"AdWindow"]||
       [cls containsString:@"PAGWindow"]||[cls containsString:@"CSJWindow"])
        return %orig(YES);
    %orig;
}
- (void)setHidden:(BOOL)hidden{
    NSString *cls = NSStringFromClass([self class]);
    if([cls containsString:@"Splash"]||[cls containsString:@"AdWindow"]||
       [cls containsString:@"PAGWindow"]||[cls containsString:@"CSJWindow"])
        return %orig(YES);
    %orig(hidden);
}
%end

/* ===================== UIViewController 兜底 ===================== */
%hook UIViewController
- (void)viewWillAppear:(BOOL)animated{
    %orig;
    Class cls = [self class];
    NSString *name = NSStringFromClass(cls);
    if([name containsString:@"Splash"]||[name containsString:@"AdViewController"]||
       [name containsString:@"CMAd"]){
        if(((UIViewController *)self).presentingViewController){
            [((UIViewController *)self) dismissViewControllerAnimated:NO completion:nil];
        }
        if([self isKindOfClass:[UIView class]]){
            [(UIView *)self setHidden:YES];
        }else if([self isKindOfClass:[UIViewController class]]){
            ((UIViewController *)self).view.hidden = YES;
        }
    }
}
%end