//
//  UserVipModel.h
//  GameMacro
//
//  Created by 敬攀 on 2025/12/30.
//

#import "RTRootModel.h"

NS_ASSUME_NONNULL_BEGIN

/// 用户vip状态
typedef NS_ENUM(NSInteger, UserVipState) {
    ///超级会员
    Vip_Supper     =  0,
    ///会员剩余-大于3天
    Vip_MoreThreeDay         =  1,
    ///会员剩余-小于3天-大于0天
    Vip_LessThreeDay         =  2,
    ///会员剩余-次数
    Vip_RemainingCount       =  3,
    ///会员-过期
    Vip_Expired              =  4,
    ///会员-没有购买过
    Vip_NoPurchase           =  5,
};

@interface UserVipModel : RTRootModel

///使用次数
@property (nonatomic, assign) int useCount;

///邀请人数
@property (nonatomic, assign) int inviteCount;
///游戏时长
@property (nonatomic, copy) NSString *gameTime;
///使用结束日期
@property (nonatomic, copy) NSString *useEndTime;
///今日获取次数
@property (nonatomic, assign) int useDayCount;
///是否过期
@property (nonatomic, assign) BOOL isExpired;
///剩余过期天数
@property (nonatomic, assign) int useEndTimeDay;
///是否终身会员
@property (nonatomic, assign) BOOL isSuperVip;

//返回当前vip状态
+(UserVipState)returnUserCurrentVipState:(UserVipModel *__nullable)model;

@end

NS_ASSUME_NONNULL_END
