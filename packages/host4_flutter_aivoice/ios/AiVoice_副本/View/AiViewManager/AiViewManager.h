//
//  AiViewManager.h
//  GameMacro
//
//  Created by 敬攀 on 2025/12/16.
//

#import <Foundation/Foundation.h>
#import "AiVoiceManager.h"

NS_ASSUME_NONNULL_BEGIN

/// AI语音控件显示状态
typedef NS_ENUM(NSInteger, AiFloatingViewState) {
    ///悬浮窗状态
    FloatingState,
    ///聊天窗缩小状态
    ChatMinimized,
    ///聊天窗放大状态
    ChatExpanded,
};

@interface AiViewManager : NSObject

//单例
+ (AiViewManager *)shared;

///当前悬浮状态
@property (nonatomic, assign) AiFloatingViewState floatState;

///显示悬浮球
-(void)showFloatWindow:(BOOL)isshow;

@end

NS_ASSUME_NONNULL_END
