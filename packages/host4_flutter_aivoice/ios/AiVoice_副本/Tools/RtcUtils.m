//
//  RtcUtils.m
//  GameMacro
//
//  Created by 敬攀 on 2025/12/11.
//

#import "RtcUtils.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation RtcUtils

+ (int)randomInt {
    return arc4random();
}

+ (int)getTimestamp {
    return (int)[[NSDate date] timeIntervalSince1970];
}

+ (NSData *)hmacSignWithKey:(NSString *)keyString message:(NSData *)msg error:(NSError **)error {
    const char *keyBytes = [keyString UTF8String];
    
    unsigned char *hmacResult = malloc(CC_SHA256_DIGEST_LENGTH);
    
    CCHmac(kCCHmacAlgSHA256, keyBytes, strlen(keyBytes), msg.bytes, msg.length, hmacResult);
    
    NSData *result = [NSData dataWithBytes:hmacResult length:CC_SHA256_DIGEST_LENGTH];
    free(hmacResult);
    return result;
}

+ (NSString *)base64Encode:(NSData *)data {
    return [data base64EncodedStringWithOptions:0];
}

+ (NSData *)base64Decode:(NSString *)data {
    return [[NSData alloc] initWithBase64EncodedString:data options:0];
}

+ (NSString *)generateRoomId {
    NSString *uuid = [[NSUUID UUID] UUIDString];
    uuid = [uuid stringByReplacingOccurrencesOfString:@"-" withString:@""];
    uuid = [uuid substringToIndex:MIN(8, uuid.length)];
    return [NSString stringWithFormat:@"room_%@", uuid];
}

+ (NSString *)generateUserId {
    return [NSString stringWithFormat:@"user_%d", arc4random_uniform(10000)];
}

+ (NSString *)generateTaskId {
    return [NSString stringWithFormat:@"task_%d", arc4random_uniform(10000)];
}

+ (NSString *)generateChatbotId {
    return [NSString stringWithFormat:@"chatbot_%d", arc4random_uniform(10000)];
}

+ (NSUserDefaults *)getAppPreferences {
    return [NSUserDefaults standardUserDefaults];
}

@end
