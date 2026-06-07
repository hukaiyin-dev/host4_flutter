//
//  AccessToken.m
//  火山引擎 RTC Token Generator
//  Token 生成和解析实现
//

#import "AccessToken.h"
#import "ByteBuf.h"
#import "RtcUtilTools.h"

@implementation AccessToken

- (instancetype)initWithAppID:(NSString *)appID
                       appKey:(NSString *)appKey
                       roomID:(NSString *)roomID
                       userID:(NSString *)userID {
    self = [super init];
    if (self) {
        _appID = appID;
        _appKey = appKey;
        _roomID = roomID;
        _userID = userID;
        _issuedAt = [RtcUtilTools getTimestamp];
        _nonce = [RtcUtilTools randomInt];
        _privileges = [NSMutableDictionary dictionary];
        _expireAt = 0;
    }
    return self;
}

+(NSString *)generateToken:(NSString *)roomID userID:(NSString *)userID{
    
    AccessToken *token = [[AccessToken alloc] initWithAppID:AIVoiceAppId appKey:AIVoiceAppKey roomID:roomID userID:userID];
    
    [token setExpireTime:[RtcUtilTools getTimestamp] + 3600];
    [token addPrivilege:RTCPrivilegeSubscribeStream expireTimestamp:0];
    [token addPrivilege:RTCPrivilegePublishStream expireTimestamp:[RtcUtilTools getTimestamp] + 3600];
    
    return [token serialize];
}

+ (NSString *)getVersion {
    return @"001";
}

- (void)addPrivilege:(RTCPrivilege)privilege expireTimestamp:(int32_t)expireTimestamp {
    self.privileges[@(privilege)] = @(expireTimestamp);
    
    // 如果添加发布流权限，自动添加相关子权限
    if (privilege == RTCPrivilegePublishStream) {
        self.privileges[@(RTCPrivilegePublishAudioStream)] = @(expireTimestamp);
        self.privileges[@(RTCPrivilegePublishVideoStream)] = @(expireTimestamp);
        self.privileges[@(RTCPrivilegePublishDataStream)] = @(expireTimestamp);
    }
}

- (void)setExpireTime:(int32_t)expireTimestamp {
    self.expireAt = expireTimestamp;
}

- (NSData *)packMsg {
    ByteBuf *buffer = [[ByteBuf alloc] init];
    
    [buffer putInt:self.nonce];
    [buffer putInt:self.issuedAt];
    [buffer putInt:self.expireAt];
    [buffer putString:self.roomID];
    [buffer putString:self.userID];
    [buffer putIntMap:self.privileges];
    
    return [buffer asBytes];
}

- (NSString *)serialize {
    NSData *msg = [self packMsg];
    
    // 生成签名
    self.signature = [RtcUtilTools hmacSign:self.appKey data:msg];
    
    if (!self.signature) {
        NSLog(@"❌ AccessToken: 签名生成失败");
        return nil;
    }
    
    // 打包消息和签名
    ByteBuf *buffer = [[ByteBuf alloc] init];
    [buffer putBytes:msg];
    [buffer putBytes:self.signature];
    
    NSData *content = [buffer asBytes];
    
    // 生成最终 Token: 版本号 + AppID + Base64(内容)
    NSString *encoded = [RtcUtilTools base64Encode:content];
    
    return [NSString stringWithFormat:@"%@%@%@", 
            [AccessToken getVersion], 
            self.appID, 
            encoded];
}

- (BOOL)verify:(NSString *)key {
    // 检查是否过期
    if (self.expireAt > 0 && [RtcUtilTools getTimestamp] > self.expireAt) {
        return NO;
    }
    
    self.appKey = key;
    
    // 重新生成签名并比较
    NSData *newSignature = [RtcUtilTools hmacSign:self.appKey data:[self packMsg]];
    
    if (!newSignature || !self.signature) {
        return NO;
    }
    
    return [self.signature isEqualToData:newSignature];
}

+ (AccessToken *)parse:(NSString *)tokenString {
    AccessToken *token = [[AccessToken alloc] initWithAppID:@"" 
                                                     appKey:@"" 
                                                     roomID:@"" 
                                                     userID:@""];
    
    if (!tokenString || tokenString.length <= RTCVersionLength + RTCAppIDLength) {
        return token;
    }
    
    // 验证版本号
    NSString *version = [tokenString substringToIndex:RTCVersionLength];
    if (![version isEqualToString:[AccessToken getVersion]]) {
        return token;
    }
    
    // 提取 AppID
    NSRange appIDRange = NSMakeRange(RTCVersionLength, RTCAppIDLength);
    token.appID = [tokenString substringWithRange:appIDRange];
    
    // 提取并解码内容
    NSString *encodedContent = [tokenString substringFromIndex:RTCVersionLength + RTCAppIDLength];
    NSData *content = [RtcUtilTools base64Decode:encodedContent];
    
    if (!content) {
        return token;
    }
    
    // 解析内容
    ByteBuf *buffer = [[ByteBuf alloc] initWithBytes:content];
    
    NSData *msg = [buffer readBytes];
    token.signature = [buffer readBytes];
    
    // 解析消息
    ByteBuf *msgBuf = [[ByteBuf alloc] initWithBytes:msg];
    
    token.nonce = [msgBuf readInt];
    token.issuedAt = [msgBuf readInt];
    token.expireAt = [msgBuf readInt];
    token.roomID = [msgBuf readString];
    token.userID = [msgBuf readString];
    token.privileges = [[msgBuf readIntMap] mutableCopy];
    
    return token;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"AccessToken{\n"
            "  appID='%@',\n"
            "  roomID='%@',\n"
            "  userID='%@',\n"
            "  issuedAt=%d,\n"
            "  expireAt=%d,\n"
            "  nonce=%d,\n"
            "  privileges=%@\n"
            "}",
            self.appID,
            self.roomID,
            self.userID,
            self.issuedAt,
            self.expireAt,
            self.nonce,
            self.privileges];
}

@end
