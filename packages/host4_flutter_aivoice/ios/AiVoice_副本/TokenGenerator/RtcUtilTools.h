//
//  RtcUtilTools.h
//  火山引擎 RTC Token Generator
//  工具类
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * RTC 工具类 - 提供加密、编码等功能
 */
@interface RtcUtilTools : NSObject

// 常量
extern const NSUInteger RTCVersionLength;
extern const NSUInteger RTCAppIDLength;

/**
 * 获取当前时间戳（秒）
 */
+ (int32_t)getTimestamp;

/**
 * 生成随机整数
 */
+ (int32_t)randomInt;

/**
 * HMAC-SHA256 签名
 * @param key 密钥
 * @param data 数据
 * @return 签名结果
 */
+ (NSData *)hmacSign:(NSString *)key data:(NSData *)data;

/**
 * Base64 编码
 * @param data 原始数据
 * @return Base64 字符串
 */
+ (NSString *)base64Encode:(NSData *)data;

/**
 * Base64 解码
 * @param string Base64 字符串
 * @return 原始数据
 */
+ (NSData *)base64Decode:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
