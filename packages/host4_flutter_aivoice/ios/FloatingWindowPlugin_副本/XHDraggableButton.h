//
//  XHDraggableButton.h
//  XHFloatingWindow
//
//  Created by Xinhou Jiang on 14/1/17.
//  Copyright © 2017年 Xinhou Jiang. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * to avoid event collision between button click and pan,here touch event is adopted 
 * to deal with both click and pan event
 */

// 方向枚举（用于给Controller判断是左边还是右边）
typedef NS_ENUM(NSInteger, xh_EdgeType) {
    xh_EdgeNone,  // 没有贴边（在中间）
    xh_EdgeLeft,  // 贴左边
    xh_EdgeRight  // 贴右边
};


@protocol UIDragButtonDelegate <NSObject>

//代理方法：通知控制器点击事件
- (void)dragButtonClicked:(UIButton *)sender;

//通知控制器拖拽结束，告知当前是否处于边缘状态
- (void)dragButtonDidEndDrag:(UIButton *)button edgeType:(xh_EdgeType)edgeType;

@end

@interface XHDraggableButton : UIButton

@property (nonatomic, strong)UIView *rootView;
@property (nonatomic, weak)id<UIDragButtonDelegate>buttonDelegate;
@property (nonatomic, assign)UIInterfaceOrientation initOrientation;
@property (nonatomic, assign)CGAffineTransform originTransform;

- (void)buttonRotate;

@end
