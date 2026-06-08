//
//  XHFloatWindowController.m
//  XHFloatingWindow
//
//  Created by Xinhou Jiang on 14/1/17.
//  Copyright © 2017年 Xinhou Jiang. All rights reserved.
//

#import "XHFloatWindowController.h"
#import "XHDraggableButton.h"
#import "XHFloatWindowSingleton.h"

@interface XHFloatWindowController ()<UIDragButtonDelegate>

@property (strong,nonatomic) UIWindow *window;
@property (strong,nonatomic) XHDraggableButton *button;

@property (nonatomic, strong)UIImage *imageNormal;
@property (nonatomic, strong)UIImage *imageSelected;

@property (nonatomic, strong)NSString *gifImageName; // GIF image name
@property (nonatomic, assign)BOOL playGifOnClick; // whether to play gif on click

///是否缩小状态
@property (nonatomic, assign) BOOL isShrunk;
///当前位置
@property (nonatomic, assign) xh_EdgeType currentEdgeType;

@end

@implementation XHFloatWindowController

- (void)viewDidLoad {
    [super viewDidLoad];
    // hide the root view
    self.view.frame = CGRectZero;
    // create floating window button
    [self createButton];
    // register UIDeviceOrientationDidChangeNotification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

/**
 * create floating window and button
 */
- (void)createButton
{
    // 1.floating button
    _button = [XHDraggableButton buttonWithType:UIButtonTypeCustom];
    [self resetBackgroundImage:@"default_normal" forState:UIControlStateNormal];
    [self resetBackgroundImage:@"default_selected" forState:UIControlStateSelected];
    _button.imageView.contentMode = UIViewContentModeScaleAspectFill;
    _button.frame = CGRectMake(0, 0, kNormalSize, kNormalSize);
    _button.buttonDelegate = self;
    _button.initOrientation = [UIApplication sharedApplication].statusBarOrientation;
    _button.originTransform = _button.transform;
    
    // 2.floating window
    _window = [[UIWindow alloc] init];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    _window.frame = CGRectMake(screenWidth - kNormalSize, 65 * COEFi0, kNormalSize, kNormalSize);
    _window.windowLevel = UIWindowLevelAlert+1;
    _window.backgroundColor = [UIColor clearColor];
    _window.layer.cornerRadius = kNormalSize / 2;
    _window.layer.masksToBounds = YES;
    [_window addSubview:_button];
    [_window makeKeyAndVisible];
    
    // Initialize edge type
    self.currentEdgeType = xh_EdgeRight;
}

/**
 * set rootview
 */
- (void)setRootView {
    _button.rootView = self.view.superview;
}

/**
 *  floating button clicked
 */
- (void)dragButtonClicked:(UIButton *)sender {
    // 如果是缩小状态，点击先恢复，不执行业务回调
    if (self.isShrunk) {
        [self recoverToNormalState];
        return;
    }
    
    sender.selected = !sender.selected;
    if (sender.selected) {
        [sender setBackgroundImage:_imageSelected forState:UIControlStateSelected];
    }
    else {
        [sender setBackgroundImage:_imageNormal forState:UIControlStateNormal];
    }
    
    // click callback
    [XHFloatWindowSingleton Ins].floatWindowCallBack();
}

/**
 * reset window hiden
 */
- (void)setHideWindow:(BOOL)hide {
    _window.hidden = hide;
}

/**
 * reset floating window size
 */
- (void)setWindowSize:(float)size {
    CGRect rect = _window.frame;
    _window.frame = CGRectMake(rect.origin.x, rect.origin.y, size, size);
    _button.frame = CGRectMake(0, 0, size, size);
    
    self.window.layer.cornerRadius = size / 2.0;
    
    [self.view setNeedsLayout];
}

/**
 * reset button background image
 */
- (void)resetBackgroundImage:(NSString *)imageName forState:(UIControlState)UIControlState {
    UIImage *image = [UIImage imageNamed:imageName];
    switch (UIControlState) {
        case UIControlStateNormal:
            _imageNormal = image;
            break;
        case UIControlStateSelected:
            _imageSelected = image;
            break;
            
        default:
            break;
    }
    [_button setBackgroundImage:image forState:UIControlState];
}

/**
 * move window to top right corner
 */
- (void)moveToTopRight {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGRect rect = _window.frame;
    _window.frame = CGRectMake(screenWidth - rect.size.width - 20 * COEFi0, 65 * COEFi0, rect.size.width, rect.size.height);
}

/**
 * notification
 */
- (void)orientationChange:(NSNotification *)notification {
    // 延迟0.3秒后调整位置（等待屏幕旋转动画完成）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self adaptToNewOrientation];
    });
}

