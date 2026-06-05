//
//  ByteBuf.m
//  火山引擎 RTC Token Generator
//  字节缓冲区实现
//

#import "ByteBuf.h"

@interface ByteBuf ()

@property (nonatomic, strong) NSMutableData *buffer;
@property (nonatomic, assign) NSUInteger position;
@property (nonatomic, assign) NSUInteger readPosition;

@end

@implementation ByteBuf

- (instancetype)init {
    self = [super init];
    if (self) {
        _buffer = [NSMutableData dataWithCapacity:1024];
        _position = 0;
        _readPosition = 0;
    }
    return self;
}

- (instancetype)initWithBytes:(NSData *)bytes {
    self = [super init];
    if (self) {
        _buffer = [bytes mutableCopy];
        _position = bytes.length;
        _readPosition = 0;
    }
    return self;
}

- (NSData *)asBytes {
    return [NSData dataWithBytes:self.buffer.bytes length:self.position];
}

// MARK: - 写入方法

- (ByteBuf *)putShort:(int16_t)value {
    // Little Endian
    uint8_t bytes[2];
    bytes[0] = (uint8_t)(value & 0xFF);
    bytes[1] = (uint8_t)((value >> 8) & 0xFF);
    
    [self.buffer appendBytes:bytes length:2];
    self.position += 2;
    
    return self;
}

- (ByteBuf *)putInt:(int32_t)value {
    // Little Endian
    uint8_t bytes[4];
    bytes[0] = (uint8_t)(value & 0xFF);
    bytes[1] = (uint8_t)((value >> 8) & 0xFF);
    bytes[2] = (uint8_t)((value >> 16) & 0xFF);
    bytes[3] = (uint8_t)((value >> 24) & 0xFF);
    
    [self.buffer appendBytes:bytes length:4];
    self.position += 4;
    
    return self;
}

- (ByteBuf *)putLong:(int64_t)value {
    // Little Endian
    uint8_t bytes[8];
    bytes[0] = (uint8_t)(value & 0xFF);
    bytes[1] = (uint8_t)((value >> 8) & 0xFF);
    bytes[2] = (uint8_t)((value >> 16) & 0xFF);
    bytes[3] = (uint8_t)((value >> 24) & 0xFF);
    bytes[4] = (uint8_t)((value >> 32) & 0xFF);
    bytes[5] = (uint8_t)((value >> 40) & 0xFF);
    bytes[6] = (uint8_t)((value >> 48) & 0xFF);
    bytes[7] = (uint8_t)((value >> 56) & 0xFF);
    
    [self.buffer appendBytes:bytes length:8];
    self.position += 8;
    
    return self;
}

- (ByteBuf *)putBytes:(NSData *)value {
    // 先写入长度
    [self putShort:(int16_t)value.length];
    
    // 再写入数据
    [self.buffer appendData:value];
    self.position += value.length;
    
    return self;
}

- (ByteBuf *)putString:(NSString *)value {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    return [self putBytes:data];
}

- (ByteBuf *)putIntMap:(NSDictionary<NSNumber *, NSNumber *> *)map {
    // 写入 map 大小
    [self putShort:(int16_t)map.count];
    
    // 按 key 排序（TreeMap 行为）
    NSArray *sortedKeys = [map.allKeys sortedArrayUsingSelector:@selector(compare:)];
    
    // 写入每个键值对
    for (NSNumber *key in sortedKeys) {
        NSNumber *value = map[key];
        [self putShort:[key shortValue]];
        [self putInt:[value intValue]];
    }
    
    return self;
}

// MARK: - 读取方法

- (int16_t)readShort {
    if (self.readPosition + 2 > self.buffer.length) {
        return 0;
    }
    
    const uint8_t *bytes = self.buffer.bytes;
    
    // Little Endian
    int16_t value = (int16_t)(bytes[self.readPosition] |
                             (bytes[self.readPosition + 1] << 8));
    
    self.readPosition += 2;
    
    return value;
}

- (int32_t)readInt {
    if (self.readPosition + 4 > self.buffer.length) {
        return 0;
    }
    
    const uint8_t *bytes = self.buffer.bytes;
    
    // Little Endian
    int32_t value = (int32_t)(bytes[self.readPosition] |
                             (bytes[self.readPosition + 1] << 8) |
                             (bytes[self.readPosition + 2] << 16) |
                             (bytes[self.readPosition + 3] << 24));
    
    self.readPosition += 4;
    
    return value;
}

- (NSData *)readBytes {
    int16_t length = [self readShort];
    
    if (length <= 0 || self.readPosition + length > self.buffer.length) {
        return [NSData data];
    }
    
    NSRange range = NSMakeRange(self.readPosition, length);
    NSData *data = [self.buffer subdataWithRange:range];
    
    self.readPosition += length;
    
    return data;
}

- (NSString *)readString {
    NSData *data = [self readBytes];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSDictionary<NSNumber *, NSNumber *> *)readIntMap {
    int16_t length = [self readShort];
    
    NSMutableDictionary<NSNumber *, NSNumber *> *map = [NSMutableDictionary dictionary];
    
    for (int16_t i = 0; i < length; i++) {
        int16_t key = [self readShort];
        int32_t value = [self readInt];
        
        map[@(key)] = @(value);
    }
    
    return map;
}

@end
