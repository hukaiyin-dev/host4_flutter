//
//  AiVoiceManager.h
//  GameMacro
//
//  Created by 敬攀 on 2025/12/9.
//

#define AIVoiceShared [AiVoiceManager shared]

#define AIVoiceAppId @"68230496df1dcd01804db0a9"

#define AIVoiceAppKey @"5054eb5367ec4703bc6763ca78736038"

#import <Foundation/Foundation.h>
#import <VolcEngineRTC/objc/ByteRTCEngine.h>
#import <VolcEngineRTC/objc/ByteRTCRoom.h>
#import "ConversationStatusMessage.h"

NS_ASSUME_NONNULL_BEGIN

/// AI语音信息的当前状态
typedef NS_ENUM(NSInteger, AiVoiceMessageState) {
    ///失败
    Message_ERROR      =  0,
    ///听
    Message_LISTENING   =  1,
    ///思考
    Message_THINKING    =  2,
    ///说话
    Message_SPEAKING    =  3,
    ///中断
    Message_INTERRUPT   =  4,
    ///完成
    Message_COMPLETE    =  5,
};

/// AI语音当前聊天状态
typedef NS_ENUM(NSInteger, AiVoiceChatState) {
    ///连接中
    CHAT_Connecting     =  0,
    ///连接成功未说话，且信息没有播放
    CHAT_Normal         =  1,
    ///连接成功用户说话中
    CHAT_Speaking       =  2,
    ///连接成功信息播放中，可打断
    CHAT_Interrupt      =  3,
    ///点击重新连接
    CHAT_Reconnect      =  4,
    ///不是vip
    CHAT_NotVip      =   5,
};

/// AI语音当前聊天状态
typedef NS_ENUM(NSInteger, AiConnectState) {
    ///连接中(包含CHAT_Connecting)
    Connecting     =  0,
    ///连接成功(包含CHAT_Normal，CHAT_Speaking，CHAT_Interrupt)
    Connected         =  1,
    ///失去连接(包含CHAT_Reconnect)
    LoseConnect       =  2,
};

@interface AiVoiceManager : NSObject <ByteRTCEngineDelegate, ByteRTCRoomDelegate>

+ (AiVoiceManager *)shared;

#pragma mark - 属性
///引擎
@property (nonatomic, strong) ByteRTCEngine *__nullable rtcEngine;

///聊天室实例
@property (nonatomic, strong) ByteRTCRoom *__nullable rtcRoom;

///连接状态
@property (nonatomic, assign) AiConnectState connectState;

///isUserVip是否vip
@property (nonatomic, assign) BOOL isUserVip;

///isUserAsk用户是否已经说话（判断是否调用扣减次数）
@property (nonatomic, assign) BOOL isUserAsk;

///房间ID
@property (nonatomic, copy) NSString *__nullable roomId;

///任务ID
@property (nonatomic, copy) NSString *__nullable taskId;

///用户ID
@property (nonatomic, copy) NSString *__nullable userId;

///智能体ID
@property (nonatomic, copy, nullable) NSString *chatbotId;

#pragma mark - 实例方法
///创建引擎
-(void)buildRTCEngine;

///销毁引擎
-(void)destructionRTCEngine;

///加入房间
-(void)joinRoom;

/**
 * 重新加入房间（网络重连）
 */
- (void)reJoinRoom;

///离开房间
-(void)leaveRoom;

/**
 * 切换音量开关
 *
 * @param openAudioVolume YES 打开音量，NO 关闭音量
 */
- (void)switchVoiceVolume:(BOOL)openAudioVolume;

/**
 * 切换麦克风开关
 *
 * @param isOpenAudio YES 打开麦克风，NO 关闭麦克风
 */
- (void)switchAudioCapture:(BOOL)isOpenAudio;

/**
 * 设置音频能力（启用/禁用语音功能）
 *
 * @param isEnable YES 启用，NO 禁用
 */
- (void)setAudioAbility:(BOOL)isEnable;


/**
 * AI播放特殊字符回复音频
 */
- (void)palySpeciaAudio;

@end

NS_ASSUME_NONNULL_END
