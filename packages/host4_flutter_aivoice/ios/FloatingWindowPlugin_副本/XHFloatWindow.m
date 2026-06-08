//
//  XHFloatWindow.m
//  XHFloatingWindow
//
//  Created by Xinhou Jiang on 14/1/17.
//  Copyright © 2017年 Xinhou Jiang. All rights reserved.
//

#import "XHFloatWindow.h"
#import "XHFloatWindowSingleton.h"
#import "XHFloatWindowController.h"

@interface XHFloatWindow ()

@end

@implementation XHFloatWindow

+(BOOL)xh_isShowing{
    return [[XHFloatWindowSingleton Ins] isShowing];
}

+ (void)xh_addWindowOnTarget:(id)target onClick:(void (^)())callback {
    [[XHFloatWindowSingleton Ins] xh_addWindowOnTarget:target onClick:callback];
}

+ (void)xh_setWindowSize:(float)size {
    [[XHFloatWindowSingleton Ins] xh_setWindowSize:size];
}

+ (void)xh_setHideWindow:(BOOL)hide {
    [[XHFloatWindowSingleton Ins] xh_setHideWindow:hide];
}

+ (void)xh_setBackgroundImage:(NSString *)imageName forState:(UIControlState)UIControlState {
    [[XHFloatWindowSingleton Ins] xh_setBackgroundImage:imageName forState:UIControlState];
}

+ (void)xh_setGifImageName:(NSString *)gifName playOnClick:(BOOL)playOnClick {
    [[XHFloatWindowSingleton Ins] xh_setGifImageName:gifName playOnClick:playOnClick];
}

+ (CGRect)xh_getCurrentFrame {
    return [[XHFloatWindowSingleton Ins] xh_getCurrentFrame];
}

+ (void)xh_setInitialPosition:(CGPoint)position {
    [[XHFloatWindowSingleton Ins] xh_setInitialPosition:position];
}

+ (void)xh_destroyWindow {
    [[XHFloatWindowSingleton Ins] xh_destroyWindow];
}

+ (void)xh_rebuildWindowOnTarget:(id)target onClick:(void (^)())callback {
    [[XHFloatWindowSingleton Ins] xh_rebuildWindowOnTarget:target onClick:callback];
}

+ (BOOL)xh_isShrunk {
    return [[XHFloatWindowSingleton Ins] xh_isShrunk];
}

+ (void)xh_setShrunk:(BOOL)isShrunk {
    [[XHFloatWindowSingleton Ins] xh_setShrunk:isShrunk];
}

+ (BOOL)xh_getSavedShrunkState {
    // 如果窗口正在显示，直接返回当前状态
    if ([XHFloatWindowSingleton Ins].floatVC) {
        return [XHFloatWindowSingleton Ins].floatVC.isShrunk;
    }
    
    // 如果窗口已销毁，返回缓存的状态
    return [XHFloatWindowSingleton Ins].savedShrunkState;
}
@end
