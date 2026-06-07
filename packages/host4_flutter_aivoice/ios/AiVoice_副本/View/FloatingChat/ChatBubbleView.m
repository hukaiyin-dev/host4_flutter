//
//  ChatBubbleView.m
//  支持动态状态的聊天气泡视图
//

#import "ChatBubbleView.h"
#import "SubtitleTextAssembler.h"

#pragma mark - Message Model

@implementation ChatMessage

+ (instancetype)messageWithType:(ChatMessageType)type text:(NSString *)text {
    ChatMessage *message = [[ChatMessage alloc] init];
    message.type = type;
    message.text = text;
    return message;
}

+(instancetype)messageWithInfo:(ChatMessageType)type text:(NSString *)text roundId:(NSInteger)roundId{
    ChatMessage *message = [[ChatMessage alloc] init];
    message.type = type;
    message.text = text;
    message.roundId = roundId;
    return message;
}

@end

#pragma mark - Message Cell

@interface ChatMessageCell : UIView

@property (nonatomic, strong) ChatMessage *message;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) UIView *overlayContainer; // overlay视图容器
@property (nonatomic, strong) UIView *hintContainer; // 提示容器
@property (nonatomic, strong) UILabel *hintLabel; // 提示文本
@property (nonatomic, strong) UIImageView *hintIconView; // 提示图标
@property (nonatomic, strong) UIImageView *avatarView; // 头像视图

// ✅ 添加：渐变层属性
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@property (nonatomic, copy) void(^onTap)(void);

//最小宽度
@property (nonatomic, assign) CGFloat minWidth;
//最大宽度
@property (nonatomic, assign) CGFloat maxWidth;


- (instancetype)initWithMessage:(ChatMessage *)message
                      userColor:(UIColor *)userColor
                        aiColor:(UIColor *)aiColor
                      textColor:(UIColor *)textColor
                           font:(UIFont *)font
                  hintTextColor:(UIColor *)hintTextColor
                       hintFont:(UIFont *)hintFont;
- (void)updateWithMessage:(ChatMessage *)message;
- (CGFloat)calculateHeight;

@end

@implementation ChatMessageCell

- (instancetype)initWithMessage:(ChatMessage *)message
                      userColor:(UIColor *)userColor
                        aiColor:(UIColor *)aiColor
                      textColor:(UIColor *)textColor
                           font:(UIFont *)font
                  hintTextColor:(UIColor *)hintTextColor
                       hintFont:(UIFont *)hintFont {
    self = [super init];
    if (self) {
        self.message = message;
        
//        _minWidth = 60 * COEFi0;
        _minWidth = LS_Margin_16;
        _maxWidth = 170 * COEFi0;
        
        [self setupUIWithUserColor:userColor
                           aiColor:aiColor
                         textColor:textColor
                              font:font
                     hintTextColor:hintTextColor
                          hintFont:hintFont];
        [self updateLayout];
    }
    return self;
}