/**
 * Adapt window position to new orientation
 */
- (void)adaptToNewOrientation {
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    BOOL isPortrait = screenHeight > screenWidth;
    
    // 强制恢复为大球状态
    if (self.isShrunk) {
        self.isShrunk = NO;
        self.currentEdgeType = xh_EdgeNone;
        
        CGRect bounds = self.window.bounds;
        bounds.size = CGSizeMake(kNormalSize, kNormalSize);
        self.window.bounds = bounds;
        self.button.frame = self.window.bounds;
        self.window.layer.cornerRadius = kNormalSize / 2.0;
        [self.button setBackgroundImage:self.imageNormal forState:UIControlStateNormal];
    }
    
    CGFloat newX, newY;
    
    if (isPortrait) {
        // 竖屏：下方居中
        newX = (screenWidth - kNormalSize) / 2.0;
        newY = screenHeight - kNormalSize - LS_Margin_32; // 距离底部100，可根据需要调整
    } else {
        // 横屏：右上方
        newX = screenWidth - kNormalSize - LS_Margin_16; // 距离右边20
        newY = 65 * COEFi0; // 保持原本初始化时的Y轴或您期望的高度
    }
    
    self.window.frame = CGRectMake(newX, newY, kNormalSize, kNormalSize);
}

/**
 * destroy floating window
 */
- (void)destroy {
    // remove notification observer
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // remove button from window
    [_button removeFromSuperview];
    _button = nil;
    
    // hide and remove window
    _window.hidden = YES;
    _window = nil;
    
    // remove from parent view controller
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

/**
 * set initial position of floating window
 */
- (void)setInitialPosition:(CGPoint)position {
    CGRect rect = _window.frame;
    _window.frame = CGRectMake(position.x, position.y, rect.size.width, rect.size.height);
    
}

/**
 * get current frame of floating window
 */
- (CGRect)getCurrentFrame {
    if (_window) {
        return _window.frame;
    }
    return CGRectZero;
}

/**
 * set gif image name and whether to play on click
 */
- (void)setGifImageName:(NSString *)gifName playOnClick:(BOOL)playOnClick {
    _gifImageName = gifName;
    
    _playGifOnClick = playOnClick;
    
    NSLog(@"🎬 已设置GIF动画: %@, 点击播放: %@", gifName, playOnClick ? @"是" : @"否");
}

//新增
- (void)dragButtonDidEndDrag:(UIButton *)button edgeType:(xh_EdgeType)edgeType {
    
    self.currentEdgeType = edgeType;
        
    // 【核心修改点】：如果当前是缩小状态
    if (self.isShrunk) {
        // 需求：拖动到哪里就停在哪里，并且变大
        // 所以这里不再判断 edgeType，直接执行“原地恢复”
        [self recoverToNormalStateAtCurrentPosition];
        return; // 变大后直接返回，不再执行后续的“贴边变小”逻辑
    }
    
    // 如果当前已经是大球状态，且拖到了边缘，则执行变小逻辑（保留原有逻辑）
    if (edgeType == xh_EdgeLeft || edgeType == xh_EdgeRight) {
        [self shrinkWindowToEdge:edgeType];
    }
}

// 执行缩小动画
- (void)shrinkWindowToEdge:(xh_EdgeType)type {
    if (self.isShrunk) return; // 已经是小的就不重复操作
    
    self.isShrunk = YES;
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width; // 注意横竖屏适配获取正确的W
    CGPoint currentCenter = self.window.center;
    
    // 计算缩小后的新中心点
    // 原来是 100x100 (center=50)，现在变成 24x24 (center=12)
    // 如果不调整 center，它会向中心收缩，导致离开屏幕边缘
    CGPoint targetCenter = currentCenter;
    
    if (type == xh_EdgeLeft) {
        targetCenter.x = kShrunkSize / 2.0; // 紧贴左边
    } else {
        // 获取当前屏幕宽度，注意这里的获取方式要和你 Button 里的逻辑一致，适配横屏
        if (screenWidth < [UIScreen mainScreen].bounds.size.height) {
             // 简单的修正逻辑，具体视你项目横竖屏逻辑定
        }
        
        targetCenter.x = screenWidth - (kShrunkSize / 2.0); // 紧贴右边
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        // 1. 改变 Frame 大小
        CGRect bounds = self.window.bounds;
        bounds.size = CGSizeMake(kShrunkSize, kShrunkSize);
        self.window.bounds = bounds;
        self.button.frame = self.window.bounds;
        
        // 2. 移动到新的贴边位置
        self.window.center = targetCenter;
        self.window.layer.cornerRadius = kShrunkSize / 2.0;
    }];
}

