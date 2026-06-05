//
//  UserVipModel.m
//  GameMacro
//
//  Created by 敬攀 on 2025/12/30.
//

#import "UserVipModel.h"

@implementation UserVipModel

+(UserVipState)returnUserCurrentVipState:(UserVipModel *__nullable)model{
    UserVipState state;
    
    if (!model){
        state = Vip_NoPurchase;
    }else{
        if (model.isSuperVip){
            state = Vip_Supper;
        }else if (model.useEndTimeDay > 3){
            state = Vip_MoreThreeDay;
        }else if (model.useEndTimeDay > 0){
            state = Vip_LessThreeDay;
        }else if (model.useCount > 0){
            state = Vip_RemainingCount;
        }else{
            state = Vip_Expired;
        }
    }
    
    return state;
}

@end
