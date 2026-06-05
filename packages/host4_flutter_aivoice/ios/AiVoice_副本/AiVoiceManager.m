//
//  AiVoiceManager.m
//  GameMacro
//
//  Created by 敬攀 on 2025/12/9.
//

#import "AiVoiceManager.h"
#import "AgentRequestManager.h"
#import "RtcUtils.h"
#import "ChatAssistantView.h"
#import "AccessToken.h"
#import "RtcUtilTools.h"
#import "SubtitleMsgData+Validation.h"
#import "WavAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

static AiVoiceManager *voiceManager = nil;

@interface AiVoiceManager()

///isSpeaking是否有人说话
@property (nonatomic, assign) BOOL isSpeaking;

///latestConvModel最新收到的conv智能体状态
@property (nonatomic, strong) ConversationStatusMessage *__nullable latestConvModel;

///isJoinRoom是否已经加入房间(判断重连的时候是拉取智能体还是重新进房)
@property (nonatomic, assign) BOOL isJoinRoom;

@end

@implementation AiVoiceManager

+(AiVoiceManager *)shared{
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        voiceManager = [[AiVoiceManager alloc] init];
    });
    
    return voiceManager;
}

- (ByteRTCEngine *)rtcEngine{
    if (!_rtcEngine){
        //没有引擎，创建
        ByteRTCEngineConfig *engineCfg = [[ByteRTCEngineConfig alloc] init];
        
        engineCfg.appID = AIVoiceAppId;
        engineCfg.parameters = @{};
        
        AIVoiceShared.rtcEngine = [ByteRTCEngine createRTCEngine:engineCfg delegate:AIVoiceShared];
    }
    return _rtcEngine;
}

#pragma mark - 创建引擎
-(void)buildRTCEngine{
    //开启本地音频采集
    // 1. 配置音频参数
    ByteRTCAudioPropertiesConfig *audioConfig = [[ByteRTCAudioPropertiesConfig alloc] init];
    audioConfig.enableVad = YES;
    audioConfig.interval = 200;
    [AIVoiceShared.rtcEngine enableAudioPropertiesReport:audioConfig];
    
    [AIVoiceShared.rtcEngine startAudioCapture];
    [AIVoiceShared.rtcEngine setAudioProfile:ByteRTCAudioProfileDefault];
    [AIVoiceShared.rtcEngine setPlaybackVolume:100];
//    [AIVoiceShared.rtcEngine setDefaultAudioRoute:ByteRTCAudioRouteSpeakerphone];
    
    
    // 2. 禁用视频相关功能
    [AIVoiceShared.rtcEngine stopVideoCapture];
    
    //进入房间
    [AIVoiceShared joinRoom];
    
    self.isUserAsk = NO;
}

#pragma mark - 销毁引擎和房间
-(void)destructionRTCEngine{
    //退出智能体
    [self agentLeave];
    
    //销毁房间
    [self leaveRoom];
    
    //销毁引擎
    [ByteRTCEngine destroyRTCEngine];
    AIVoiceShared.rtcEngine = nil;
    
    AIVoiceShared.userId = nil;
    AIVoiceShared.taskId = nil;
    AIVoiceShared.roomId = nil;
    AIVoiceShared.chatbotId = nil;
    
    AIVoiceShared.isSpeaking = NO;
    AIVoiceShared.isUserAsk = NO;
    AIVoiceShared.isUserVip = NO;
    AIVoiceShared.isJoinRoom = NO;
    
    AIVoiceShared.connectState = LoseConnect;
    AIVoiceShared.latestConvModel = nil;
}

