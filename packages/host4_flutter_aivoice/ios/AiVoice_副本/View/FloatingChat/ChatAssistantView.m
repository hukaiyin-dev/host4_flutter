//
//  ChatAssistantView.m
//  内置完整UI的AI对话助手视图
//

#import "ChatAssistantView.h"
#import "FrameAnimationView.h"
#import "FrameAnimationView+Animations.h"
#import "ChatBubbleView.h"
#import "ChatToolsView.h"
#import "SubtitleTextAssembler.h"
#import "SubtitleMsgData+Validation.h"

@interface ChatAssistantView ()<ChatBubbleViewDelegate>

@property (nonatomic, strong) UIView *containerView;

///是否显示
@property (nonatomic, assign) BOOL isShowing;

///是否展开状态
@property (nonatomic, assign) BOOL isExpanded;

///是否在思考
@property (nonatomic, assign) BOOL isThinking;

///最后一条消息
@property (nonatomic, copy) NSString *lastMsg;

//UI元素

//背景图
@property (nonatomic, strong) UIImageView *backImgV;

//关闭按钮
@property (nonatomic, strong) UIButton *closeButton;

//展开按钮
@property (nonatomic, strong) UIButton *fullscreenButton;

//音量按钮
@property (nonatomic, strong) UIButton *volumeButton;

//展开状态的标题或者缩小状态的文本
@property (nonatomic, strong) UILabel *aiChatLab;

//缩小状态的等待动画
@property (nonatomic, strong) FrameAnimationView *waitView;

//缩小状态的等待状态提示
@property (nonatomic, strong) UILabel *statusLabel;

//聊天界面
@property (nonatomic, strong) ChatBubbleView *chatView;

//下方工具
@property (nonatomic, strong) ChatToolsView *toolsView;

//下方AI文本提示
@property (nonatomic, strong) UILabel *vipLab;

//下方AI按钮
@property (nonatomic, strong) UIButton *vipBtn;

//聊天的最后一条消息Index
@property (nonatomic, assign, readonly) NSInteger chatLastIndex;

@end

@implementation ChatAssistantView

// 静态变量存储单例实例
static ChatAssistantView *_sharedInstance = nil;
static dispatch_once_t _onceToken;

#pragma mark - Singleton

+ (instancetype)shared {
    if (_sharedInstance == nil) {
        _onceToken = 0;
        dispatch_once(&_onceToken, ^{
            _sharedInstance = [[self alloc] initPrivate];
        });
    }
    return _sharedInstance;
}

+ (void)destroy {
    if (_sharedInstance) {
        if ([_sharedInstance.delegate respondsToSelector:@selector(chatAssistantViewWillDestroy:)]) {
            [_sharedInstance.delegate chatAssistantViewWillDestroy:_sharedInstance];
        }
        
        [_sharedInstance hideAnimated:YES];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_sharedInstance removeFromSuperview];
            
            if ([_sharedInstance.delegate respondsToSelector:@selector(chatAssistantViewDidDestroy:)]) {
                [_sharedInstance.delegate chatAssistantViewDidDestroy:_sharedInstance];
            }
            
            _sharedInstance = nil;
            
            _onceToken = 0;
        });
    }
}

+ (BOOL)isInstanceCreated {
    return _sharedInstance != nil;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (_sharedInstance == nil) {
        _sharedInstance = [super allocWithZone:zone];
    }
    return _sharedInstance;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"Singleton" reason:@"Use +[ChatAssistantView shared] instead" userInfo:nil];
    return nil;
}

- (instancetype)initPrivate {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self commonInit];
    }
    return self;
}

-(void)setIsExpanded:(BOOL)isExpanded{
    _isExpanded = isExpanded;
    
    if (_isExpanded){
        [AiViewManager shared].floatState = ChatExpanded;
    }else{
        [AiViewManager shared].floatState = ChatMinimized;
    }
}

-(void)setFrame:(CGRect)frame{
    [super setFrame: frame];
    
    NSLog(@"当前坐标：%@", NSStringFromCGRect(frame));
}

