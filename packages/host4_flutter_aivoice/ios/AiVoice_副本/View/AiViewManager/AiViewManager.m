//
//  AiViewManager.m
//  GameMacro
//
//  Created by 敬攀 on 2025/12/16.
//

#import "AiViewManager.h"
#import "XHFloatWindow.h"
#import "XHFloatWindowController.h"
#import "AiVoiceManager.h"
#import "FrameAnimationView.h"
#import "FrameAnimationView+Animations.h"
#import "ChatAssistantView.h"
#import "UserSignInVC.h"


@interface AiViewManager()<ChatAssistantViewDelegate>

@end

static AiViewManager *viewManager = nil;

@implementation AiViewManager

+(AiViewManager *)shared{
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        viewManager = [[AiViewManager alloc] init];
        
        //初始状态都是FloatingState
        viewManager.floatState = FloatingState;
    });
    
    return viewManager;
}

#pragma mark - 悬浮球
-(void)showFloatWindow:(BOOL)isshow{
    
    NSLog(@"显示悬浮球 floatState: %ld", (long)self.floatState);
    
    BaseVC *target = (BaseVC *)[TheGlobalMethod getCurrentVC];
    
    if (!isshow){
        //不显示的时候直接销毁
        [XHFloatWindow xh_destroyWindow];

        if ([ChatAssistantView shared].isShowing){
            [[ChatAssistantView shared] hide];
        }
        
        return;
    }
    
    if (self.floatState != FloatingState){
        //聊天状态,显示聊天
        [self showChatFloatCustomView];
    }else{
        //悬浮窗状态
        kWeakSelf(self)
        
        if ([XHFloatWindow xh_isShowing]){
            return;
        }
        
        [XHFloatWindow xh_addWindowOnTarget:target onClick:^{
            
            if ([weakself isPushNothing]){
                [MBProgressHUD showMsg:kLocalizedString(@"LoginAndUse", nil) toView:KEY_WINDOW];
            }else{
                CGRect frame = [XHFloatWindow xh_getCurrentFrame];
                
                [XHFloatWindow xh_destroyWindow];

                [self playAnimalImage:frame];
            }
        }];
        
        //根据缩小放大状态
        BOOL isShrunk = [XHFloatWindow xh_getSavedShrunkState];
        
        CGFloat floatWidth;
        
        if (isShrunk){
            //缩小状态
            floatWidth = kShrunkSize;
        }else{
            //放大状态
            floatWidth = kNormalSize;
        }
        
        [XHFloatWindow xh_setWindowSize:floatWidth];
        
        [XHFloatWindow xh_setBackgroundImage:@"AINotClick" forState:(UIControlStateNormal)];
        
        if (SCREEN_H > SCREEN_W){
            //竖屏(默认显示横屏放大状态)
            [XHFloatWindow xh_setInitialPosition:CGPointMake((SCREEN_MIN - floatWidth) / 2, SCREEN_MAX - 100 * COEFi0 - floatWidth / 2)];
        }else{
            if (isShrunk){
                //横屏放大
                [XHFloatWindow xh_setInitialPosition:CGPointMake(SCREEN_MAX - floatWidth, 65 * COEFi0)];
            }
        }
        
    }
}

//帧动画视图
- (void)playAnimalImage:(CGRect)frame{
    
    //如果没有登陆，那么跳转登陆
    if (![TheGlobalMethod getModelInLocal:GMUserModel]){
        //跳转登陆
        [self pushController:0];
        
        return;
    }
    
    FrameAnimationView *view = [[FrameAnimationView alloc] initWithImagePrefix:@"思考状态-出现_" startIndex:0 count:124 numberFormat:@"%05d" extension:@"png"];
    
    view.frameRate = 40;
    
    view.animationMode = FrameAnimationModeOnce;
    
    [KEY_WINDOW addSubview:view];
      
    CGPoint center = CGPointMake(frame.origin.x + frame.size.width / 2, frame.origin.y + frame.size.height / 2);
    
    [view animateFromCenter:center toSize:CGSizeMake(100 * COEFi0, 100 * COEFi0) duration:3 damping:3 autoPlay:YES completion:^{
        //动画结束，销毁视图，并创建聊天视图
        [self showFloatWindow:NO];
        
        [view removeFromSuperview];
        
        self.floatState = ChatMinimized;
        
        [self showChatFloatCustomView];
    }];
}

//聊天界面
-(void)showChatFloatCustomView{
    [AIVoiceShared buildRTCEngine];
    
    [ChatAssistantView shared].delegate = self;
    
    switch (self.floatState) {
        case ChatMinimized:
            [[ChatAssistantView shared] showMinimizedAtScreen];
            break;
            
        case ChatExpanded:
            [[ChatAssistantView shared] showExpandedAtScreen];
            break;
            
        default:
            break;
    }
}

-(void)setFloatState:(AiFloatingViewState)floatState{
    _floatState = floatState;
}

