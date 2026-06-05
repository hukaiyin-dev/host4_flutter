//
//  AgentRequestManager.h
//  GameMacro
//
//  Created by 敬攀 on 2025/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AgentRequestManager : NSObject

///智能体进入房间的POST请求
+(void)agentJoinRoomRequest:(NSString *)boostingTableID roomID:(NSString *)roomID taskID:(NSString *)taskID userID:(NSString *)userID botname:(NSString *)botname completedBlock:(void (^)(void))successblock failuerBlock:(void (^)(void))failblock;

///智能体退出房间的POST请求
+(void)agentLeaveRoomRequest:(NSString *)roomID taskID:(NSString *)taskID  completedBlock:(void (^)(void))successblock failuerBlock:(void (^)(void))failblock;

///智能体更新的POST请求
+(void)agentUpdateRoomRequest:(NSString *)roomID taskID:(NSString *)taskID command:(NSString *)command  completedBlock:(void (^)(void))successblock failuerBlock:(void (^)(void))failblock;

///请求会员使用情况
+(void)requestVipUserUse:(NSInteger)type completedBlock:(void (^)(id))successblock failuerBlock:(void (^)(id))failblock;

///下单支付
+(void)requestCreatePayOrder:(int)setMealId completedBlock:(void (^)(id))successblock failuerBlock:(void (^)(id))failblock;

///苹果支付回调
+(void)requestAppStoreNotify:(NSString *)signedPayload completedBlock:(void (^)(id))successblock failuerBlock:(void (^)(id))failblock;

///用户游戏时长记录
+(void)requestUserAddGameTime:(NSInteger)type tag:(NSString *)tag completedBlock:(void (^)(id))successblock failuerBlock:(void (^)(id))failblock;

@end

NS_ASSUME_NONNULL_END
