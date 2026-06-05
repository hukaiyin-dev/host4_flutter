//
//  RtcUtils.h
//  GameMacro
//
//  Created by 敬攀 on 2025/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RtcUtils : NSObject

+ (int)randomInt;
+ (int)getTimestamp;
+ (NSData *)hmacSignWithKey:(NSString *)keyString message:(NSData *)msg error:(NSError **)error;
+ (NSData *)base64Decode:(NSString *)data;
///必填，房间 ID
+ (NSString *)generateRoomId;
///必填，目标用户 ID
+ (NSString *)generateUserId;
///必填，任务 ID
+ (NSString *)generateTaskId;
///可选，机器人名称，默认
+ (NSString *)generateChatbotId;
+ (NSUserDefaults *)getAppPreferences;

@end

NS_ASSUME_NONNULL_END
