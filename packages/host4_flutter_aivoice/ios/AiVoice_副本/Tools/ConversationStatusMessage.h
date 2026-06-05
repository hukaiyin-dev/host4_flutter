//
//  ConversationStatusMessage.h
//  GameMacro
//
//  Created by 敬攀 on 2025/12/19.
////解析conv对应的json
///conv是智能体的状态，跟用户无关

#import <Foundation/Foundation.h>
#import "AiVoiceManager.h"

typedef struct {
    int code;
    NSString *reason;
} ErrorDetail;


typedef struct {
    int code;
    NSString *description;
} Stage;

NS_ASSUME_NONNULL_BEGIN

@interface ConversationStatusMessage : NSObject

//拆包校验
+(NSString *)unPackData:(NSData *)message;

//解析
+(ConversationStatusMessage *)parseMsg:(NSString *)msg;

@property (nonatomic, copy) NSString *taskId;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, assign) int64_t roundID;
@property (nonatomic, assign) int64_t eventTime;
@property (nonatomic, assign) Stage stage;
@property (nonatomic, assign) ErrorDetail errorInfo;
@property (nonatomic, assign) BOOL hasErrorInfo;

@end

NS_ASSUME_NONNULL_END
