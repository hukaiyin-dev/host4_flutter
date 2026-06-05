//
//  SubtitleMsgData+Validation.h
//  GameMacro
//
//  判断 subv 消息是否为完整句子的扩展
//

#pragma mark - 句子类型枚举

typedef NS_ENUM(NSInteger, SubtitleSentenceType) {
    SubtitleSentenceTypeIncomplete = 0,     // 不完整句子
    SubtitleSentenceTypeComplete = 1,       // 正常完整句子
    SubtitleSentenceTypeEmpty = 2,          // 完整但内容为空
    SubtitleSentenceTypeSpecialSymbol = 3,  // 完整但只有特殊符号
    SubtitleSentenceTypeParagraphEnd = 4    // 段落结束
};

#import "SubtitleMsgData.h"

NS_ASSUME_NONNULL_BEGIN

@interface SubtitleMsgData (Validation)

#pragma mark - 机器人消息判断

/**
 * 判断是否为机器人消息
 * @param botUserIds 机器人的 userId 列表（支持多个机器人）
 * @return YES: 机器人消息, NO: 用户消息
 */
- (BOOL)isBotMessageWithBotIds:(NSArray<NSString *> *)botUserIds;

/**
 * 判断是否为指定机器人的消息
 * @param botUserId 机器人的 userId
 * @return YES: 该机器人的消息, NO: 其他消息
 */
- (BOOL)isBotMessage:(NSString *)botUserId;

#pragma mark - 完整句子判断

/**
 * 判断是否为完整句子
 * @return YES: 完整句子, NO: 不完整
 *
 * 判断逻辑:
 * 1. definite = true: 完整的分句
 * 2. paragraph = true: 段落结束（通常也是完整句子）
 */
- (BOOL)isCompleteSentence;

/**
 * 判断是否为段落结束
 * @return YES: 段落结束, NO: 段落未结束
 */
- (BOOL)isParagraphEnd;

#pragma mark - 特殊内容判断

/**
 * 判断文本内容是否为空或无效
 * @return YES: 空或无效, NO: 有效内容
 *
 * 判断条件:
 * - text 为 nil
 * - text 为空字符串
 * - text 只包含空白字符
 */
- (BOOL)isEmptyOrNil;

/**
 * 判断文本内容是否为特殊符号（如 ~）
 * @return YES: 特殊符号, NO: 正常内容
 */
- (BOOL)isSpecialSymbol;

/**
 * 判断是否需要特殊处理
 * @return YES: 需要特殊处理, NO: 正常处理
 *
 * 特殊处理条件:
 * - 文本为 "~"
 * - 文本为空或 nil
 * - 文本只包含特殊符号
 */
- (BOOL)needsSpecialHandling;

#pragma mark - 综合判断

/**
 * 判断机器人的完整句子是否需要特殊处理(扣费)
 * @param botUserId 机器人的 userId
 * @return YES: 需要特殊处理, NO: 正常处理
 *
 * 使用场景:
 * 当机器人发送了完整句子，但内容不为 ~ 或 nil 时，需要做额外操作
 */
- (BOOL)isBotCompleteSentenceNeedsSpecialHandling:(NSString *)botUserId;

/**
 * 判断机器人的完整句子是否需要特殊处理
 * @param botUserId 机器人的 userId
 * @return YES: 需要特殊处理, NO: 正常处理
 *
 * 使用场景:
 * 当机器人发送了完整句子，但内容为 ~ 或 nil 时，需要做额外操作,播放音频
 */
- (BOOL)isBotCompleteSentenceAndPlayAudio:(NSString *)botUserId;

/**
 * 获取完整句子的类型
 * @return 句子类型枚举
 */
- (SubtitleSentenceType)sentenceType;

@end



NS_ASSUME_NONNULL_END