- (void)setupUIWithUserColor:(UIColor *)userColor
                     aiColor:(UIColor *)aiColor
                   textColor:(UIColor *)textColor
                        font:(UIFont *)font
               hintTextColor:(UIColor *)hintTextColor
                    hintFont:(UIFont *)hintFont {
    
    // 气泡背景
    self.bubbleView = [[UIView alloc] init];
    
    // ✅ 根据消息类型设置背景
    if (self.message.type == ChatMessageTypeUser) {
        // 用户消息：使用渐变色（将在 setupUserGradientBackground 中设置）
        self.bubbleView.backgroundColor = [UIColor clearColor];
    } else {
        // AI 消息：使用纯色
        self.bubbleView.backgroundColor = aiColor;
    }
    
    self.bubbleView.layer.cornerRadius = 8 * COEFi0;
    
    self.bubbleView.clipsToBounds = YES;
    [self addSubview:self.bubbleView];
    
    // 添加点击手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    self.bubbleView.userInteractionEnabled = YES;
    [self.bubbleView addGestureRecognizer:tap];
    
    // 文本标签
    self.textLabel = [[UILabel alloc] init];
    self.textLabel.textColor = textColor;
    self.textLabel.font = font;
    self.textLabel.numberOfLines = 0;
    self.textLabel.text = self.message.text;
    [self.bubbleView addSubview:self.textLabel];
    
    // Overlay容器（用于放置三点动画等自定义视图）
    self.overlayContainer = [[UIView alloc] init];
    self.overlayContainer.backgroundColor = [UIColor clearColor];
    self.overlayContainer.hidden = YES;
    [self.bubbleView addSubview:self.overlayContainer];
    
    // 提示容器
    self.hintContainer = [[UIView alloc] init];
    self.hintContainer.backgroundColor = [UIColor clearColor];
    self.hintContainer.hidden = YES;
    [self addSubview:self.hintContainer];
    
    // 提示图标
    self.hintIconView = [[UIImageView alloc] init];
    self.hintIconView.contentMode = UIViewContentModeScaleAspectFit;
    self.hintIconView.hidden = YES;
    [self.hintContainer addSubview:self.hintIconView];
    
    // 提示文本
    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.textColor = hintTextColor;
    self.hintLabel.font = hintFont;
    self.hintLabel.numberOfLines = 0;
    [self.hintContainer addSubview:self.hintLabel];
    
    // 头像视图（在气泡外部）
    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.avatarView];
    
    // 设置默认图标
    if (self.message.avatarImage) {
        self.avatarView.image = self.message.avatarImage;
    } else {
        // 使用系统图标作为默认
        NSString *iconName = self.message.type == ChatMessageTypeAI ? @"AiAvatar" : @"";
        self.avatarView.image = PNGIMAGE(@"AiAvatar");
    }
}

// ✅ 添加：设置用户气泡的渐变背景
- (void)setupUserGradientBackground {
    if (self.message.type != ChatMessageTypeUser) {
        return; // 只为用户消息设置渐变
    }
    
    // 移除旧的渐变层（如果存在）
    if (self.gradientLayer) {
        [self.gradientLayer removeFromSuperlayer];
    }
    
    // 创建渐变层
    self.gradientLayer = [CAGradientLayer layer];
    
    // 设置渐变颜色
    // 起始颜色: rgba(47, 248, 109, 1) - 鲜绿色
    UIColor *startColor = appGradientStartColor;
    
    // 结束颜色: rgba(62, 255, 174, 1) - 青绿色
    UIColor *endColor = appGradientEndColor;
    
    self.gradientLayer.colors = @[(__bridge id)startColor.CGColor, (__bridge id)endColor.CGColor];
    
    // 设置渐变方向（水平：从左到右）
    self.gradientLayer.startPoint = CGPointMake(0, 0.5);  // 左边中间
    self.gradientLayer.endPoint = CGPointMake(1, 0.5);    // 右边中间
    
    // 设置圆角（与气泡一致）
    self.gradientLayer.cornerRadius = 8 * COEFi0;
    
    // 设置渐变层的 frame（将在 layoutSubviews 中更新）
    self.gradientLayer.frame = self.bubbleView.bounds;
    
    // 插入到最底层
    [self.bubbleView.layer insertSublayer:self.gradientLayer atIndex:0];
    
    __weak CAGradientLayer *weakGl = self.gradientLayer;
    self.bubbleView.themeBlock = ^(__kindof UIView *v) {
        weakGl.colors = @[(__bridge id)appGradientStartColor.CGColor, (__bridge id)appGradientEndColor.CGColor];
    };
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (self.onTap) {
        self.onTap();
    }
}

