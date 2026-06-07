//
//  SubtitleMsgData.h
//  GameMacro
//
//  Created by 敬攀 on 2025/12/10.
// 消息体处理
//  解析subv对应的json

#import <Foundation/Foundation.h>
#import "AiVoiceManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface SubtitleMsgData : RTRootModel

@property (nonatomic, copy) NSString *text;

@property (nonatomic, copy) NSString *language;

@property (nonatomic, copy) NSString *userId;

@property (nonatomic, assign) NSInteger sequence;

@property (nonatomic, assign) NSInteger roundId;

/* 首先判断roundid是否一致，
    true: 同一个气泡
    false: 新的气泡
 
 字幕是否为完整的分句，
 abcd d:false
 abcde. d:true ,p:false
 efg d:false, p:false
 abcde.efg
 */

@property (nonatomic, assign) BOOL definite;

@property (nonatomic, assign) BOOL paragraph;

@property (nonatomic, assign) NSInteger msgType;

//拆包校验
+(NSString *)unPackData:(NSData *)message;

//解析
+(NSMutableArray *)parseMsg:(NSString *)msg;

@end

NS_ASSUME_NONNULL_END
