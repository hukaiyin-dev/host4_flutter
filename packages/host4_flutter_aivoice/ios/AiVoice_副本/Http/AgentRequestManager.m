//
//  AgentRequestManager.m
//  GameMacro
//
//  Created by 敬攀 on 2025/12/11.
//

#import "AgentRequestManager.h"
#import "AFNetworking.h"
#import "NSDictionary+NullHandle.h"
#import "WYProgressHUD.h"
#import "WYImageResetSize.h"
#import "DYRequestModel.h"
#import "UIImage+DYCategory.h"
#import "MyAFHTTPSessionManager.h"

@implementation AgentRequestManager

+(void)agentJoinRoomRequest:(NSString *)boostingTableID roomID:(NSString *)roomID taskID:(NSString *)taskID userID:(NSString *)userID  botname:(NSString *)botname completedBlock:(void (^)(void))successblock failuerBlock:(void (^)(void))failblock{
    
    if (isStringEmpty(boostingTableID) || isStringEmpty(roomID) || isStringEmpty(taskID) || isStringEmpty(userID)){
        if (failblock){
            failblock();
        }
        return;
    }
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc] initWithDictionary:@{@"BoostingTableID":boostingTableID,@"RoomID":roomID,@"TaskID":taskID,@"TargetUserID":userID,@"SystemLanguage":[[HXLanguageManager shareInstance] getAILanguage]}];
    
    if (!isStringEmpty(botname)){
        [param setValue:botname forKey:@"Botname"];
    }
    
    [self PostRequestWithInfo:startVoiceChat andParameters:param completedBlock:^(id data) {
        
        if (successblock){
            successblock();
        }

    } failuerBlock:^(id ErrorModal) {
        if (failblock){
            failblock();
        }
    }];
}

+(void)agentLeaveRoomRequest:(NSString *)roomID taskID:(NSString *)taskID  completedBlock:(void (^)(void))successblock failuerBlock:(void (^)(void))failblock{
    
    if (isStringEmpty(roomID) || isStringEmpty(taskID)){
        if (failblock){
            failblock();
        }
        return;
    }
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc] initWithDictionary:@{@"RoomID":roomID,@"TaskID":taskID}];
    
    [self PostRequestWithInfo:stopVoiceChat andParameters:param completedBlock:^(id data) {
        
        if (successblock){
            successblock();
        }
        
    } failuerBlock:^(id ErrorModal) {
        if (failblock){
            failblock();
        }
    }];
}


+(void)agentUpdateRoomRequest:(NSString *)roomID taskID:(NSString *)taskID command:(NSString *)command  completedBlock:(void (^)(void))successblock failuerBlock:(void (^)(void))failblock{
    
    if (isStringEmpty(roomID) || isStringEmpty(taskID) || isStringEmpty(command)){
        if (failblock){
            failblock();
        }
        return;
    }
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc] initWithDictionary:@{@"RoomID":roomID,@"TaskID":taskID,@"Command":command}];
    
    [self PostRequestWithInfo:updateVoiceChat andParameters:param completedBlock:^(id data) {
        
        if (successblock){
            successblock();
        }
        
    } failuerBlock:^(id ErrorModal) {
        if (failblock){
            failblock();
        }
    }];
}

+(void)PostRequestWithInfo:(NSString *)str andParameters:(NSDictionary *)parameters completedBlock:(void (^)(id))successblock failuerBlock:(void (^)(id))failblock{
    
    if (![UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:@[[MBProgressHUD class]]]){
        [MBProgressHUD showHintTips:@"" detailStr:kLocalizedString(@"Loading", @"") toView:KEY_WINDOW];
    }
    
    AFHTTPSessionManager *manager = [self managerWithTimeOut:20];

    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:parameters];
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:BaseContentType];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@",AgentChatBaseURL,str];
    
    [manager POST:urlStr parameters:mutableDic headers:nil progress:^(NSProgress * _Nonnull uploadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (successblock){
            successblock(responseObject);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (failblock) {
            failblock(error);
        }
    }];
}


+(AFHTTPSessionManager *)managerWithTimeOut:(float)timeOut{
    AFHTTPSessionManager * manager =  [MyAFHTTPSessionManager sharedHTTPSession];
    manager.requestSerializer.timeoutInterval = timeOut;
    return manager;
}

#pragma mark - 会员使用
+(void)requestVipUserUse:(NSInteger)type completedBlock:(void (^)(id))successblock failuerBlock:(void (^)(id))failblock{
    
    NSDictionary *dic = @{@"type":@(type)};
    
    [HttpRequrst GetRequestWithInfo:aiExpiredUserUse andParameters:dic completedBlock:^(id data) {
        
        UserVipModel *vipM = [UserVipModel mj_objectWithKeyValues:data];
        
        if (successblock){
            successblock(vipM);
        }
        
    } failuerBlock:^(id ErrorModal) {
        
        if (failblock) {
            failblock(ErrorModal);
        }
        
    }];
}


#pragma mark - 下单支付
+(void)requestCreatePayOrder:(int)setMealId completedBlock:(void (^)(id _Nonnull))successblock failuerBlock:(void (^)(id _Nonnull))failblock{
    
    NSDictionary *dic = @{@"setMealId":@(setMealId),@"payWayType":@"appleStore"};
    
    [HttpRequrst GetRequestWithInfo:aiOrderPay andParameters:dic completedBlock:^(id data) {
        
        if (successblock){
            successblock(data);
        }
        
    } failuerBlock:^(id ErrorModal) {
        
        if (failblock) {
            failblock(ErrorModal);
        }
        
    }];
}

#pragma mark - 苹果支付回调
+(void)requestAppStoreNotify:(NSString *)signedPayload completedBlock:(void (^)(id _Nonnull))successblock failuerBlock:(void (^)(id _Nonnull))failblock{
    
    NSDictionary *dic = @{@"signedPayload":signedPayload};
    
    [HttpRequrst PostRequestWithInfo:aiAppleStorePayNotify andParameters:dic completedBlock:^(id data) {
        
        BOOL isSuccess = [data boolValue];
        
        if (successblock){
            successblock(@(isSuccess));
        }
        
    } failuerBlock:^(id ErrorModal) {
        
        if (failblock) {
            failblock(ErrorModal);
        }
        
    }];
    
}


#pragma mark - 用户游戏时长记录
+(void)requestUserAddGameTime:(NSInteger)type tag:(NSString *)tag completedBlock:(void (^)(id))successblock failuerBlock:(void (^)(id))failblock{
    
    if (![DYUserManager shareManager].model){
        return;
    }
    
    NSDictionary *dic = @{@"type":@(type),@"tag":tag};
    
    [HttpRequrst PostRequestWithInfo:aiExpiredAddGameTime andParameters:dic completedBlock:^(id data) {
        
        BOOL isSuccess = [data boolValue];
        
        if (successblock){
            successblock(@(isSuccess));
        }
        
    } failuerBlock:^(id ErrorModal) {
        
        if (failblock) {
            failblock(ErrorModal);
        }
        
    }];
    
}

@end
