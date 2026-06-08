//
//  XHFloatWindow.h
//  XHFloatingWindow
//
//  Created by Xinhou Jiang on 14/1/17.
//  Copyright © 2017年 Xinhou Jiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface XHFloatWindow : NSObject

+ (BOOL)xh_isShowing;

/* add the floaitng window to the target and the callback block will be excuted when click the button */
+ (void)xh_addWindowOnTarget:(nonnull id)target onClick:(nullable void(^)())callback;
/* you can resize the view's size, 50 by default if you don't set it */
+ (void)xh_setWindowSize:(float)size;
/* you can hide the view or show it again */
+ (void)xh_setHideWindow:(BOOL)hide;
/* you can reset the button's background image of normal and selected states */
+ (void)xh_setBackgroundImage:(nullable NSString *)imageName forState:(UIControlState)UIControlState;
/* you can set the initial position of the floating window */
+ (void)xh_setInitialPosition:(CGPoint)position;
/* set gif animation to play on click, then destroy window after animation */
+ (void)xh_setGifImageName:(nonnull NSString *)gifName playOnClick:(BOOL)playOnClick;
/* get current frame of floating window */
+ (CGRect)xh_getCurrentFrame;
/* destroy the floating window and release resources */
+ (void)xh_destroyWindow;
/* rebuild the floating window (destroy old one and create new one) */
+ (void)xh_rebuildWindowOnTarget:(nonnull id)target onClick:(nullable void(^)())callback;


// 【新增】获取当前是否是缩小模式
+ (BOOL)xh_isShrunk;

// 【新增】直接设置缩小模式（用于旋转屏幕后恢复状态）
+ (void)xh_setShrunk:(BOOL)isShrunk;

+ (BOOL)xh_getSavedShrunkState;

@end
