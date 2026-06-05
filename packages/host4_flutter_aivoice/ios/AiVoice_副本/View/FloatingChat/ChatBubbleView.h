//
//  ChatBubbleView.h
//  支持动态状态的聊天气泡视图
//

#import <UIKit/UIKit.h>
#import "AiVoiceManager.h"


NS_ASSUME_NONNULL_BEGIN

#pragma mark - Message Type

/// 消息类型
typedef NS_ENUM(NSInteger, ChatMessageType) {
    ChatMessageTypeUser = 0,    // 用户消息（右侧，紫色）
    ChatMessageTypeAI   = 1,      // AI消息（左侧，灰色）
};

#pragma mark - Message Model 消息体模型

@interface ChatMessage : NSObject

@property (nonatomic, assign) ChatMessageType type;
@property (nonatomic, assign) NSInteger roundId;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong, nullable) UIView *overlayView;        // 气泡上的overlay视图
@property (nonatomic, copy, nullable) NSString *hintText;           // 气泡下方的提示文本
@property (nonatomic, assign) BOOL showHintIcon; // 是否显示提示图标
@property (nonatomic, strong, nullable) UIImage *avatarImage;       // 头像图片

+ (instancetype)messageWithType:(ChatMessageType)type text:(NSString *)text;

+ (instancetype)messageWithInfo:(ChatMessageType)type text:(NSString *)text roundId:(NSInteger)roundId;

@end

#pragma mark - Delegate && 消息被点击
 
@class ChatBubbleView;

@protocol ChatBubbleViewDelegate <NSObject>

@optional
/// 消息被点击
- (void)chatBubbleView:(ChatBubbleView *)bubbleView didTapMessageAtIndex:(NSInteger)index;

@end

#pragma mark - Main View

@interface ChatBubbleView : UIView

// MARK: - Properties

/// 代理
@property (nonatomic, weak, nullable) id<ChatBubbleViewDelegate> delegate;

/// 消息列表
@property (nonatomic, strong, readonly) NSMutableArray<ChatMessage *> *messages;

/// 消息列表最后一条消息的index
@property (nonatomic, assign, readonly) NSInteger lastMsgIndex;

// MARK: - Appearance

/// 用户消息气泡背景色（默认紫色）
@property (nonatomic, strong) UIColor *userBubbleColor;

/// AI消息气泡背景色（默认深灰色）
@property (nonatomic, strong) UIColor *aiBubbleColor;

/// 消息文本颜色（默认白色）
@property (nonatomic, strong) UIColor *messageTextColor;

/// 消息字体（默认15号）
@property (nonatomic, strong) UIFont *messageFont;

/// 提示文本颜色（默认灰色）
@property (nonatomic, strong) UIColor *hintTextColor;

/// 提示字体（默认12号）
@property (nonatomic, strong) UIFont *hintFont;

/// 用户头像（默认nil，使用系统图标）
@property (nonatomic, strong, nullable) UIImage *userAvatarImage;

/// AI头像（默认nil，使用系统图标）
@property (nonatomic, strong, nullable) UIImage *aiAvatarImage;

// MARK: - Initialization

- (instancetype)initWithFrame:(CGRect)frame;

// MARK: - Message Management
///更新convMessage
-(void)updateConvMessage:(ConversationStatusMessage *)convMsg;

///更新subvMessage
-(void)updateSubvMessage:(SubtitleMsgData *)subvMsg;

/// 添加消息
- (void)addMessage:(ChatMessage *)message;
- (void)addMessage:(ChatMessage *)message animated:(BOOL)animated;

/// 添加普通消息
- (void)addUserMessage:(NSString *)text;
- (void)addAIMessage:(NSString *)text;

/// 更新指定索引的消息文本
- (void)updateMessageAtIndex:(NSInteger)index withText:(NSString *)text;

/// 更新指定索引的消息，添加overlay和提示
- (void)updateMessageAtIndex:(NSInteger)index 
                 withOverlay:(UIView *_Nullable)overlayView 
                    hintText:(NSString *_Nullable)hintText 
                    showIcon:(BOOL)showIcon;

/// 清除指定索引消息的overlay和提示
- (void)clearOverlayAndHintAtIndex:(NSInteger)index;

/// 删除指定索引的消息
- (void)removeMessageAtIndex:(NSInteger)index;

/// 清空所有消息
- (void)clearAllMessages;

// MARK: - Convenience Methods（便捷方法）

/// 设置消息为"分析中"状态（显示三点动画 + "指令分析中"）
- (void)setMessageAnalyzingAtIndex:(NSInteger)index;

/// 设置消息为"说话中"状态（显示三点动画 + 自定义提示文本）
- (void)setMessageSpeakingAtIndex:(NSInteger)index withHint:(NSString *)hintText;

/// 设置消息为"网络错误"状态（显示图标 + "网络错误，请检查网络连接"）
- (void)setMessageNetworkErrorAtIndex:(NSInteger)index;

/// 设置消息为"网络错误"状态（自定义提示）
- (void)setMessageNetworkErrorAtIndex:(NSInteger)index withHint:(NSString *)hintText;

/// 完成分析/说话，更新为最终文本（清除overlay和提示）
- (void)finishMessageAtIndex:(NSInteger)index withFinalText:(NSString *)text;

// MARK: - Helper Methods

/// 创建三点动画视图
- (UIView *)createThreeDotsAnimationView;

// MARK: - Scroll

/// 滚动到底部
- (void)scrollToBottom;
- (void)scrollToBottomAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
