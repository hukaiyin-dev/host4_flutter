//
//  ByteBuf.h
//  火山引擎 RTC Token Generator
//  字节缓冲区工具类
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 字节缓冲区 - 用于序列化和反序列化数据
 * Little Endian 字节序
 */
@interface ByteBuf : NSObject

/**
 * 初始化空缓冲区
 */
- (instancetype)init;

/**
 * 从字节数组初始化
 */
- (instancetype)initWithBytes:(NSData *)bytes;

/**
 * 获取缓冲区内容
 */
- (NSData *)asBytes;

// MARK: - 写入方法

/**
 * 写入 Short (16位)
 */
- (ByteBuf *)putShort:(int16_t)value;

/**
 * 写入 Int (32位)
 */
- (ByteBuf *)putInt:(int32_t)value;

/**
 * 写入 Long (64位)
 */
- (ByteBuf *)putLong:(int64_t)value;

/**
 * 写入字节数组
 */
- (ByteBuf *)putBytes:(NSData *)value;

/**
 * 写入字符串
 */
- (ByteBuf *)putString:(NSString *)value;

/**
 * 写入整数字典 (Short -> Integer)
 */
- (ByteBuf *)putIntMap:(NSDictionary<NSNumber *, NSNumber *> *)map;

// MARK: - 读取方法

/**
 * 读取 Short (16位)
 */
- (int16_t)readShort;

/**
 * 读取 Int (32位)
 */
- (int32_t)readInt;

/**
 * 读取字节数组
 */
- (NSData *)readBytes;

/**
 * 读取字符串
 */
- (NSString *)readString;

/**
 * 读取整数字典
 */
- (NSDictionary<NSNumber *, NSNumber *> *)readIntMap;

@end

NS_ASSUME_NONNULL_END
