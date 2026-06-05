//
//  SubtitleMsgData.m
//  GameMacro
//
//  Created by 敬攀 on 2025/12/10.
//

#import "SubtitleMsgData.h"

@implementation SubtitleMsgData

+ (NSString *)unPackData:(NSData *)message{
    NSString *subtitles = subvUnpack(message);
    
    return subtitles;
}

+(NSMutableArray *)parseMsg:(NSString *)msg{
    return subvParseData(msg);
}

// 大端序转换
uint32_t swapUInt32(uint32_t value) {
    return ((value & 0x000000FF) << 24) |
           ((value & 0x0000FF00) << 8) |
           ((value & 0x00FF0000) >> 8) |
           ((value & 0xFF000000) >> 24);
}

//拆包校验
NSString *subvUnpack(NSData *data) {
    const int kSubtitleHeaderSize = 8;
    
    NSUInteger size = data.length;
    
    if (size < kSubtitleHeaderSize) {
        return nil;
    }
    
    const uint8_t *message = data.bytes;
    // Check magic number "subv"
    uint32_t magic = (message[0] << 24) | (message[1] << 16) | (message[2] << 8) | message[3];
    
    if (magic != 0x73756276) {
        return nil;
    }
    
    // Get length
    uint32_t length = (message[4] << 24) | (message[5] << 16) | (message[6] << 8) | message[7];
    
    if (size - kSubtitleHeaderSize != length) {
        return nil;
    }
    
    // Get subtitles
    NSString *subtitles = nil;
    
    if (length > 0) {
        subtitles = [[NSString alloc] initWithBytes:message + kSubtitleHeaderSize length:length encoding:NSUTF8StringEncoding];
    } else {
        subtitles = @"";
    }
    
    return subtitles;
}

//解析
NSMutableArray *subvParseData(NSString *msg) {
    NSError *error = nil;
    
    NSDictionary *json_data = [NSJSONSerialization JSONObjectWithData:[msg dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    
    if (error) {
        NSLog(@"JSON Parse Error: %@", error);
        return nil;
    }
    
    NSMutableArray<SubtitleMsgData *> *subtitles = [NSMutableArray array];
    
    for (NSDictionary *item in json_data[@"data"]) {
        SubtitleMsgData *subData = [[SubtitleMsgData alloc] init];
        
        subData.definite = [item[@"definite"] boolValue];
        subData.language = item[@"language"];
        subData.paragraph = [item[@"paragraph"] boolValue];
        subData.sequence = [item[@"sequence"] integerValue];
        subData.text = item[@"text"];
        subData.userId = item[@"userId"];
        subData.roundId = [item[@"roundId"] intValue];
        
        if ([subData.userId isEqualToString:AIVoiceShared.userId]){
            subData.msgType = 0;
        }else{
            subData.msgType = 1;
        }
        
        [subtitles addObject:subData];
    }
    
    return subtitles;
}

@end