// 恢复正常大小
- (void)recoverToNormalState {
    self.isShrunk = NO;
    self.currentEdgeType = xh_EdgeNone; // 恢复后视为不在边缘，或者等待下次拖拽判断
    
    CGPoint currentCenter = self.window.center;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    // 恢复大小时，也要修正 Center，让它向屏幕内膨胀，而不是向屏幕外
    CGPoint targetCenter = currentCenter;
    
    // 如果之前是在左边缩小的
    if (currentCenter.x < screenWidth / 2.0) {
        targetCenter.x = kNormalSize / 2.0;
    } else {
        // 在右边
        targetCenter.x = screenWidth - (kNormalSize / 2.0);
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        CGRect bounds = self.window.bounds;
        bounds.size = CGSizeMake(kNormalSize, kNormalSize);
        self.window.bounds = bounds;
        self.button.frame = self.window.bounds;
        
        self.window.center = targetCenter;
        self.window.layer.cornerRadius = kNormalSize / 2.0;
    }];
}

// 在当前位置恢复成正常大小（不强制归位到屏幕边缘）
- (void)recoverToNormalStateAtCurrentPosition {
    self.isShrunk = NO;
    self.currentEdgeType = xh_EdgeNone;
    
    // 1. 获取当前中心点
    CGPoint currentCenter = self.window.center;
    CGFloat screenW = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenH = [UIScreen mainScreen].bounds.size.height;
    
    // 2. 边界修正
    // 因为从小球变大球，如果不修正，大球可能会超出屏幕边界
    CGFloat halfNormal = kNormalSize / 2.0;
    
    // 修正 X 轴
    if (currentCenter.x < halfNormal) currentCenter.x = halfNormal;
    if (currentCenter.x > screenW - halfNormal) currentCenter.x = screenW - halfNormal;
    
    // 修正 Y 轴 (防止变大后盖住状态栏或超出底部)
    if (currentCenter.y < halfNormal) currentCenter.y = halfNormal;
    if (currentCenter.y > screenH - halfNormal) currentCenter.y = screenH - halfNormal;
    
    // 3. 执行动画
    [UIView animateWithDuration:0.25 animations:^{
        // 恢复 Frame 大小
        CGRect bounds = self.window.bounds;
        bounds.size = CGSizeMake(kNormalSize, kNormalSize);
        self.window.bounds = bounds;
        self.button.frame = self.window.bounds;
        
        // 设置修正后的中心点
        self.window.center = currentCenter;
        
        // 恢复透明度和样式
        [self.button setBackgroundImage:self.imageNormal forState:UIControlStateNormal];
    }];
}

- (void)setShrunkState:(BOOL)isShrunk immediately:(BOOL)immediately {
    if (self.isShrunk == isShrunk) return;
    
    self.isShrunk = isShrunk;
    
    CGFloat targetSize = isShrunk ? kShrunkSize : kNormalSize;
    
    // 在设置状态时，我们需要确保 Frame 大小正确更新
    // 注意：这里我们只更新 Size，Center 位置由当前的 Center 决定，或者由外部重新布局
    
    CGFloat targetCornerRadius = targetSize / 2.0;
    
    void (^updateBlock)(void) = ^{
        CGRect bounds = self.window.bounds;
        bounds.size = CGSizeMake(targetSize, targetSize);
        self.window.bounds = bounds;
        self.button.frame = self.window.bounds;
        
        // 如果是恢复缩小状态，可能需要简单的边界修正（防止变大变小过程中中心点偏移导致出界）
        // 这里简单调用一下 button 的逻辑来确保在屏幕内
        // 注意：因为是 Controller 控制，我们手动修正一下 frame
        // (此处省略复杂的边界计算，直接应用即可，View 自身的 layout 机制会处理)
        self.window.layer.cornerRadius = targetCornerRadius;
        self.window.layer.masksToBounds = YES;
    };
    
    if (immediately) {
        updateBlock();
        // 立即执行时，可能需要移除所有动画
        [self.window.layer removeAllAnimations];
    } else {
        [UIView animateWithDuration:0.25 animations:updateBlock];
    }
}

@end