#pragma mark - 加入房间
-(void)joinRoom{
    //创建房间
    NSString *roomId = isStringEmpty(AIVoiceShared.roomId) ? [RtcUtils generateRoomId] : AIVoiceShared.roomId;

    AIVoiceShared.rtcRoom = [AIVoiceShared.rtcEngine createRTCRoom:roomId];
    AIVoiceShared.rtcRoom.delegate = AIVoiceShared;
    
    // 设置用户可见性
    [AIVoiceShared.rtcRoom setUserVisibility:YES];
    
    //用户信息
    ByteRTCUserInfo *userInfo = [[ByteRTCUserInfo alloc] init];
    
    userInfo.userId = isStringEmpty(AIVoiceShared.userId) ? [RtcUtils generateUserId] : AIVoiceShared.userId;
    
    //生成 Token
    NSString *tokenStr = [AccessToken generateToken:roomId userID:userInfo.userId];
    if (isStringEmpty(tokenStr)) {
        NSLog(@"[RTCManager] ❌ Token 生成失败");
        return;
    }
    
    // 房间配置
    ByteRTCRoomConfig *roomCfg = [[ByteRTCRoomConfig alloc] init];
    roomCfg.isPublishAudio = NO; // 初始不发布上行，避免影响播放路由
    roomCfg.isPublishVideo = NO;
    roomCfg.isAutoSubscribeAudio = YES;
    roomCfg.isAutoSubscribeVideo = NO;

    //加入房间
    [AIVoiceShared.rtcRoom joinRoom:tokenStr userInfo:userInfo userVisibility:YES roomConfig:roomCfg];
}

#pragma mark - 重新房间
-(void)reJoinRoom{
    if (self.isJoinRoom){
        //之前进入过房间，重新拉取智能体
        [self startAgent];
    }else{
        //进房失败，没有进入过房间，重新进入房间
        [self joinRoom];
    }
}

#pragma mark - 退出房间
-(void)leaveRoom{
    if (AIVoiceShared.rtcRoom){
        [AIVoiceShared.rtcRoom leaveRoom];
        [AIVoiceShared.rtcRoom destroy];
        self.rtcRoom = nil;
    }
}

#pragma mark - 设置音量
- (void)switchVoiceVolume:(BOOL)openAudioVolume {
    
    if (!AIVoiceShared.rtcEngine) return;
    
    if (openAudioVolume) {
        //开启音量
        NSLog(@"开启音量");
        [AIVoiceShared.rtcEngine setPlaybackVolume:100];
    } else {
        //关闭音量
        NSLog(@"关闭音量");
        [AIVoiceShared.rtcEngine setPlaybackVolume:0];
    }
}

#pragma mark - 设置麦克风
- (void)switchAudioCapture:(BOOL)isOpenAudio {
    if (!AIVoiceShared.rtcEngine || !AIVoiceShared.rtcRoom) {
        NSLog(@"[RTC] ❌ 引擎或房间未初始化，放弃切换麦克风");
        return;
    }
    
    //增加状态拦截，防止重复调用导致链路重启
    if (self.isUserVip == isOpenAudio) {
        NSLog(@"[RTC] ℹ️ 麦克风状态已经是 %d，跳过重复设置", isOpenAudio);
        return;
    }

    self.isUserVip = isOpenAudio;

    if (isOpenAudio) {
        NSLog(@"[RTC] ✅ 开启麦克风");
        [AIVoiceShared.rtcRoom publishStreamAudio:YES];
        [[ChatAssistantView shared] updateToolWithChatState:CHAT_Normal];
    } else {
        NSLog(@"[RTC] ✅ 关闭麦克风");
        [AIVoiceShared.rtcRoom publishStreamAudio:NO];
        [[ChatAssistantView shared] updateToolWithChatState:CHAT_NotVip];
    }
    // 不修改播放音量，避免误将 AI 播放静音
}

#pragma mark - 开启智能体
-(void)startAgent{
    // 验证初始化
    if (!AIVoiceShared.rtcEngine) {
        NSLog(@"[RTCManager] ❌ RTC 引擎未初始化");
        return;
    }
    
    if (!isStringEmpty(AIVoiceShared.roomId) && !isStringEmpty(AIVoiceShared.userId) && !isStringEmpty(AIVoiceShared.taskId)){
        
        //先关闭语音录取，作为非VIP用户，等待获取后台成功之后再更改状态打开
        
        [[ChatAssistantView shared] updateToolWithChatState:CHAT_NotVip];

        kWeakSelf(self)
        
        [AgentRequestManager agentJoinRoomRequest:K_APP_NAME roomID:AIVoiceShared.roomId taskID:AIVoiceShared.taskId userID:AIVoiceShared.userId botname:AIVoiceShared.chatbotId completedBlock:^{
            
            [weakself getVipUseInfo:0];
            
        } failuerBlock:^{

        }];
    }else{
       
    }
}

