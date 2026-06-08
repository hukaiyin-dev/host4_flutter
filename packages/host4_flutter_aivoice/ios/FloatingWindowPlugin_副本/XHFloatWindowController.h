//
//  XHFloatWindowController.h
//  XHFloatingWindow
//
//  Created by Xinhou Jiang on 14/1/17.
//  Copyright © 2017年 Xinhou Jiang. All rights reserved.
//

#define kNormalSize 100 * COEFi0
#define kShrunkSize 33 * COEFi0

#import <UIKit/UIKit.h>

@class XHDraggableButton;
@interface XHFloatWindowController : UIViewController

- (void)setRootView;
- (void)setHideWindow:(BOOL)hide;
- (void)setWindowSize:(float)size; // 50 by default
- (void)resetBackgroundImage: (NSString *)imageName forState:(UIControlState)UIControlState;
- (void)setInitialPosition:(CGPoint)position;
- (void)setGifImageName:(NSString *)gifName playOnClick:(BOOL)playOnClick; // set gif animation to play on click
- (CGRect)getCurrentFrame; // get current frame of floating window
- (void)destroy; // destroy floating window

// 【新增】公开当前是否缩小状态，供外部读取（例如在旋转前保存）
@property (nonatomic, assign, readonly) BOOL isShrunk;

// 【新增】提供一个方法强制设置状态（用于旋转后恢复状态）
// isShrunk: 目标状态
// immediately: 是否立即执行（无动画），旋转恢复时通常传 YES
- (void)setShrunkState:(BOOL)isShrunk immediately:(BOOL)immediately;

@end
