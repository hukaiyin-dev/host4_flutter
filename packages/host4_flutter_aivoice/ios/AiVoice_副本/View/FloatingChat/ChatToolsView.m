//
//  ChatToolsView.m
//

#import "ChatToolsView.h"
#import "FrameAnimationView.h"
#import "FrameAnimationView+Animations.h"
#import "AgentRequestManager.h"

@interface ChatToolsView()

//说话按钮
@property (nonatomic, strong) FrameAnimationView *speakView;

//打断按钮
@property (nonatomic, strong) UIButton *interruptedBtn;

//重连按钮
@property (nonatomic, strong) UIButton *reconnectBtn;

//语音停止识别按钮
@property (nonatomic, strong) UIButton *chatStopBtn;

@end

@implementation ChatToolsView


-(void)awakeFromNib{
    [super awakeFromNib];
    
    [[NSBundle mainBundle] loadNibNamed:@"ChatToolsView" owner:self options:nil];
    
    self.contentView.frame = self.bounds;
    
    [self addSubview:self.contentView];
    
    [self loadUI];
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self awakeFromNib];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self awakeFromNib];
    }
    return self;
}


-(void)loadUI{
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = LS_Margin_8;
    self.contentView.backgroundColor = RGB(27, 27, 27);
    
    [self.contentView addSubview:self.speakView];
    [self.speakView mas_makeConstraints:^(MASConstraintMaker *make) {
        CenterX_Mas(self.contentView, 0);
        CenterY_Mas(self.contentView, 0);
        Width_Mas(18 * COEFi0);
        Height_Mas(18 * COEFi0);
    }];
    
    [self.contentView addSubview:self.interruptedBtn];
    [self.interruptedBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        Top_Mas(self.contentView, 0);
        Left_Mas(self.contentView, 0);
        Right_Mas(self.contentView, 0);
        Bottom_Mas(self.contentView, 0);
    }];
    
    [self.contentView addSubview:self.reconnectBtn];
    [self.reconnectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        Top_Mas(self.contentView, 0);
        Left_Mas(self.contentView, 0);
        Right_Mas(self.contentView, 0);
        Bottom_Mas(self.contentView, 0);
    }];
    
    [self.contentView addSubview:self.chatStopBtn];
    [self.chatStopBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        Top_Mas(self.contentView, 0);
        Left_Mas(self.contentView, 0);
        Right_Mas(self.contentView, 0);
        Bottom_Mas(self.contentView, 0);
    }];
    
    self.speakView.hidden = YES;
    self.interruptedBtn.hidden = YES;
    self.reconnectBtn.hidden = YES;
    self.chatStopBtn.hidden = YES;
}

-(void)setChatState:(AiVoiceChatState)chatState{
    
    if (chatState == _chatState){
        //同样的状态，无需修改
        return;
    }
    
//    NSLog(@"聊天状态修改:chatState:%ld",(long)chatState);

    _chatState = chatState;
    
    //如果收到没有人说话的状态，应该先判断是否ai正在回复
    
    if (_chatState == CHAT_Connecting){
        //正在连接中
//        NSLog(@"设置连接中状态");
        self.speakView.hidden = NO;
        
        self.interruptedBtn.hidden = YES;
        self.reconnectBtn.hidden = YES;
        self.chatStopBtn.hidden = YES;

        [self.speakView setImageSequenceWithPrefix:@"LoadingDetail" startIndex:1 count:6 numberFormat:@"%05d" extension:@"png"];
        [self.speakView mas_remakeConstraints:^(MASConstraintMaker *make) {
            CenterX_Mas(self.contentView, 0);
            CenterY_Mas(self.contentView, 0);
            Width_Mas(18 * COEFi0);
            Height_Mas(18 * COEFi0);
        }];
        
        [self.speakView play];
        
    }else if (_chatState == CHAT_Normal){
//        NSLog(@"设置未说话状态");
        //未说话
        
        self.speakView.hidden = NO;
        
        self.interruptedBtn.hidden = YES;
        self.reconnectBtn.hidden = YES;
        self.chatStopBtn.hidden = YES;

        [self.speakView setImageSequenceWithPrefix:@"未说话_" startIndex:0 count:6 numberFormat:@"%05d" extension:@"png"];
        
        [self.speakView mas_remakeConstraints:^(MASConstraintMaker *make) {
            CenterX_Mas(self.contentView, 0);
            CenterY_Mas(self.contentView, 0);
            Width_Mas(180 * COEFi0);
            Height_Mas(100 * COEFi0);
        }];
        
        [self.speakView play];
            
    }else if (_chatState == CHAT_Speaking){
            
//        NSLog(@"设置说话中状态");
        //说话中
        self.speakView.hidden = NO;
        
        self.interruptedBtn.hidden = YES;
        self.reconnectBtn.hidden = YES;
        self.chatStopBtn.hidden = YES;

        [self.speakView setImageSequenceWithPrefix:@"说话_" startIndex:0 count:29 numberFormat:@"%05d" extension:@"png"];
        
        [self.speakView mas_makeConstraints:^(MASConstraintMaker *make) {
            CenterX_Mas(self.contentView, 0);
            CenterY_Mas(self.contentView, 0);
            Width_Mas(180 * COEFi0);
            Height_Mas(100 * COEFi0);
        }];
        
        [self.speakView play];
            
    }else if (_chatState == CHAT_Interrupt){
            
//        NSLog(@"设置打断状态");
        //打断
        self.interruptedBtn.hidden = NO;
        
        self.reconnectBtn.hidden = YES;
        self.chatStopBtn.hidden = YES;
        self.speakView.hidden = YES;
        
        [self.speakView stop];
            
    }else if (_chatState == CHAT_Reconnect){
//        NSLog(@"设置重连状态");
        //重连
        self.reconnectBtn.hidden = NO;
        
        self.interruptedBtn.hidden = YES;
        self.chatStopBtn.hidden = YES;
        self.speakView.hidden = YES;
        
        [self.speakView stop];
    }else if (_chatState == CHAT_NotVip){
        //不是VIP
        self.chatStopBtn.hidden = NO;
        
        self.interruptedBtn.hidden = YES;
        self.reconnectBtn.hidden = YES;
        self.speakView.hidden = YES;
        
        [self.speakView stop];
    }
}