#pragma mark - Initialization

- (void)commonInit {
//    _isShowing = NO;
//    _isExpanded = NO;
//    
//    [AiViewManager shared].floatState = ChatMinimized;
    
    self.backgroundColor = [UIColor clearColor];
    
    self.hidden = YES;

    //创建容器视图
    [self setupContainerView];
    
    // Add observer for orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOrientationChange) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}



- (void)handleOrientationChange {
    if (self.isShowing) {
        // Delay to allow rotation to finish
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateFrameForCurrentOrientation];
        });
    }
}

- (void)updateFrameForCurrentOrientation {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    BOOL isPortrait = screenSize.height > screenSize.width;
    CGFloat minDim = MIN(screenSize.width, screenSize.height);
    CGFloat maxDim = MAX(screenSize.width, screenSize.height);
    
    CGFloat width = 256 * COEFi0;
    CGFloat height = self.isExpanded ? 375 * COEFi0 : 64 * COEFi0;
    
    CGPoint point;
    
    if (self.isExpanded) {
        if (isPortrait) {
            // (SCREEN_MIN - 256 * COEFi0) / 2, SCREEN_MAX - SCREEN_MIN
            point = CGPointMake((minDim - width) / 2, maxDim - minDim);
        } else {
            // SCREEN_MAX - 256 * COEFi0, 0
            point = CGPointMake(maxDim - width, 0);
        }
    } else {
        if (isPortrait) {
            // (SCREEN_MIN - 256 * COEFi0) / 2, SCREEN_MAX - 96 * COEFi0
            point = CGPointMake((minDim - width) / 2, maxDim - 96 * COEFi0);
        } else {
            // SCREEN_MAX - 256 * COEFi0, 64 * COEFi0
            point = CGPointMake(maxDim - width, 64 * COEFi0);
        }
    }
    
    self.frame = CGRectMake(point.x, point.y, width, height);
    self.containerView.frame = CGRectMake(0, 0, width, height);
    [self.containerView layoutIfNeeded]; // Ensure subviews update
}

#pragma mark - 懒加载
- (NSInteger)chatLastIndex{
    return self.chatView.messages.count - 1;
}