- (void)updateWithMessage:(ChatMessage *)message {
    self.message = message;
    self.textLabel.text = message.text;
    
    // 更新overlay
    for (UIView *subview in self.overlayContainer.subviews) {
        [subview removeFromSuperview];
    }
    
    if (message.overlayView) {
        self.overlayContainer.hidden = NO;
        [self.overlayContainer addSubview:message.overlayView];
    } else {
        self.overlayContainer.hidden = YES;
    }
    
    // 更新提示
    if (message.hintText) {
        self.hintContainer.hidden = NO;
        self.hintLabel.text = message.hintText;
        
        if (message.showHintIcon) {
            self.hintIconView.hidden = NO;
            // 使用系统图标或文本
            self.hintIconView.image = [UIImage systemImageNamed:@"exclamationmark.circle"];
            self.hintIconView.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
        } else {
            self.hintIconView.hidden = YES;
        }
    } else {
        self.hintContainer.hidden = YES;
    }
    
    // 更新头像
    if (message.avatarImage) {
        self.avatarView.image = message.avatarImage;
    } else {
        NSString *iconName = message.type == ChatMessageTypeAI ? @"AiAvatar" : @"";
        self.avatarView.image = PNGIMAGE(@"AiAvatar");
    }
    
    [self updateLayout];
}

- (void)updateLayout {
    
    CGFloat maxWidth = _maxWidth; // 增加最大宽度以适应各种语言
    
    CGFloat padding = LS_Margin_24;   // 左右内边距
    
    // 使用 UILabel 的 sizeThatFits 获取更精确的文本尺寸
    // 这个方法能更好地处理不同语言（中文、英文、日文、韩文等）
    self.textLabel.numberOfLines = 0;
    self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    CGSize constraintSize = CGSizeMake(maxWidth - padding, CGFLOAT_MAX);
    CGSize textSize = [self.textLabel sizeThatFits:constraintSize];
    
    // 向上取整避免截断
    textSize.width = ceil(textSize.width);
    textSize.height = ceil(textSize.height);
    
    // 如果文本很短，使用 boundingRect 获取最小宽度
    if (textSize.width < _minWidth) {
        CGSize minSize = [self.message.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: self.textLabel.font} context:nil].size;
        
        textSize.width = MAX(ceil(minSize.width), textSize.width);
    }
    
    CGFloat bubbleWidth = textSize.width + LS_Margin_16;
    CGFloat bubbleHeight = textSize.height + LS_Margin_16;
    
    // 确保最小尺寸和最大宽度
    bubbleWidth = MAX(bubbleWidth, _minWidth);
    
    bubbleWidth = MIN(bubbleWidth, maxWidth);
    
    bubbleHeight = MAX(bubbleHeight, LS_Margin_32);
    
    if (!self.overlayContainer.hidden && self.message.overlayView) {
        bubbleWidth = 60 * COEFi0;
    }
    
    // 根据消息类型设置气泡位置
    // AI在左侧(24)，用户在右侧
    CGFloat bubbleX = self.message.type == ChatMessageTypeAI ? LS_Margin_24 :
    (self.bounds.size.width > 0 ? self.bounds.size.width - bubbleWidth - LS_Margin_24 : 244 * COEFi0 - bubbleWidth);
    
    self.bubbleView.frame = CGRectMake(bubbleX, 0, bubbleWidth, bubbleHeight);
    
    // 设置文本位置
    self.textLabel.frame = CGRectMake(LS_Margin_8, LS_Margin_8, textSize.width, textSize.height);
    