#pragma mark - ChatAssistantViewDelegate

//关闭按钮
-(void)chatAssistantViewCloseButtonTapped:(ChatAssistantView *)view{
    
    [self showFloatWindow:NO];
    
    [ChatAssistantView destroy];
    
    [AIVoiceShared destructionRTCEngine];
    
    [AiViewManager shared].floatState = FloatingState;
    
    QueueStartAfterTime(.5)
    
    [AIVoiceShared destructionRTCEngine];
    
    [self showFloatWindow:YES];
    
    queueEnd
}

//音量按钮
-(void)chatAssistantViewVolumeButtonTapped:(ChatAssistantView *)view isSec:(BOOL)isSec{

    [AIVoiceShared switchVoiceVolume:!isSec];
}

- (void)chatAssistantViewVipButtonTapped:(ChatAssistantView *)view{
    //跳转vip
    [self pushController:1];
}

//-(void)pushController:(int)type{
////    BOOL isDelay = SCREEN_W > SCREEN_H;
////    
////    if (isDelay){
////        [[LandscapeStatusView shareView] hiddenView];
////        
////        [[LandscapeToolBar shareToolBar] hiddenView];
////    }
//
//    BaseVC *currentVC = (BaseVC *)[TheGlobalMethod getCurrentController];
//    
//    if (type == 0){
//        //登陆界面
////        UserSignInVC *signVC = [[UserSignInVC alloc] initWithDelay:isDelay];
//        UserSignInVC *signVC = [[UserSignInVC alloc] init];
//        
//        [currentVC.navigationController pushViewController:signVC animated:YES];
//        
////        signVC.popController = ^{
////            [self showFloatWindow:NO];
////            
////            QueueStartAfterTime(.5)
////            
////            [self showFloatWindow:YES];
////            
////            queueEnd
////        };
//    }
//    
//    if (type == 1){
//        //vip界面
//        
//        if (!isStringEmpty([HttpRequrst shareManager].appM.H5_VIP)){
//            
////            WKViewController *webVC = [[WKViewController alloc] initWithUrl:[HttpRequrst shareManager].appM.H5_VIP isShowNav:NO isDelay:isDelay];
//            WKViewController *webVC = [[WKViewController alloc] initWithUrl:[HttpRequrst shareManager].appM.H5_VIP isShowNav:NO isDelay:NO];
//            
//            [currentVC.navigationController pushViewController:webVC animated:YES];
//            
////            webVC.popController = ^{
////                [self showFloatWindow:NO];
////                
////                currentVC.isLaunchScreen = YES;
////                
////                QueueStartAfterTime(.5)
////                
////                [self showFloatWindow:YES];
////                
////                queueEnd
////            };
//        }
//    }
//    
//    [self showFloatWindow:NO];
//    
//    [ChatAssistantView destroy];
//    
//    [AIVoiceShared destructionRTCEngine];
//    
//    [AiViewManager shared].floatState = FloatingState;
//    
////    CGFloat delayTime = isDelay ? 1 : 0;
//    
////    QueueStartAfterTime(delayTime)
//    
//    [self showFloatWindow:YES];
//    
////    queueEnd
//    
//}

-(void)pushController:(int)type{
    UINavigationController *nav = [TheGlobalMethod getCurrentNavController];
    
    if (!nav) {
        [MBProgressHUD showMsg:@"导航控制器未就绪"];
        return;
    }

    // 获取当前显示的VC
    UIViewController *topVC = nav.topViewController;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self showFloatWindow:YES];
        
        if (type == 0){
            // 已经是登录页就不再 push
            if ([topVC isKindOfClass:[UserSignInVC class]]) {
                return;
            }
            
            UserSignInVC *signVC = [[UserSignInVC alloc] init];
            [nav pushViewController:signVC animated:YES];
        }
        if (type == 1){
            if (!isStringEmpty([HttpRequrst shareManager].appM.H5_VIP)){
                // 已经是 VIP 页就不再 push
                if ([topVC isKindOfClass:[WKViewController class]]) {
                    return;
                }
                
                WKViewController *webVC = [[WKViewController alloc] initWithUrl:[HttpRequrst shareManager].appM.H5_VIP isShowNav:NO isDelay:NO];
                [nav pushViewController:webVC animated:YES];
            }
        }
        
//        [self showFloatWindow:NO];
//        [ChatAssistantView destroy];
//        [AIVoiceShared destructionRTCEngine];
//        [AiViewManager shared].floatState = FloatingState;
//        [self showFloatWindow:YES];
        
    });
}

-(BOOL)isPushNothing{
    BaseVC *currentVC = (BaseVC *)[TheGlobalMethod getCurrentController];
    
    if (![TheGlobalMethod getModelInLocal:GMUserModel] && [currentVC isKindOfClass:[UserSignInVC class]]){
        //跳转登陆
        return YES;
    }
    
    return NO;
}

@end