-(UIButton *)closeButton{
    if (!_closeButton){
        // 关闭按钮
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeButton setImage:PNGIMAGE(@"chatClose") forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(closeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

-(UIButton *)fullscreenButton{
    if (!_fullscreenButton){
        self.fullscreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.fullscreenButton setImage:PNGIMAGE(@"chatZoom") forState:UIControlStateNormal];
        [self.fullscreenButton addTarget:self action:@selector(fullscreenButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullscreenButton;
}

-(UIButton *)volumeButton{
    if (!_volumeButton){
        self.volumeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.volumeButton setImage:PNGIMAGE(@"chatVolume") forState:UIControlStateNormal];
        [self.volumeButton setImage:PNGIMAGE(@"chatSilent") forState:UIControlStateSelected];
        [self.volumeButton addTarget:self action:@selector(volumeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _volumeButton;
}

-(UIImageView *)backImgV{
    if (!_backImgV){
        _backImgV = [[UIImageView alloc] init];
    }
    return _backImgV;
}

-(UILabel *)aiChatLab{
    if (!_aiChatLab){
        _aiChatLab = [[UILabel alloc] init];
        _aiChatLab.font = FONTNAME(@"PingFangSC-Semibold", 14 * COEFi0);
        _aiChatLab.textColor = LS_Basic_WhiteColor;
        _aiChatLab.textAlignment = NSTextAlignmentCenter;
    }
    return _aiChatLab;
}

-(FrameAnimationView *)waitView{
    if (!_waitView){
        _waitView = [[FrameAnimationView alloc] initWithImagePrefix:@"icon_load_" startIndex:1 count:3 numberFormat:@"%04d" extension:@"png"];
        
        _waitView.frameRate = 3;
        
        _waitView.animationMode = FrameAnimationModePingPong;
    }
    
    return _waitView;
}

-(UILabel *)statusLabel{
    if (!_statusLabel){
        _statusLabel = [[UILabel alloc] init];
        _statusLabel.font = FONTNAME(@"PingFangSC-Regular", 12);
        _statusLabel.textColor = LS_Basic_WhiteColor;
        _statusLabel.textAlignment = NSTextAlignmentCenter;
        _statusLabel.text = kLocalizedString(@"InstructionAnalysis", nil);
    }
    return _statusLabel;
}

-(ChatToolsView *)toolsView{
    if (!_toolsView){
        _toolsView = [[ChatToolsView alloc] init];
    }
    return _toolsView;
}

-(UILabel *)vipLab{
    if (!_vipLab){
        _vipLab = [[UILabel alloc] init];
        _vipLab.font = FONTNAME(@"PingFangSC-Regular", 10);
        _vipLab.textColor = LS_TextColor_55;
        _vipLab.textAlignment = NSTextAlignmentCenter;
        _vipLab.numberOfLines = 0;
    }
    return _vipLab;
}

-(UIButton *)vipBtn{
    if (!_vipBtn){
        _vipBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.vipBtn setImage:PNGIMAGE(@"AIPayWeb") forState:UIControlStateNormal];
        [self.vipBtn addTarget:self action:@selector(vipButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _vipBtn;
}

-(ChatBubbleView *)chatView{
    if (!_chatView){
        _chatView = [[ChatBubbleView alloc] init];
        
        _chatView.delegate = self;
        
        _chatView.backgroundColor = [UIColor clearColor];
        
        _chatView.userBubbleColor = LS_BasicColor;
        _chatView.aiBubbleColor = RGBA(255, 255, 255, .08);
        _chatView.messageTextColor = LS_Basic_WhiteColor;
        _chatView.messageFont = FONTNAME(@"PingFangSC-Semibold", 14);
        
        _chatView.hintFont = FONTNAME(@"PingFangSC-Regular", 12);
        _chatView.hintTextColor = LS_TextColor_55;
        
    }
    return _chatView;
}

#pragma mark - UI Setup
- (void)setupContainerView {
    self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
    
    self.containerView.backgroundColor = [UIColor clearColor];
    
    self.containerView.layer.cornerRadius = LS_Margin_8;
    self.containerView.clipsToBounds = NO;
    self.containerView.userInteractionEnabled = YES;
    [self addSubview:self.containerView];
    
    //设置阴影
    self.containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.containerView.layer.shadowOffset = CGSizeMake(0, -2 * COEFi0);
    self.containerView.layer.shadowOpacity = 0.4;
    self.containerView.layer.shadowRadius = 8 * COEFi0;
    self.containerView.layer.masksToBounds = NO;
    
    [self.containerView addSubview:self.backImgV];
    [self.containerView addSubview:self.waitView];
    [self.containerView addSubview:self.statusLabel];
    [self.containerView addSubview:self.closeButton];
    [self.containerView addSubview:self.fullscreenButton];
    [self.containerView addSubview:self.volumeButton];
    [self.containerView addSubview:self.aiChatLab];
    [self.containerView addSubview:self.vipLab];
    [self.containerView addSubview:self.vipBtn];
    [self.containerView addSubview:self.toolsView];
    [self.containerView addSubview:self.chatView];
}

- (void)setupChatAssistantUI {
    [self.containerView setNeedsLayout];
    [self.containerView layoutIfNeeded];
    
    //全局背景
    [self.backImgV mas_remakeConstraints:^(MASConstraintMaker *make) {
        Top_Mas(self.containerView, 0);
        Left_Mas(self.containerView, 0);
        Right_Mas(self.containerView, 0);
        Bottom_Mas(self.containerView, 0);
    }];
    
    //等待动画
    [self.waitView mas_remakeConstraints:^(MASConstraintMaker *make) {
        Top_Mas(self.containerView, LS_Margin_8);
        CenterX_Mas(self.containerView, 0);
        Width_Mas(48 * COEFi0);
        Height_Mas(27 * COEFi0);
    }];
    
    //等待状态的视图
    [self.statusLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        Top_Mas_ViewBottom(self.waitView, - LS_Margin_4);
        CenterX_Mas(self.containerView, 0);
        Width_Mas(60 * COEFi0);
    }];
    
    if (self.isExpanded){
        //展开状态
        self.backImgV.image = PNGIMAGE(@"chatBack");
        
        [self hiddenWaitUI:YES];
        
        //调整关闭按钮位置
        [self.closeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            Top_Mas(self.containerView, LS_Margin_24);
            Left_Mas(self.containerView, LS_Margin_24);
            Width_Mas(LS_Margin_24);
            Height_Mas(LS_Margin_24);
        }];
    }else{
        //缩小状态
        self.backImgV.image = PNGIMAGE(@"zoomBack");
        
        [self hiddenWaitUI:NO];
        
        //调整关闭按钮位置
        [self.closeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            CenterY_Mas(self.containerView, 0);
            Left_Mas(self.containerView, LS_Margin_24);
            Width_Mas(LS_Margin_24);
            Height_Mas(LS_Margin_24);
        }];
    }
    
    // 全屏按钮（位置会在布局时调整）
    [self.fullscreenButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        CenterY_Mas(self.closeButton, 0);
        Right_Mas(self.containerView, LS_Margin_24);
        Width_Mas(LS_Margin_24);
        Height_Mas(LS_Margin_24);
    }];
    
    //音量按钮
    [self.volumeButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        Right_Mas_ViewLeft(self.fullscreenButton, LS_Margin_8);
        CenterY_Mas(self.closeButton, 0);
        Width_Mas(LS_Margin_24);
        Height_Mas(LS_Margin_24);
    }];
    
    [self.toolsView mas_remakeConstraints:^(MASConstraintMaker *make) {
        Left_Mas(self.containerView, LS_Margin_24);
        Width_Mas(171 * COEFi0);
        Height_Mas(40 * COEFi0);
        Bottom_Mas(self.containerView, LS_Margin_24);
    }];
    
    [self.vipLab mas_makeConstraints:^(MASConstraintMaker *make) {
        Bottom_Mas_ViewTop(self.toolsView, LS_Margin_4);
        CenterX_Mas(self.toolsView, 0);
        Width_Mas(188 * COEFi0);
    }];
    
    [self.vipBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        CenterY_Mas(self.toolsView, 0);
        Left_Mas_ViewRight(self.toolsView, LS_Margin_8);
        Width_Mas(LS_Margin_24);
        Height_Mas(LS_Margin_24);
    }];
    
    if (self.isExpanded){
        //展开状态
        [self.chatView mas_remakeConstraints:^(MASConstraintMaker *make) {
            CenterX_Mas(self.containerView, 0);
            Width_Mas(self.containerView.width - LS_Margin_12);
            Top_Mas_ViewBottom(self.closeButton, LS_Margin_24);
            Bottom_Mas_ViewTop(self.vipLab, LS_Margin_12);
        }];
        
        //内容或标题
        [self.aiChatLab mas_remakeConstraints:^(MASConstraintMaker *make) {
            CenterY_Mas(self.closeButton, 0);
            Left_Mas_ViewRight(self.closeButton, LS_Margin_12);
            Right_Mas_ViewLeft(self.volumeButton, LS_Margin_12);
        }];
        
        self.aiChatLab.text = AIVoiceShared.chatbotId;
    }else{
        //缩小状态
        [self.chatView mas_remakeConstraints:^(MASConstraintMaker *make) {
            CenterX_Mas(self.containerView, 0);
            Width_Mas(self.containerView.width - LS_Margin_12);
            Height_Mas(0);
            Top_Mas(self.containerView, 0);
        }];
        
        //内容或标题
        [self.aiChatLab mas_remakeConstraints:^(MASConstraintMaker *make) {
            CenterY_Mas(self.closeButton, 0);
            Width_Mas(144 * COEFi0);
            CenterX_Mas(self.containerView, 0);
        }];
    }
}

-(void)hiddenWaitUI:(BOOL)hide{
    // !hide缩小状态
    // hide展开状态
    
    self.waitView.hidden = hide;
    self.statusLabel.hidden = hide;
    self.toolsView.hidden = !hide;
    self.volumeButton.hidden = !hide;
    self.chatView.hidden = !hide;
    self.vipLab.hidden = !hide;
    self.vipBtn.hidden = !hide;
    
    if (!hide){
        //缩小
        [self.toolsView stopAnimal];
        
        [self changeUIWithIsThinking];
    }else{
        [self.waitView stop];
        
        [self.toolsView playAnimal];
        
        self.aiChatLab.text = AIVoiceShared.chatbotId;
    }
}

// 重写 hitTest，只在容器区域响应触摸
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    CGPoint containerPoint = [self convertPoint:point toView:self.containerView];
    
    if (CGRectContainsPoint(self.containerView.bounds, containerPoint)) {
        return [super hitTest:point withEvent:event];
    }
    
    return nil;
}

#pragma mark - Display Methods
-(void)showMinimizedAtScreen{
    if (SCREEN_H > SCREEN_W){
        //竖屏
        [self showMinimizedAtPoint:CGPointMake((SCREEN_MIN - 256 * COEFi0) / 2, SCREEN_MAX - 96 * COEFi0)];
    }else{
        //横屏
        [self showMinimizedAtPoint:CGPointMake(SCREEN_MAX - 256 * COEFi0, 64 * COEFi0)];
    }
}

- (void)showMinimizedAtPoint:(CGPoint)point {
    
    [self addToKeyWindow];
    
    self.isExpanded = NO;
   
    [AiViewManager shared].floatState = ChatMinimized;
    
    self.isShowing = YES;
    self.hidden = NO;
    
    CGFloat width = 256 * COEFi0;
    CGFloat height = 64 * COEFi0;
    
    //设置容器大小和位置
    self.containerView.frame = CGRectMake(0, 0, width, height);
    self.frame = CGRectMake(point.x, point.y, width, height);
    
    //创建UI
    [self setupChatAssistantUI];
    
    // 动画显示
    [self animateShow];
}


-(void)showExpandedAtScreen{
    if (SCREEN_H > SCREEN_W){
        //竖屏
        [self showExpandedAtPoint:CGPointMake((SCREEN_MIN - 256 * COEFi0) / 2, SCREEN_MAX - SCREEN_MIN)];
    }else{
        //横屏
        [self showExpandedAtPoint:CGPointMake(SCREEN_MAX - 256 * COEFi0, 0)];
    }
}

- (void)showExpandedAtPoint:(CGPoint)point {
    [self addToKeyWindow];
    
    self.isExpanded = YES;
    
    [AiViewManager shared].floatState = ChatExpanded;
    
    self.isShowing = YES;
    self.hidden = NO;
    
    CGFloat width = 256 * COEFi0;
    CGFloat height = 375 * COEFi0;
    
    // 设置容器大小和位置
    self.containerView.frame = CGRectMake(0, 0, width, height);
    self.frame = CGRectMake(point.x , point.y, width, height);

    //创建UI
    [self setupChatAssistantUI];
    
    //动画显示
    [self animateShow];
}

- (void)animateShow {
    UIWindow *keyWindow = [self getKeyWindow];
    
    CGRect finalFrame = self.frame;
    
    CGRect startFrame = finalFrame;
    
    if (SCREEN_H > SCREEN_W){
        //竖屏
        startFrame.origin.y = keyWindow.bounds.size.height;
    }else{
        //横屏
        startFrame.origin.x = keyWindow.bounds.size.width;
    }
    
    self.frame = startFrame;
    self.containerView.alpha = 0;
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.8  options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        self.frame = finalFrame;
        
        self.containerView.alpha = 1;
        
        [keyWindow bringSubviewToFront:self];
    
    } completion:nil];
    
    [AIVoiceShared switchVoiceVolume:!self.volumeButton.selected];
}