#pragma mark - 退出智能体
-(void)agentLeave{
    if (!isStringEmpty(AIVoiceShared.roomId) && !isStringEmpty(AIVoiceShared.taskId)){
        
        //退出智能体
        [AgentRequestManager agentLeaveRoomRequest:AIVoiceShared.roomId taskID:AIVoiceShared.taskId completedBlock:^{
            
            AIVoiceShared.roomId = nil;
            AIVoiceShared.taskId = nil;
            AIVoiceShared.userId = nil;
            AIVoiceShared.chatbotId = nil;
        } failuerBlock:^{
            
        }];
    }
}

#pragma mark - 状态更新
///连接状态
-(void)setConnectState:(AiConnectState)connectState{
    _connectState = connectState;
    
    AiVoiceChatState chatState;
    
    switch (_connectState) {
        case Connecting:
            chatState = CHAT_Connecting;
            break;
        case LoseConnect:
            chatState = CHAT_Reconnect;
            break;
        default:
            chatState = CHAT_Normal;
            break;
    }
    
    [[ChatAssistantView shared] updateToolWithChatState:chatState];
}

///说话状态
-(void)setIsSpeaking:(BOOL)isSpeaking{
    
    _isSpeaking = isSpeaking;
    
    if (_isSpeaking){
        //有人说话
        [[ChatAssistantView shared] updateToolWithChatState:CHAT_Speaking];
    }else{
        //没有说话
        //如果当前AI语音正在说话，那么不需要处理
        if (self.latestConvModel.stage.code == 3){
            return;
        }
        
        [[ChatAssistantView shared] updateToolWithChatState:CHAT_Normal];
    }
}

-(void)setChatbotId:(NSString *)chatbotId{
    _chatbotId = chatbotId;
    
    [[ChatAssistantView shared] updateChatTitle:_chatbotId];
}

#pragma mark - 播放本地音频
-(void)palySpeciaAudio{
    NSString *language = [HttpRequrst getLanguage];
    
    NSString *audioName;
    
    if ([language isEqualToString:ZHCN_Language] || [language isEqualToString:ZHTW_Language]){
        audioName = @"illegal_game";
    }else if ([language isEqualToString:JAJP_Language]){
        audioName = @"illegal_game_ja";
    }else{
        audioName = @"illegal_game_en";
    }
    
    NSLog(@"audioName：%@",audioName);
    
    [WavAudioPlayer playAudioFile:audioName completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"✅ 播放成功");
        } else {
            NSLog(@"❌ 播放失败: %@", error.localizedDescription);
        }
    }];
}

#pragma mark - ByteRTCEngineDelegate && ByteRTCRoomDelegate

//进房状态
- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onRoomStateChanged:(NSString *)roomId withUid:(NSString *)uid state:(NSInteger)state extraInfo:(NSString *)extraInfo{
    
//    NSLog(@"房间状态改变:uid:%@ state:%ld extraInfo:%@",uid, (long)state, extraInfo);
    
    if (state == 0){
        
        self.isJoinRoom = YES;
        
        //用户进入房间成功，拉取智能体进入房间
        if (isStringEmpty(AIVoiceShared.taskId)){
            AIVoiceShared.taskId = [RtcUtils generateTaskId];
        }
        
        if (isStringEmpty(AIVoiceShared.roomId) || ![AIVoiceShared.roomId isEqualToString:roomId]){
            AIVoiceShared.roomId = roomId;
        }
        
        if (isStringEmpty(AIVoiceShared.userId) || ![AIVoiceShared.userId isEqualToString:uid]){
            AIVoiceShared.userId = uid;
        }
        
        if (isStringEmpty(AIVoiceShared.chatbotId)){
            AIVoiceShared.chatbotId = [RtcUtils generateChatbotId];
        }
        
        [self startAgent];
        
    }else{
        //用户进房失败，设置为重新连接按钮，点击重新进房
        self.connectState = LoseConnect;
    }
}

//离开房间回调
- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onLeaveRoom:(ByteRTCRoomStats *)stats{
//    NSLog(@"用户离开房间的回调");
    
//    AIVoiceShared.isInRoom = NO;
//    [self destructionRTCEngine];
}

//- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onUserPublishStreamAudio:(NSString *)streamId info:(ByteRTCStreamInfo *)info isPublish:(BOOL)isPublish{
//    NSLog(@"远端用户发布音频流：streamId:%@ info:%@ isPublish:%d",streamId, info, isPublish);
//}

//- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onUserJoined:(ByteRTCUserInfo *)userInfo{
//    NSLog(@"远端用户加入房间：%@", userInfo);
//}

//- (void)rtcRoom:(ByteRTCRoom *)rtcRoom onUserLeave:(NSString *)uid reason:(ByteRTCUserOfflineReason)reason{
//    NSLog(@"远端用户离开房间：uid:%@", uid);
//}

- (void)onTokenWillExpire:(ByteRTCRoom *)rtcRoom{
//    NSLog(@"token即将过期,请重新获取token");
    NSString *tokenStr = [AccessToken generateToken:rtcRoom.getRoomId userID:AIVoiceShared.userId];
    
    if (!isStringEmpty(tokenStr)){
        [rtcRoom updateToken:tokenStr];
    }
}

-(void)rtcEngine:(ByteRTCEngine *)engine onNetworkTypeChanged:(ByteRTCNetworkType)type{
    
    if (type == ByteRTCNetworkTypeDisconnected){
        //断网
        self.connectState = LoseConnect;
    }
}

-(void)rtcEngine:(ByteRTCEngine *)engine onConnectionStateChanged:(ByteRTCConnectionState)state{
    
//    NSLog(@"SDK与服务器连接状态改变回调。连接状态改变时：%ld",(long)state);
    
    switch (state) {
        case ByteRTCConnectionStateConnecting:
            self.connectState = Connecting;
            break;
        case ByteRTCConnectionStateReconnecting:
            self.connectState = Connecting;
            break;
        case ByteRTCConnectionStateConnected:
            self.connectState = Connected;
            break;
        case ByteRTCConnectionStateReconnected:
            self.connectState = Connected;
            break;
        default:
            self.connectState = LoseConnect;
            break;
    }
}

-(void)rtcEngine:(ByteRTCEngine *)engine onLocalAudioPropertiesReport:(NSArray<ByteRTCLocalAudioPropertiesInfo *> *)audioPropertiesInfos{

    //此处判断是否有人说话，改变UI下面的说话按钮状态
    if (audioPropertiesInfos.count > 0){
        
        for (ByteRTCLocalAudioPropertiesInfo * info in audioPropertiesInfos){
            
            //有人说话且音量大于30
            if (info.audioPropertiesInfo.vad == 1 && info.audioPropertiesInfo.linearVolume > 10){
                AIVoiceShared.isSpeaking = YES;
            }else{
                AIVoiceShared.isSpeaking = NO;
            }
        }
        
//        ByteRTCLocalAudioPropertiesInfo *info = audioPropertiesInfos.firstObject;
    }else{
        AIVoiceShared.isSpeaking = NO;
    }
}

-(void)rtcRoom:(ByteRTCRoom *)rtcRoom onRoomBinaryMessageReceived:(NSString *)uid message:(NSData *)message{
    
    //Subv
    NSString *subtitles = [SubtitleMsgData unPackData:message];
    
    if (subtitles) {
        NSMutableArray *subvArr = [SubtitleMsgData parseMsg:subtitles];
        
        for (SubtitleMsgData *subvModel in subvArr){
            NSLog(@"subv:收到的消息%@",subtitles);
            
            //检测VIP扣费
            [self checkVipDeduction:[subvModel copy]];
            
            [[ChatAssistantView shared] updateSubvMessage:subvModel];
        }
    } else {
        NSString *strMessage = [ConversationStatusMessage unPackData:message];
        
        if (strMessage) {
            NSLog(@"conv:收到的消息%@",strMessage);
            
            ConversationStatusMessage *convModel = [ConversationStatusMessage parseMsg:strMessage];
            
            if (convModel){
                AIVoiceShared.latestConvModel = convModel;
                
                [[ChatAssistantView shared] updateConvMessage:convModel];
                
                if (convModel.stage.code == 3){
                    //智能体回复的时候显示打断
                    [[ChatAssistantView shared] updateToolWithChatState:CHAT_Interrupt];
                }
                
                if (convModel.stage.code == 4 || convModel.stage.code == 5){
                    //智能体被打断或者说话完成
                    [[ChatAssistantView shared] updateToolWithChatState:CHAT_Normal];
                }
            }
            
            
        }
    }
}

