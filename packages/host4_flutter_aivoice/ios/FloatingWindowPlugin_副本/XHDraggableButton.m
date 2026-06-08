//
//  XHDraggableButton.m
//  XHFloatingWindow
//

#import "XHDraggableButton.h"

#define xh_ScreenH [UIScreen mainScreen].bounds.size.height
#define xh_ScreenW [UIScreen mainScreen].bounds.size.width

#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_PAD (UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad)

@interface XHDraggableButton()

@property (nonatomic, assign)CGPoint touchStartPosition;

@end

@implementation XHDraggableButton

typedef NS_ENUM(NSInteger ,xh_FloatWindowDirection) {
    xh_FloatWindowLEFT,
    xh_FloatWindowRIGHT,
    xh_FloatWindowTOP,
    xh_FloatWindowBOTTOM
};

typedef NS_ENUM(NSInteger, xh_ScreenChangeOrientation) {
    xh_Change2Origin,
    xh_Change2Upside,
    xh_Change2Left,
    xh_Change2Right
};

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    self.touchStartPosition = [touch locationInView:_rootView];
    
    if(IS_IPHONE) self.touchStartPosition = [self ConvertDir:_touchStartPosition];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint curPoint = [touch locationInView:_rootView];
    if(IS_IPHONE) curPoint = [self ConvertDir:curPoint];
    self.superview.center = curPoint;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint curPoint = [touch locationInView:_rootView];
    
    if(IS_IPHONE) curPoint = [self ConvertDir:curPoint];
    // if the start touch point is too close to the end point, take it as the click event and notify the click delegate
    if (pow((_touchStartPosition.x - curPoint.x),2) + pow((_touchStartPosition.y - curPoint.y),2) < 1) {
        [self.buttonDelegate dragButtonClicked:self];
        return;
    }
    
    //调用新的松手处理逻辑
    [self handleTouchEnd:curPoint];
}

-(void)buttonAutoAdjust:(CGPoint)curPoint {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat W = xh_ScreenW;
    CGFloat H = xh_ScreenH;
    // (1,2->3,4 | 3,4->1,2)
    NSInteger judge = orientation + _initOrientation;
    // Remove old logic that swapped W/H incorrectly
    
    CGFloat halfWidth = self.superview.frame.size.width / 2;
    CGFloat halfHeight = self.superview.frame.size.height / 2;
    
    // 检查按钮中心是否在屏幕范围内
    BOOL isInBounds = (curPoint.x >= halfWidth &&
                       curPoint.x <= W - halfWidth &&
                       curPoint.y >= halfHeight &&
                       curPoint.y <= H - halfHeight);
    
    // 如果按钮中心在屏幕范围内，不需要调整位置
    if (isInBounds) {
        return;
    }
    
    // 如果按钮中心超出屏幕范围，找到最近的边缘并停靠
    // distances to the four screen edges
    CGFloat left = curPoint.x;
    CGFloat right = IS_IPHONE ? (W - curPoint.x) : (xh_ScreenW - curPoint.x);
    CGFloat top = curPoint.y;
    CGFloat bottom = IS_IPHONE ? (H - curPoint.y) : (xh_ScreenH - curPoint.y);
    // find the direction to go
    xh_FloatWindowDirection minDir = xh_FloatWindowLEFT;
    CGFloat minDistance = left;
    if (right < minDistance) {
        minDistance = right;
        minDir = xh_FloatWindowRIGHT;
    }
    if (top < minDistance) {
        minDistance = top;
        minDir = xh_FloatWindowTOP;
    }
    if (bottom < minDistance) {
        minDir = xh_FloatWindowBOTTOM;
    }
    
    switch (minDir) {
        case xh_FloatWindowLEFT: {
            [UIView animateWithDuration:0.3 animations:^{
                self.superview.center = CGPointMake(self.superview.frame.size.width/2, self.superview.center.y);
            }];
            break;
        }
        case xh_FloatWindowRIGHT: {
            [UIView animateWithDuration:0.3 animations:^{
                self.superview.center = CGPointMake(W - self.superview.frame.size.width/2, self.superview.center.y);
            }];
            break;
        }
        case xh_FloatWindowTOP: {
            [UIView animateWithDuration:0.3 animations:^{
                self.superview.center = CGPointMake(self.superview.center.x, self.superview.frame.size.height/2);
            }];
            break;
        }
        case xh_FloatWindowBOTTOM: {
            [UIView animateWithDuration:0.3 animations:^{
                self.superview.center = CGPointMake(self.superview.center.x, H - self.superview.frame.size.height/2);
            }];
            break;
        }
        default:
            break;
    }
}

- (void)buttonRotate {
//    [self buttonAutoAdjust:self.center];
    
    if(IS_IPHONE){
        xh_ScreenChangeOrientation change2orien = [self screenChange];
        switch (change2orien) {
            case xh_Change2Origin:
                self.transform = _originTransform;
                break;
            case xh_Change2Left:
                self.transform = _originTransform;
                self.transform = CGAffineTransformMakeRotation(-90*M_PI/180.0);
                break;
            case xh_Change2Right:
                self.transform = _originTransform;
                self.transform = CGAffineTransformMakeRotation(90*M_PI/180.0);
                break;
            case xh_Change2Upside:
                self.transform = _originTransform;
                self.transform = CGAffineTransformMakeRotation(180*M_PI/180.0);
                break;
            default:
                break;
        }
    }
}

