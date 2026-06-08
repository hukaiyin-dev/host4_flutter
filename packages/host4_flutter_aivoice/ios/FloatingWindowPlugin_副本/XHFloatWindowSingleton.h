//
//  XHFloatWindowSingleton.h
//  XHFloatingWindow
//
//  Created by Xinhou Jiang on 14/1/17.
//  Copyright © 2017年 Xinhou Jiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^CallBack)();

@class XHFloatWindowController;

@interface XHFloatWindowSingleton : NSObject

@property (nonnull, nonatomic, strong) XHFloatWindowController *floatVC;
@property (nullable, nonatomic, copy)CallBack floatWindowCallBack;

@property (nonatomic, assign) BOOL isShowing;

@property (nonatomic, assign) BOOL savedShrunkState;

// 【新增】
- (BOOL)xh_isShrunk;
- (void)xh_setShrunk:(BOOL)isShrunk;

- (void)xh_addWindowOnTarget: (nonnull id)target onClick:(nullable void(^)())callback;
- (void)xh_setWindowSize:(float)size;
- (void)xh_setHideWindow:(BOOL)hide;
- (void)xh_setBackgroundImage:(nullable NSString *)imageName forState:(UIControlState)UIControlState;
- (void)xh_setGifImageName:(nonnull NSString *)gifName playOnClick:(BOOL)playOnClick; // set gif animation to play on click
- (CGRect)xh_getCurrentFrame; // get current frame of floating window
- (void)xh_setInitialPosition:(CGPoint)position; // set initial position
- (void)xh_destroyWindow; // destroy floating window
- (void)xh_rebuildWindowOnTarget:(nonnull id)target onClick:(nullable void(^)())callback; // rebuild floating window

+ (nonnull instancetype)Ins;

@end
