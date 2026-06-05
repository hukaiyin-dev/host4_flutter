//
//  SubtitleMsgData+Validation.m
//  GameMacro
//
//  判断 subv 消息是否为完整句子的扩展
//

#import "SubtitleMsgData+Validation.h"

@implementation SubtitleMsgData (Validation)

#pragma mark - 机器人消息判断

- (BOOL)isBotMessageWithBotIds:(NSArray<NSString *> *)botUserIds {
    if (!self.userId || botUserIds.count == 0) {
        return NO;
    }
    
    return [botUserIds containsObject:self.userId];
}

- (BOOL)isBotMessage:(NSString *)botUserId {
    if (!self.userId || !botUserId) {
        return NO;
    }
    
    return [self.userId isEqualToString:botUserId];
}

#pragma mark - 完整句子判断

- (BOOL)isCompleteSentence {
    // definite = true 表示完整的分句
    // paragraph = true 表示段落结束（也是完整句子）
//    if ([self.userId isEqualToString:AIVoiceShared.userId]){
//        //用户回复
//        return self.definite;
//    }else{
//        //机器人回复
//        return self.paragraph;
//    }
    return self.definite;
}

- (BOOL)isParagraphEnd {
    return self.paragraph;
}

#pragma mark - 特殊内容判断

- (BOOL)isEmptyOrNil {
    if (!self.text) {
        return YES;
    }
    
    // 去除空白字符后检查
    NSString *trimmed = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmed.length == 0;
}

- (BOOL)isSpecialSymbol {
//    if (!self.text) {
//        return NO;
//    }
    
    return [self.text isEqualToString:@"~"];
    
    NSString *trimmed = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // 判断是否为特殊符号
    NSArray<NSString *> *specialSymbols = @[@"~"];
    
    for (NSString *symbol in specialSymbols) {
        if ([trimmed isEqualToString:symbol]) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)needsSpecialHandling {
    return [self isSpecialSymbol];
}

#pragma mark - 综合判断

- (BOOL)isBotCompleteSentenceNeedsSpecialHandling:(NSString *)botUserId {
    // 1. 必须是机器人消息（不是用扣费）
    if (![self isBotMessage:botUserId]) {
        return NO;
    }
    
    //特殊字符不扣费
    NSString *trimmed = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    //2.判断是否为特殊符号
    NSArray<NSString *> *specialSymbols = @[@"~"];
    
    for (NSString *symbol in specialSymbols) {
        if ([trimmed isEqualToString:symbol]) {
            //是特殊字符，不需要扣费
            AIVoiceShared.isUserAsk = NO;
            
            NSLog(@"当前isUserAsk状态%d",AIVoiceShared.isUserAsk);
            
            return NO;
        }
    }
    
    //3. 不是完整内容，不扣费
    if (!self.paragraph) {
        return NO;
    }
    
//    //空字段不扣费
//    if (isStringEmpty(self.text)){
//        return NO;
//    }
    
    return YES;
}

- (BOOL)isBotCompleteSentenceAndPlayAudio:(NSString *)botUserId{
    // 1. 必须是机器人消息
    if (![self isBotMessage:botUserId]) {
        return NO;
    }
    
    // 2. 必须是完整句子
    if (![self isCompleteSentence]) {
        return NO;
    }
    
    // 3. 内容需要特殊处理（为空或特殊符号）
    return [self needsSpecialHandling];
}

- (SubtitleSentenceType)sentenceType {
    // 不完整句子
    if (![self isCompleteSentence]) {
        return SubtitleSentenceTypeIncomplete;
    }
    
    // 段落结束
    if ([self isParagraphEnd]) {
        return SubtitleSentenceTypeParagraphEnd;
    }
    
    // 内容为空
    if ([self isEmptyOrNil]) {
        return SubtitleSentenceTypeEmpty;
    }
    
    // 只有特殊符号
    if ([self isSpecialSymbol]) {
        return SubtitleSentenceTypeSpecialSymbol;
    }
    
    // 正常完整句子
    return SubtitleSentenceTypeComplete;
}

@end