- (void)playAnimal{
    if (!self.speakView.isHidden){
        [self.speakView play];
    }
}

-(void)stopAnimal{
    [self.speakView stop];
}

#pragma mark - 懒加载
-(FrameAnimationView *)speakView{
    if (!_speakView){
        _speakView = [[FrameAnimationView alloc] initWithImagePrefix:@"LoadingDetail" startIndex:1 count:9 numberFormat:@"%05d" extension:@"png"];
        
        _speakView.frameRate = 10;
        
        _speakView.animationMode = FrameAnimationModeLoop;
    }
    
    return _speakView;
}

-(UIButton *)interruptedBtn{
    if (!_interruptedBtn){
        _interruptedBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_interruptedBtn setBackgroundColor:[UIColor clearColor]];
        [_interruptedBtn setImage:PNGIMAGE(@"icon-record-on") forState:(UIControlStateNormal)];
        [_interruptedBtn setTitle:kLocalizedString(@"Interrupted", nil) forState:(UIControlStateNormal)];
        [_interruptedBtn setImagePosition:(LXMImagePositionLeft) spacing:LS_Margin_4];
        _interruptedBtn.titleLabel.font = FONTNAME(@"PingFangSC-Semibold", 14);
        [_interruptedBtn setTitleColor:RGBA(255, 255, 255, .95) forState:(UIControlStateNormal)];
        [_interruptedBtn addTarget:self action:@selector(interruptBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _interruptedBtn;
}

-(UIButton *)reconnectBtn{
    if (!_reconnectBtn){
        _reconnectBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_reconnectBtn setBackgroundColor:[UIColor clearColor]];
        [_reconnectBtn setTitle:kLocalizedString(@"", nil) forState:(UIControlStateNormal)];
        _reconnectBtn.titleLabel.font = FONTNAME(@"PingFangSC-Semibold", 14);
        [_reconnectBtn setTitleColor:RGBA(255, 255, 255, .95) forState:(UIControlStateNormal)];
        [_reconnectBtn addTarget:self action:@selector(reconnectBtnAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _reconnectBtn;
}

-(UIButton *)chatStopBtn{
    if (!_chatStopBtn){
        _chatStopBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_chatStopBtn setBackgroundColor:[UIColor clearColor]];
        [_chatStopBtn setTitle:kLocalizedString(@"StopAiChat", nil) forState:(UIControlStateNormal)];
        _chatStopBtn.titleLabel.font = FONTNAME(@"PingFangSC-Semibold", 14);
        [_chatStopBtn setTitleColor:RGBA(255, 255, 255, .95) forState:(UIControlStateNormal)];
        [_chatStopBtn setImage:PNGIMAGE(@"AIClose") forState:(UIControlStateNormal)];
        [_chatStopBtn setImagePosition:LXMImagePositionLeft spacing:LS_Margin_4];
    }
    return _chatStopBtn;
}

#pragma mark - 按钮事件
///打断智能体
-(void)interruptBtnAction:(UIButton *)sender{
    NSLog(@"打断智能体");
    
    [AgentRequestManager agentUpdateRoomRequest:AIVoiceShared.roomId taskID:AIVoiceShared.taskId command:@"interrupt" completedBlock:^{
        
    } failuerBlock:^{
        
    }];
}

//重新连接
-(void)reconnectBtnAction:(UIButton *)sender{
    NSLog(@"重新连接");
    
    [AIVoiceShared reJoinRoom];
}

@end