//    if (textSize.width <= _minWidth){
//        //居中
//        self.textLabel.centerX = _minWidth / 2;
//    }
    
    // 设置overlay位置（在气泡左下角）
    if (!self.overlayContainer.hidden && self.message.overlayView) {
        
        CGSize overlaySize = self.message.overlayView.frame.size;
        
        if (CGSizeEqualToSize(overlaySize, CGSizeZero)) {
            overlaySize = [self.message.overlayView sizeThatFits:CGSizeMake(100, 100)];
        }
        
        // overlay在气泡左下角
        CGFloat overlayX = 18 * COEFi0;
        
        CGFloat overlayY = (bubbleHeight - overlaySize.height) / 2;
        
        self.overlayContainer.frame = CGRectMake(overlayX, overlayY, overlaySize.width, overlaySize.height);
        
        self.message.overlayView.frame = CGRectMake(0, 0, overlaySize.width, overlaySize.height);
    }
    
    // 设置头像位置（在气泡外部的角落）
    CGFloat avatarSize = 14 * COEFi0;
    
    CGFloat avatarY = bubbleHeight - avatarSize; // 底部对齐
    
    if (self.message.type == ChatMessageTypeAI) {
        // AI头像在气泡左下角外部
        self.avatarView.frame = CGRectMake(bubbleX + bubbleWidth + LS_Margin_8, avatarY, avatarSize, avatarSize);
    } else {
        // 用户头像在气泡右下角外部
        self.avatarView.frame = CGRectMake(bubbleX + bubbleWidth + LS_Margin_4, avatarY, 0, 0);
    }
    
    // 设置提示容器位置（在气泡下方）
    if (!self.hintContainer.hidden && self.message.hintText) {
        CGFloat hintY = bubbleHeight + LS_Margin_8;
        CGFloat hintX = bubbleX;
        
        // 计算提示文本大小
        CGSize hintSize = [self.message.hintText boundingRectWithSize:CGSizeMake(200, CGFLOAT_MAX)
                                                              options:NSStringDrawingUsesLineFragmentOrigin
                                                           attributes:@{NSFontAttributeName: self.hintLabel.font}
                                                              context:nil].size;
        
        CGFloat iconWidth = self.message.showHintIcon ? LS_Margin_24 : 0;
        CGFloat totalWidth = iconWidth + hintSize.width + (self.message.showHintIcon ? LS_Margin_8 : 0);
        
        self.hintContainer.frame = CGRectMake(hintX, hintY, totalWidth, MAX(hintSize.height, LS_Margin_16));
        
        if (self.message.showHintIcon) {
            self.hintIconView.frame = CGRectMake(0, 0, LS_Margin_24, LS_Margin_24);
            self.hintLabel.frame = CGRectMake(LS_Margin_32, 0, hintSize.width, hintSize.height);
        } else {
            self.hintLabel.frame = CGRectMake(0, 0, hintSize.width, hintSize.height);
        }
    }
    
    // ✅ 添加：设置用户气泡的渐变背景
    if (self.message.type == ChatMessageTypeUser) {
        [self setupUserGradientBackground];
    }
}

// ✅ 添加：更新渐变层的 frame
- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 更新渐变层的大小以匹配气泡视图
    if (self.gradientLayer && self.message.type == ChatMessageTypeUser) {
        self.gradientLayer.frame = self.bubbleView.bounds;
    }
}

- (CGFloat)calculateHeight {
    CGFloat maxWidth = _maxWidth;
    CGFloat padding = LS_Margin_24;
    
    // 创建临时 label 来计算尺寸（如果还没有 textLabel）
    if (!self.textLabel) {
        UILabel *tempLabel = [[UILabel alloc] init];
        tempLabel.font = [UIFont systemFontOfSize:14];
        tempLabel.text = self.message.text;
        tempLabel.numberOfLines = 0;
        tempLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        CGSize constraintSize = CGSizeMake(maxWidth - padding, CGFLOAT_MAX);
        CGSize textSize = [tempLabel sizeThatFits:constraintSize];
        textSize.height = ceil(textSize.height);
        
        CGFloat bubbleHeight = textSize.height + LS_Margin_16;
        bubbleHeight = MAX(bubbleHeight, LS_Margin_32);
        
        CGFloat totalHeight = bubbleHeight;
        
        // 添加提示文本高度
        if (self.message.hintText) {
            UILabel *tempHintLabel = [[UILabel alloc] init];
            tempHintLabel.font = [UIFont systemFontOfSize:12];
            tempHintLabel.text = self.message.hintText;
            tempHintLabel.numberOfLines = 0;
            
            CGSize hintSize = [tempHintLabel sizeThatFits:CGSizeMake(120 * COEFi0, CGFLOAT_MAX)];
            totalHeight += ceil(hintSize.height) + LS_Margin_8;
        }
        
        return totalHeight + LS_Margin_16;
    }
    
    // 如果有 textLabel，直接使用
    CGSize constraintSize = CGSizeMake(maxWidth - padding, CGFLOAT_MAX);
    CGSize textSize = [self.textLabel sizeThatFits:constraintSize];
    textSize.height = ceil(textSize.height);
    
    CGFloat bubbleHeight = textSize.height + LS_Margin_16;
    bubbleHeight = MAX(bubbleHeight, LS_Margin_32);
    
    CGFloat totalHeight = bubbleHeight;
    
    // 添加提示文本高度
    if (self.message.hintText && self.hintLabel) {
        CGSize hintSize = [self.hintLabel sizeThatFits:CGSizeMake(120 * COEFi0, CGFLOAT_MAX)];
        totalHeight += ceil(hintSize.height) + LS_Margin_8;
    }
    
    return totalHeight + LS_Margin_16; // 添加底部间距
}

