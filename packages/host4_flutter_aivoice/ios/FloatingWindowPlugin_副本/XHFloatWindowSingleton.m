//
//  XHFloatWindowSingleton.m
//  XHFloatingWindow
//
//  Created by Xinhou Jiang on 14/1/17.
//  Copyright © 2017年 Xinhou Jiang. All rights reserved.
//

#import "XHFloatWindowSingleton.h"
#import "XHFloatWindowController.h"

@implementation XHFloatWindowSingleton

+ (instancetype)Ins {
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
    });
    return sharedInstance;
}

- (void)xh_addWindowOnTarget:(UIViewController *)target onClick:(void (^)())callback {
    
    if (_floatVC){
        [self xh_destroyWindow];
    }
    
    _floatVC = [[XHFloatWindowController alloc] init];
    
    if ([_floatVC respondsToSelector:@selector(setShrunkState:immediately:)]) {
        [_floatVC setShrunkState:self.savedShrunkState immediately:YES];
    }
    
    [target addChildViewController:_floatVC];
    [target.view addSubview:_floatVC.view];
    [_floatVC setRootView];
    _floatWindowCallBack = callback;
    
    self.isShowing = YES;
}

- (void)xh_setWindowSize:(float)size {
    [_floatVC setWindowSize:size];
}

- (void)xh_setHideWindow:(BOOL)hide {
    [_floatVC setHideWindow:hide];
}

- (void)xh_setBackgroundImage:(NSString *)imageName forState:(UIControlState)UIControlState {
    [_floatVC resetBackgroundImage:imageName forState:UIControlState];
}

- (void)xh_setGifImageName:(NSString *)gifName playOnClick:(BOOL)playOnClick {
    [_floatVC setGifImageName:gifName playOnClick:playOnClick];
}

- (CGRect)xh_getCurrentFrame {
    if (_floatVC) {
        return [_floatVC getCurrentFrame];
    }
    return CGRectZero;
}

- (void)xh_setInitialPosition:(CGPoint)position {
    [_floatVC setInitialPosition:position];
}

- (void)xh_destroyWindow {
    if (_floatVC) {
        self.savedShrunkState = _floatVC.isShrunk;
        
        [_floatVC destroy];
        _floatVC = nil;
        _floatWindowCallBack = nil;
        
        self.isShowing = NO;
    }
}

- (void)xh_rebuildWindowOnTarget:(UIViewController *)target onClick:(void (^)())callback {
    // destroy old window first
    [self xh_destroyWindow];
    
    // create new window
    [self xh_addWindowOnTarget:target onClick:callback];
}

// 【新增实现】
- (BOOL)xh_isShrunk {
    if (_floatVC) {
        return _floatVC.isShrunk;
    }
    return NO;
}

- (void)xh_setShrunk:(BOOL)isShrunk {
    if (_floatVC) {
        // 这里的场景通常是恢复状态，所以使用 immediately:YES
        // 如果你需要带动画的切换，可以扩展这个方法参数
        [_floatVC setShrunkState:isShrunk immediately:YES];
    }
}

@end
