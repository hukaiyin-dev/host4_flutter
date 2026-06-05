//
//  ConversationStatusMessage.m
//  GameMacro
//
//  Created by 敬攀 on 2025/12/19.
//

#import "ConversationStatusMessage.h"

@implementation ConversationStatusMessage

+ (NSString *)unPackData:(NSData *)message{
    NSString *subtitles = convUnpack(message);
    
    return subtitles;
}

+(ConversationStatusMessage *)parseMsg:(NSString *)msg{
    return convParseData(msg);;
}

NSString *convUnpack(NSData *data) {
    const int headerSize = 8;
    
    NSUInteger size = data.length;
    
    if (size < headerSize) {
        return nil;
    }
    const uint8_t *message = data.bytes;
    // Check magic number "conv"
    uint32_t magic = (message[0] << 24) | (message[1] << 16) | (message[2] << 8) | message[3];
    
    if (magic != 0x636F6E76) {
        return nil;
    }
    
    // Get length
    uint32_t length = (message[4] << 24) | (message[5] << 16) | (message[6] << 8) | message[7];
    
    if (size - headerSize != length) {
        return nil;
    }
    
    // Get conversationStatusMessage
    NSString *conversationStatusMessage = nil;
    
    if (length > 0) {
        conversationStatusMessage = [[NSString alloc] initWithBytes:message + headerSize length:length encoding:NSUTF8StringEncoding];
    } else {
        conversationStatusMessage = @"";
    }
    
    return conversationStatusMessage;
}

ConversationStatusMessage *convParseData(NSString *message) {
    
    NSError *error = nil;
    
    NSDictionary *json_data = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    
    if (error || json_data == nil) {
        NSLog(@"JSON parse error: %@", error);
        return nil;
    }
    
    ConversationStatusMessage *statusMsg = [[ConversationStatusMessage alloc] init];
    
    statusMsg.taskId = json_data[@"TaskId"];
    statusMsg.userID = json_data[@"UserID"];
    statusMsg.roundID = [json_data[@"RoundID"] longLongValue];
    statusMsg.eventTime = [json_data[@"EventTime"] longLongValue];
    
    Stage stage;
    
    stage.code = [json_data[@"Stage"][@"Code"] intValue];
    stage.description = json_data[@"Stage"][@"Description"];
    statusMsg.stage = stage;
    
    if (json_data[@"ErrorInfo"] && json_data[@"ErrorInfo"] != [NSNull null]) {
        
        ErrorDetail errorDetail;
        errorDetail.code = [json_data[@"ErrorInfo"][@"ErrorCode"] intValue];
        errorDetail.reason = json_data[@"ErrorInfo"][@"Reason"];
        statusMsg.errorInfo = errorDetail;
        statusMsg.hasErrorInfo = YES;
    } else {
        statusMsg.hasErrorInfo = NO;
    }
    
    return statusMsg;
}
    
@end