- (void)hide {
    [self hideAnimated:YES];
}

- (void)hideAnimated:(BOOL)animated {
    
    if (!self.isShowing) {
        return;
    }
    
    if (!animated) {
        self.isShowing = NO;
        self.hidden = YES;
        return;
    }
    
    UIWindow *keyWindow = [self getKeyWindow];
    
    CGRect finalFrame = self.frame;
    
    if (SCREEN_H > SCREEN_W){
        //竖屏
        finalFrame.origin.y = keyWindow.bounds.size.height;
    }else{
        //横屏
        finalFrame.origin.x = keyWindow.bounds.size.width;
    }
    
    
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        self.frame = finalFrame;
        self.containerView.alpha = 0;
        
    } completion:^(BOOL finished) {
        self.isShowing = NO;
        self.hidden = YES;
        self.containerView.alpha = 1;
    }];
}

#pragma mark - Content Update
-(void)updateToolWithChatState:(AiVoiceChatState)chatState{
//    NSLog(@"当前chatState状态:%ld",(long)chatState);
    
    if (chatState == CHAT_Connecting || chatState == CHAT_Reconnect || chatState == CHAT_NotVip){
        //重连和连接中
        dispatch_async(dispatch_get_main_queue(), ^{
            self.toolsView.chatState = chatState;
        });
    }else{
        //其他状态需要查看当前是否在重连或者连接中
        if (AIVoiceShared.connectState != Connecting && AIVoiceShared.connectState != LoseConnect && AIVoiceShared.isUserVip){
            //没有重连和连接中,并且VIP可用
            dispatch_async(dispatch_get_main_queue(), ^{
                self.toolsView.chatState = chatState;
            });
        }
    }
}