@end

#pragma mark - Main View

@interface ChatBubbleView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSMutableArray<ChatMessage *> *messages;
@property (nonatomic, strong) NSMutableArray<ChatMessageCell *> *cellViews;


@end

@implementation ChatBubbleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (NSInteger)lastMsgIndex{
    return self.messages.count - 1;
}

- (void)commonInit {
    _messages = [NSMutableArray array];
    _cellViews = [NSMutableArray array];
    
    // 默认颜色
    _userBubbleColor = [UIColor systemPurpleColor];
    _aiBubbleColor = [[UIColor colorWithWhite:0.25 alpha:1.0] colorWithAlphaComponent:0.8];
    _messageTextColor = [UIColor whiteColor];
    _messageFont = [UIFont systemFontOfSize:15];
    _hintTextColor = [[UIColor whiteColor] colorWithAlphaComponent:0.6];
    _hintFont = [UIFont systemFontOfSize:12];
    
    [self setupUI];
}

- (void)setupUI {
    // 滚动视图
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self addSubview:self.scrollView];
    
    // 内容视图
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 0)];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.scrollView addSubview:self.contentView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutMessages];
}

#pragma mark - 外部消息更新
-(void)updateSubvMessage:(SubtitleMsgData *)subvMsg{
    
    //buubleIndex是当前消息的index
    int buubleIndex = [self searchLocalMsgCell:subvMsg.roundId msgType:subvMsg.msgType];
    
    NSString *completeText = [[SubtitleTextAssembler sharedAssembler] assembleText:subvMsg];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (buubleIndex >= 0){
            if (subvMsg.msgType == ChatMessageTypeAI){
                [self clearOverlayAndHintAtIndex:buubleIndex];
            }

            //如果存在，更新
            [self updateMessageAtIndex:buubleIndex withText:completeText];
            
        }else{
            //不存在，需要添加
            ChatMessage *msg = [ChatMessage messageWithInfo:subvMsg.msgType text:completeText roundId:subvMsg.roundId];
            
            [self addMessage:msg];
        }
        
        [self scrollToBottomAnimated:YES];
    });
}

-(void)updateConvMessage:(ConversationStatusMessage *)convMsg{
    ///convMsg的永远是AI的消息状态
    int buubleIndex = [self searchLocalMsgCell:convMsg.roundID msgType:ChatMessageTypeAI];

//    NSLog(@"chat更新conv消息，当前总cell%lu,当前index%d", (unsigned long)self.messages.count, buubleIndex);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (buubleIndex < 0){
            //不存在，如果AI的状态是THINKING，添加一个三个点加载的cell
            if (convMsg.stage.code ==
                Message_THINKING){
                
                ChatMessage *msg = [ChatMessage messageWithInfo:ChatMessageTypeAI text:@"" roundId:convMsg.roundID];
                
                [self addMessage:msg];
                
                [self setMessageSpeakingAtIndex:self.lastMsgIndex withHint:kLocalizedString(@"InstructionAnalysis", nil)];
            }
        }else{
            //如果存在
            if (convMsg.stage.code == Message_INTERRUPT || convMsg.stage.code == Message_COMPLETE){
                //收到conv被打断或者完成的时候，先判断气泡当中有无文本，如果没有文本，那么删除
                ChatMessage *msg = self.messages[buubleIndex];
                
                if (isStringEmpty(msg.text)){
                    [self removeMessageAtIndex:buubleIndex];
                }
            }
        }
        
        [self scrollToBottomAnimated:YES];
    });
}