#pragma mark - Vip
//收到消息判断是否扣费
-(void)checkVipDeduction:(SubtitleMsgData *)subvModel{
    if ([subvModel.userId isEqualToString:self.userId] && subvModel.definite){
        //yes，如果用户开始说话，那么设置为开始检测是否需要扣费
        self.isUserAsk = YES;
    }
    
    if ([subvModel isBotCompleteSentenceNeedsSpecialHandling:self.chatbotId] && self.isUserAsk){
        
        //上报
        [[FireBaseHelper shared] logChatCount];
        
        if (![DYUserManager shareManager].model.vipModel.isSuperVip){
            
            //需要扣费
            NSLog(@"需要扣费 %@",subvModel.text);
            
            //如果不是超级会员，扣除次数
            [self getVipUseInfo:1];
        }
    }
}

//获取会员使用情况type：0 不扣费 1 扣费
-(void)getVipUseInfo:(int)type{
    //机器人返回的text不为~或者nil,那么需要扣费
    kWeakSelf(self)
    
    [AgentRequestManager requestVipUserUse:type completedBlock:^(id _Nonnull vipModel) {
        
        [weakself vipInfoCheckAndChangeUI:vipModel];

    } failuerBlock:^(id _Nonnull error) {

    }];
}

//检测vip信息并修改UI
//-(void)vipInfoCheckAndChangeUI:(UserVipModel *)vipModel{
//    if (!vipModel) return;
//
//    //是否终身会员
//    BOOL isSupper = vipModel.isSuperVip;
//
//    //会员剩余天数
//    int vipDataCount = vipModel.useEndTimeDay;
//
//    if (isSupper || vipDataCount > 3){
//        [self switchAudioCapture:YES];
//
//        //更新vip提示
//        [[ChatAssistantView shared] updateVipTitle:nil];
//
//        return;
//    }
//
//    if (vipDataCount > 0){
//        [self switchAudioCapture:YES];
//
//        //更新vip提示
//        [[ChatAssistantView shared] updateVipTitle:[NSString stringWithFormat:@"%@%d%@",kLocalizedString(@"VipLastDay", nil),vipDataCount,kLocalizedString(@"Day", nil)]];
//
//        return;
//    }
//
//    //次数验证
//    int userCount = vipModel.useCount;
//
//    [self switchAudioCapture:userCount > 0];
//
//    //更新vip提示
//    [[ChatAssistantView shared] updateVipTitle:kLocalizedString(@"UnlockUnlimitedChat", nil)];
//}

- (void)vipInfoCheckAndChangeUI:(UserVipModel *)vipModel {
    if (!vipModel) return;

    //超级会员
    BOOL isSupper = vipModel.isSuperVip;
    //剩余天数
    int vipDataCount = vipModel.useEndTimeDay;
    //剩余次数
    int userCount = vipModel.useCount;

    // 确定当前用户是否有权进行语音对话
    BOOL hasPermission = (isSupper || vipDataCount > 0 || userCount > 0);

    // 只有权限发生变化时，才去触碰 switchAudioCapture
    [self switchAudioCapture:hasPermission];

    // --- 以下仅负责 UI 更新，不干涉 RTC 逻辑 ---
    if (isSupper || vipDataCount > 3) {
        [[ChatAssistantView shared] updateVipTitle:nil];
    } else if (vipDataCount > 0) {
        [[ChatAssistantView shared] updateVipTitle:[NSString stringWithFormat:@"%@%d%@", kLocalizedString(@"VipLastDay", nil), vipDataCount, kLocalizedString(@"Day", nil)]];
    } else if (userCount <= 0) {
        [[ChatAssistantView shared] updateVipTitle:kLocalizedString(@"UnlockUnlimitedChat", nil)];
    }
}

@end