#pragma mark - MessageUpdate Methods

///智能体状态更新
-(void)updateConvMessage:(ConversationStatusMessage *)convMsg{
    [self.chatView updateConvMessage:convMsg];
    
    if (convMsg.stage.code == Message_THINKING){
        self.isThinking = YES;
    }
    
    QueueStartAfterTime(.5)
    
    [self changeUIWithIsThinking];
    
    queueEnd
}

///实时语音文本更新
-(void)updateSubvMessage:(SubtitleMsgData *)subvMsg{
    
    if ([subvMsg isBotCompleteSentenceAndPlayAudio:AIVoiceShared.chatbotId]){
        //如果机器人回复的是特殊字段，那么组装一条字段，并播放预知的音频
        subvMsg.text = kLocalizedString(@"ReplySpecial", nil);
        
        [AIVoiceShared palySpeciaAudio];
    }
    
    if (isStringEmpty(subvMsg.text)){
        return;
    }
    
    [self.chatView updateSubvMessage:subvMsg];
    
    self.isThinking = NO;
    
    self.lastMsg = [[SubtitleTextAssembler sharedAssembler] assembleText:subvMsg];
    
    QueueStartAfterTime(.2)
    
    [self changeUIWithIsThinking];
    
    queueEnd
}

-(void)updateChatTitle:(NSString *)titleStr{
    if (!isStringEmpty(titleStr) && self.isExpanded){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.aiChatLab.text = titleStr;
        });
    }
}