//根据当前conv或者subv的roundId判断历史是否存在
-(int)searchLocalMsgCell:(NSInteger)roundId msgType:(ChatMessageType)msgType{
    
    for (ChatMessage *chatMsg in self.messages){
        
        if (roundId == chatMsg.roundId && msgType == chatMsg.type){
            //表示当前用户的同一个section的消息存在
            return (int)[self.messages indexOfObject:chatMsg];
        }
    }
    
    return -1;
}


#pragma mark - Message Management

- (void)addMessage:(ChatMessage *)message {
    [self addMessage:message animated:YES];
}

- (void)addMessage:(ChatMessage *)message animated:(BOOL)animated {
    [self.messages addObject:message];
    
    ChatMessageCell *cell = [[ChatMessageCell alloc] initWithMessage:message userColor:self.userBubbleColor aiColor:self.aiBubbleColor textColor:self.messageTextColor font:self.messageFont hintTextColor:self.hintTextColor hintFont:self.hintFont];
    
    __weak typeof(self) weakSelf = self;
    cell.onTap = ^{
        NSInteger index = [weakSelf.messages indexOfObject:message];
        if ([weakSelf.delegate respondsToSelector:@selector(chatBubbleView:didTapMessageAtIndex:)]) {
            [weakSelf.delegate chatBubbleView:weakSelf didTapMessageAtIndex:index];
        }
    };
    
    [self.cellViews addObject:cell];
    [self.contentView addSubview:cell];
    
    [self layoutMessages];
    
    if (animated) {
        cell.alpha = 0;
        cell.transform = CGAffineTransformMakeTranslation(0, 20);
        [UIView animateWithDuration:0.3 animations:^{
            cell.alpha = 1;
            cell.transform = CGAffineTransformIdentity;
        }];
    }
    
    // 滚动到底部
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self scrollToBottomAnimated:animated];
    });
}

- (void)addUserMessage:(NSString *)text {
    ChatMessage *message = [ChatMessage messageWithType:ChatMessageTypeUser text:text];
    [self addMessage:message];
}

- (void)addAIMessage:(NSString *)text {
    ChatMessage *message = [ChatMessage messageWithType:ChatMessageTypeAI text:text];
    [self addMessage:message];
}

- (void)updateMessageAtIndex:(NSInteger)index withText:(NSString *)text {
    if (index < 0 || index >= self.messages.count) return;
    
    ChatMessage *message = self.messages[index];
    message.text = text;
    
    ChatMessageCell *cell = self.cellViews[index];
    [cell updateWithMessage:message];
    [self layoutMessages];
}

- (void)updateMessageAtIndex:(NSInteger)index
                 withOverlay:(UIView *)overlayView
                    hintText:(NSString *)hintText
                    showIcon:(BOOL)showIcon {
    if (index < 0 || index >= self.messages.count) return;
    
    ChatMessage *message = self.messages[index];
    message.overlayView = overlayView;
    message.hintText = hintText;
    message.showHintIcon = showIcon;
    
    ChatMessageCell *cell = self.cellViews[index];
    [cell updateWithMessage:message];
    [self layoutMessages];
}

- (void)clearOverlayAndHintAtIndex:(NSInteger)index {
    [self updateMessageAtIndex:index withOverlay:nil hintText:nil showIcon:NO];
}

- (void)removeMessageAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.messages.count) return;
    
    [self.messages removeObjectAtIndex:index];
    
    ChatMessageCell *cell = self.cellViews[index];
    [self.cellViews removeObjectAtIndex:index];
    [cell removeFromSuperview];
    
    [self layoutMessages];
}

- (void)clearAllMessages {
    [self.messages removeAllObjects];
    
    for (ChatMessageCell *cell in self.cellViews) {
        [cell removeFromSuperview];
    }
    [self.cellViews removeAllObjects];
    
    [self layoutMessages];
}

