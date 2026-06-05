//
//  AccessToken.h
//  火山引擎 RTC Token Generator
//  Token 生成和解析
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * 权限枚举
 */
typedef NS_ENUM(int16_t, RTCPrivilege) {
    RTCPrivilegePublishStream = 0,           // 发布流权限
    RTCPrivilegePublishAudioStream = 1,      // 发布音频流（内部使用）
    RTCPrivilegePublishVideoStream = 2,      // 发布视频流（内部使用）
    RTCPrivilegePublishDataStream = 3,       // 发布数据流（内部使用）
    RTCPrivilegeSubscribeStream = 4,         // 订阅流权限
};

/**
 * AccessToken - RTC Token 生成器
 */
@interface AccessToken : NSObject

// MARK: - 属性

@property (nonatomic, strong) NSString *appID;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) NSString *roomID;
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, assign) int32_t issuedAt;
@property (nonatomic, assign) int32_t expireAt;
@property (nonatomic, assign) int32_t nonce;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *privileges;
@property (nonatomic, strong, nullable) NSData *signature;

// MARK: - 初始化

/**
 * 初始化 AccessToken
 * @param appID 应用 ID（24 位）
 * @param appKey 应用密钥
 * @param roomID 房间 ID
 * @param userID 用户 ID
 */
- (instancetype)initWithAppID:(NSString *)appID appKey:(NSString *)appKey roomID:(NSString *)roomID userID:(NSString *)userID;

// MARK: - 类方法

+(NSString *)generateToken:(NSString *)roomID userID:(NSString *)userID;

/**
 * 获取版本号
 */
+ (NSString *)getVersion;

/**
 * 解析 Token 字符串
 * @param tokenString Token 字符串
 * @return AccessToken 实例
 */
+ (AccessToken *)parse:(NSString *)tokenString;

// MARK: - 实例方法

/**
 * 添加权限
 * @param privilege 权限类型
 * @param expireTimestamp 过期时间戳（秒）
 */
- (void)addPrivilege:(RTCPrivilege)privilege expireTimestamp:(int32_t)expireTimestamp;

/**
 * 设置过期时间
 * @param expireTimestamp 过期时间戳（秒）
 */
- (void)setExpireTime:(int32_t)expireTimestamp;

/**
 * 打包消息
 * @return 打包后的数据
 */
- (NSData *)packMsg;

/**
 * 序列化生成 Token 字符串
 * @return Token 字符串
 */
- (NSString *)serialize;

/**
 * 验证 Token 是否有效
 * @param key 应用密钥
 * @return 是否有效
 */
- (BOOL)verify:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