-(void)updateVipTitle:(NSString *)vipTitle{
    self.vipLab.text = vipTitle;
}

///根据isThinking修改UI
-(void)changeUIWithIsThinking{
    if (!self.isExpanded){
        //缩小状态
        self.aiChatLab.text = self.lastMsg;
        
        if (self.isThinking){
            //思考中
            self.statusLabel.hidden = NO;
            self.waitView.hidden = NO;
            [self.waitView play];
            
            self.aiChatLab.hidden = YES;
        }else{
            self.statusLabel.hidden = YES;
            
            self.waitView.hidden = YES;
            [self.waitView stop];
            
            self.aiChatLab.hidden = NO;
        }
    }
}

#pragma mark - Helper Methods

- (void)addToKeyWindow {
    UIWindow *keyWindow = [self getKeyWindow];
    
    if (!keyWindow) {
        NSLog(@"⚠️ ChatAssistantView: No key window available");
        return;
    }
    
    if (self.superview != keyWindow) {
        [self removeFromSuperview];
        [keyWindow addSubview:self];
        [keyWindow bringSubviewToFront:self];
    }
}

- (UIWindow *)getKeyWindow {
    UIWindow *keyWindow = nil;
    
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *window in scene.windows) {
                    if (window.isKeyWindow) {
                        keyWindow = window;
                        break;
                    }
                }
                if (keyWindow) break;
            }
        }
    }
    
    if (!keyWindow) {
        keyWindow = [UIApplication sharedApplication].keyWindow;
    }
    
    return keyWindow;
}