- (void)layoutMessages {
    CGFloat currentY = 20;
    CGFloat contentWidth = self.scrollView.bounds.size.width > 0 ? self.scrollView.bounds.size.width : self.bounds.size.width;
    
    for (ChatMessageCell *cell in self.cellViews) {
        CGFloat cellHeight = [cell calculateHeight];
        cell.frame = CGRectMake(0, currentY, contentWidth, cellHeight);
        [cell updateLayout];
        currentY += cellHeight;
    }
    
    // 更新内容视图大小
    self.contentView.frame = CGRectMake(0, 0, contentWidth, currentY + 20);
    self.scrollView.contentSize = CGSizeMake(contentWidth, currentY + 20);
}

#pragma mark - Convenience Methods

- (void)setMessageAnalyzingAtIndex:(NSInteger)index {
    UIView *dotsView = [self createThreeDotsAnimationView];
    [self updateMessageAtIndex:index withOverlay:dotsView hintText:kLocalizedString(@"InstructionAnalysis", nil)  showIcon:NO];
}

- (void)setMessageSpeakingAtIndex:(NSInteger)index withHint:(NSString *)hintText {
    UIView *dotsView = [self createThreeDotsAnimationView];
    [self updateMessageAtIndex:index
                   withOverlay:dotsView
                      hintText:hintText
                      showIcon:NO];
}

- (void)setMessageNetworkErrorAtIndex:(NSInteger)index {
    [self setMessageNetworkErrorAtIndex:index withHint:@"网络错误，请检查网络连接"];
}

- (void)setMessageNetworkErrorAtIndex:(NSInteger)index withHint:(NSString *)hintText {
    [self updateMessageAtIndex:index
                   withOverlay:nil
                      hintText:hintText
                      showIcon:YES];
}

- (void)finishMessageAtIndex:(NSInteger)index withFinalText:(NSString *)text {
    if (index < 0 || index >= self.messages.count) return;
    
    // 先更新文本
    [self updateMessageAtIndex:index withText:text];
    
    // 然后清除overlay和提示
    [self clearOverlayAndHintAtIndex:index];
}

#pragma mark - Helper Methods

- (UIView *)createThreeDotsAnimationView {
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, LS_Margin_24, LS_Margin_4)];
    
    containerView.backgroundColor = [UIColor clearColor]; // 透明背景
    
    // 创建三个点
    for (int i = 0; i < 3; i++) {
        
        UIView *dot = [[UIView alloc] initWithFrame:CGRectMake(i * (LS_Margin_4 + 6 * COEFi0), 0, LS_Margin_4, LS_Margin_4)];
        
        dot.backgroundColor = [UIColor whiteColor];
        
        dot.layer.cornerRadius = LS_Margin_4 / 2;
        
        dot.tag = 3000 + i;
        
        [containerView addSubview:dot];
    }
    
    // 启动动画
    [self startDotsAnimation:containerView];
    
    return containerView;
}

- (void)startDotsAnimation:(UIView *)containerView {
    __block int currentDot = 0;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.3 repeats:YES block:^(NSTimer *t) {
        for (int i = 0; i < 3; i++) {
            UIView *dot = [containerView viewWithTag:3000 + i];
            if (dot) {
                dot.alpha = (i == currentDot) ? 1.0 : 0.3;
            }
        }
        currentDot = (currentDot + 1) % 3;
    }];
    
    // 保存timer到containerView，以便清理
    objc_setAssociatedObject(containerView, "animationTimer", timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Scroll

- (void)scrollToBottom {
    [self scrollToBottomAnimated:YES];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    CGFloat offsetY = MAX(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height);
    [self.scrollView setContentOffset:CGPointMake(0, offsetY) animated:animated];
}

#pragma mark - Cleanup

- (void)dealloc {
    // 清理所有timer
    for (ChatMessageCell *cell in self.cellViews) {
        if (cell.message.overlayView) {
            NSTimer *timer = objc_getAssociatedObject(cell.message.overlayView, "animationTimer");
            if (timer) {
                [timer invalidate];
            }
        }
    }
}

@end
