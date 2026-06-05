//
//  ChatAssistantView.h
//  内置完整UI的AI对话助手视图
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 屏幕位置
typedef NS_ENUM(NSInteger, ChatAssistantPosition) {
    ChatAssistantPositionTop,          // 顶部居中
    ChatAssistantPositionBottom,       // 底部居中
    ChatAssistantPositionTopLeft,      // 左上角
    ChatAssistantPositionTopRight,     // 右上角
    ChatAssistantPositionBottomLeft,   // 左下角
    ChatAssistantPositionBottomRight,  // 右下角
    ChatAssistantPositionCenter,       // 屏幕中心
    ChatAssistantPositionCustom        // 自定义位置
};

@class ChatAssistantView;

@protocol ChatAssistantViewDelegate <NSObject>

@optional

/// 关闭按钮被点击
- (void)chatAssistantViewCloseButtonTapped:(ChatAssistantView *)view;

/// 音量按钮被点击(包含点击状态)
- (void)chatAssistantViewVolumeButtonTapped:(ChatAssistantView *)view isSec:(BOOL)isSec;

/// 全屏按钮被点击
- (void)chatAssistantViewFullscreenButtonTapped:(ChatAssistantView *)view;

/// Vip按钮被点击
- (void)chatAssistantViewVipButtonTapped:(ChatAssistantView *)view;

/// 视图即将销毁
- (void)chatAssistantViewWillDestroy:(ChatAssistantView *)view;

/// 视图已销毁
- (void)chatAssistantViewDidDestroy:(ChatAssistantView *)view;

@end

@interface ChatAssistantView : UIView

// MARK: - Singleton

/// 获取单例实例
+ (instancetype)shared;

/// 销毁单例实例
+ (void)destroy;

/// 检查单例是否存在
+ (BOOL)isInstanceCreated;

// MARK: - Properties

/// 代理
@property (nonatomic, weak, nullable) id<ChatAssistantViewDelegate> delegate;

/// 是否正在显示
@property (nonatomic, assign, readonly) BOOL isShowing;

///是否展开状态
@property (nonatomic, assign, readonly) BOOL isExpanded;

// MARK: - Display Methods
/// 显示最小化状态（自定义坐标）
/// @param point 屏幕坐标（中心点）
- (void)showMinimizedAtPoint:(CGPoint)point;

/// 显示最小化状态（GameMacro）
- (void)showMinimizedAtScreen;

/// 显示展开状态（自定义坐标）
/// @param point 屏幕坐标（中心点）
- (void)showExpandedAtPoint:(CGPoint)point;

/// 显示展开状态（GameMacro）
- (void)showExpandedAtScreen;

/// 隐藏视图
- (void)hide;

/// 隐藏视图（带动画选项）
/// @param animated 是否动画
- (void)hideAnimated:(BOOL)animated;

// MARK: - Content Update
///更新tools状态(根据AiVoiceChatState)
-(void)updateToolWithChatState:(AiVoiceChatState)chatState;

///更新convMessage
-(void)updateConvMessage:(ConversationStatusMessage *)convMsg;

///更新subvMessage
-(void)updateSubvMessage:(SubtitleMsgData *)subvMsg;

///更新标题title
-(void)updateChatTitle:(NSString *)titleStr;

///更新vip提示
-(void)updateVipTitle:(NSString * __nullable)vipTitle;

@end

NS_ASSUME_NONNULL_END