- (CGPoint)calculatePointForPosition:(ChatAssistantPosition)position isExpanded:(BOOL)isExpanded {
    UIWindow *keyWindow = [self getKeyWindow];
    CGRect screenBounds = keyWindow ? keyWindow.bounds : [UIScreen mainScreen].bounds;
    
    CGFloat screenWidth = screenBounds.size.width;
    CGFloat width = screenWidth - 40 * COEFi0;
    CGFloat height = isExpanded ? 400 * COEFi0 : 60 * COEFi0;
    CGFloat horizontalInset = 20 * COEFi0;
    CGFloat verticalInset = isExpanded ? 100 * COEFi0 : 120 * COEFi0;
    
    CGPoint point = CGPointZero;
    
    switch (position) {
        case ChatAssistantPositionTop:
            point = CGPointMake(screenBounds.size.width / 2, verticalInset + height / 2);
            break;
            
        case ChatAssistantPositionBottom:
            point = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height - verticalInset - height / 2);
            break;
            
        case ChatAssistantPositionTopLeft:
            point = CGPointMake(horizontalInset + width / 2, verticalInset + height / 2);
            break;
            
        case ChatAssistantPositionTopRight:
            point = CGPointMake(screenBounds.size.width - horizontalInset - width / 2, verticalInset + height / 2);
            break;
            
        case ChatAssistantPositionBottomLeft:
            point = CGPointMake(horizontalInset + width / 2, screenBounds.size.height - verticalInset - height / 2);
            break;
            
        case ChatAssistantPositionBottomRight:
            point = CGPointMake(screenBounds.size.width - horizontalInset - width / 2, screenBounds.size.height - verticalInset - height / 2);
            break;
            
        case ChatAssistantPositionCenter:
            point = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height / 2);
            break;
            
        case ChatAssistantPositionCustom:
            // 默认底部居中
            point = CGPointMake(screenBounds.size.width / 2, screenBounds.size.height - verticalInset - height / 2);
            break;
    }
    
    return point;
}

#pragma mark - Button Actions

- (void)closeButtonTapped:(UIButton *)sender {
    
    if ([self.delegate respondsToSelector:@selector(chatAssistantViewCloseButtonTapped:)]) {
        [self.delegate chatAssistantViewCloseButtonTapped:self];
    }
}

- (void)volumeButtonTapped:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    
    if ([self.delegate respondsToSelector:@selector(chatAssistantViewVolumeButtonTapped:isSec:)]) {
        [self.delegate chatAssistantViewVolumeButtonTapped:self isSec:sender.isSelected];
    }
    
}

- (void)fullscreenButtonTapped:(UIButton *)sender {
    
    if (self.isExpanded){
        [self showMinimizedAtScreen];
    }else{
        [self showExpandedAtScreen];
    }
    
//    if ([self.delegate respondsToSelector:@selector(chatAssistantViewFullscreenButtonTapped:)]) {
//        [self.delegate chatAssistantViewFullscreenButtonTapped:self];
//    }
}

//会员按钮
-(void)vipButtonTapped:(UIButton *)sender{
    
    if ([self.delegate respondsToSelector:@selector(chatAssistantViewVipButtonTapped:)]) {
        [self.delegate chatAssistantViewVipButtonTapped:self];
    }
}

#pragma mark - Cleanup

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[SubtitleTextAssembler sharedAssembler] clearCache];
}

@end