/**
 *  convert to the origin coordinate
 *
 *  UIInterfaceOrientationPortrait           = 1
 *  UIInterfaceOrientationPortraitUpsideDown = 2
 *  UIInterfaceOrientationLandscapeRight     = 3
 *  UIInterfaceOrientationLandscapeLeft      = 4
 */
- (CGPoint)ConvertDir:(CGPoint)p {
    return p;
}

- (xh_ScreenChangeOrientation)screenChange {
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    // 1. xh_Change2Origin(1->1 | 2->2 | 3->3 | 4->4)
    if (_initOrientation == orientation) return xh_Change2Origin;
    
    // 2. xh_Change2Upside(1->2 | 2->1 | 4->3 | 3->4)
    NSInteger isUpside = orientation + _initOrientation;
    
    if (isUpside == 3 || isUpside == 7) return xh_Change2Upside;
    
    // 3. xh_Change2Left(1->4 | 4->2 | 2->3 | 3->1)
    // 4. xh_Change2Right(1->3 | 3->2 | 2->4 | 4->1)
    xh_ScreenChangeOrientation change2orien = 0;
    switch (_initOrientation) {
        case UIInterfaceOrientationPortrait:
            if (orientation == UIInterfaceOrientationLandscapeLeft)
                change2orien = xh_Change2Left;
            else if(orientation == UIInterfaceOrientationLandscapeRight)
                change2orien = xh_Change2Right;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            if (orientation == UIInterfaceOrientationLandscapeRight)
                change2orien = xh_Change2Left;
            else if(orientation == UIInterfaceOrientationLandscapeLeft)
                change2orien = xh_Change2Right;
            break;
        case UIInterfaceOrientationLandscapeRight:
            if (orientation == UIInterfaceOrientationPortrait)
                change2orien = xh_Change2Left;
            else if(orientation == UIInterfaceOrientationPortraitUpsideDown)
                change2orien = xh_Change2Right;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            if (orientation == UIInterfaceOrientationPortraitUpsideDown)
                change2orien = xh_Change2Left;
            else if(orientation == UIInterfaceOrientationPortrait)
                change2orien = xh_Change2Right;
            break;
            
        default:
            break;
    }
    return change2orien;
}

- (CGPoint)UpsideDown:(CGPoint)p {
    return CGPointMake(xh_ScreenW - p.x, xh_ScreenH - p.y);
}

- (CGPoint)LandscapeLeft:(CGPoint)p {
    return CGPointMake(p.y, xh_ScreenW - p.x);
}

- (CGPoint)LandscapeRight:(CGPoint)p {
    return CGPointMake(xh_ScreenH - p.y, p.x);
}

//新增
- (void)handleTouchEnd:(CGPoint)curPoint {
    CGFloat W = IS_IPHONE ? xh_ScreenW : xh_ScreenW; // 简写，实际根据你的旋转逻辑取值
    CGFloat H = IS_IPHONE ? xh_ScreenH : xh_ScreenH;
    
    // 这里处理旋转时的宽高互换逻辑 (沿用你之前的逻辑)
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    NSInteger judge = orientation + _initOrientation;
    // Remove old logic that swapped W/H incorrectly
    
    // 获取当前 View 的宽高的一半
    CGFloat halfWidth = self.superview.frame.size.width / 2.0;
    CGFloat halfHeight = self.superview.frame.size.height / 2.0;
    
    // 1. 边界限制（防止拖出屏幕外）
    // 如果不需要吸附，至少要保证不能把球拖到屏幕外面看不见的地方
    CGPoint targetCenter = self.superview.center;
    
    // 修正 X 轴
    if (targetCenter.x < halfWidth) targetCenter.x = halfWidth;
    if (targetCenter.x > W - halfWidth) targetCenter.x = W - halfWidth;
    
    // 修正 Y 轴
    if (targetCenter.y < halfHeight) targetCenter.y = halfHeight;
    if (targetCenter.y > H - halfHeight) targetCenter.y = H - halfHeight;
    
    // 执行位置修正动画（如果有超出边界，弹回来；如果没有超出，这里几乎不动）
    [UIView animateWithDuration:0.2 animations:^{
        self.superview.center = targetCenter;
    } completion:^(BOOL finished) {
        // 动画结束后，检测是否在边缘
        [self checkEdgeStatus:targetCenter screenWidth:W];
    }];
}

- (void)checkEdgeStatus:(CGPoint)currentCenter screenWidth:(CGFloat)width {
    CGFloat halfWidth = self.superview.frame.size.width / 2.0;
    
    // 定义一个阈值，比如距离边缘小于 5 像素就算贴边
    CGFloat threshold = 5.0;
    
    xh_EdgeType type = xh_EdgeNone;
    
    // 判断是否贴左边 (center.x 接近 halfWidth)
    if (currentCenter.x <= halfWidth + threshold) {
        type = xh_EdgeLeft;
    }
    // 判断是否贴右边
    else if (currentCenter.x >= width - halfWidth - threshold) {
        type = xh_EdgeRight;
    }
    
    // 通知代理
    if ([self.buttonDelegate respondsToSelector:@selector(dragButtonDidEndDrag:edgeType:)]) {
        [self.buttonDelegate dragButtonDidEndDrag:self edgeType:type];
    }
}
@end
